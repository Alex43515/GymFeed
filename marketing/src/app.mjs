import Fastify from "fastify";
import { preflightAppCaptures } from "./app-captures.mjs";

function tokenFrom(request, name) {
  const value = request.headers[name];
  return Array.isArray(value) ? value[0] : value;
}

export function buildApp({ config, orchestrator, cmo, captureIngestor, logger = true }) {
  const app = Fastify({ logger });
  const legacyReview = (fn) => {
    if (cmo) throw new Error("Use the idea/asset decision actions in the main CMO; the old review path is disabled");
    return fn();
  };
  const guardedWork = async (id, operation, fn) => {
    if (!cmo) return fn();
    return cmo.campaigns.withWork(id, operation, fn);
  };

  app.addHook("onRequest", async (request, reply) => {
    if (!request.url.startsWith("/v1/")) return;
    const isApproval = /^\/v1\/content\/[^/]+\/approve(?:\?|$)/.test(request.url);
    const expected = isApproval ? config.MARKETING_APPROVAL_TOKEN : config.MARKETING_INTERNAL_TOKEN;
    const header = isApproval ? "x-marketing-approval-token" : "x-marketing-token";
    if (tokenFrom(request, header) !== expected) return reply.code(401).send({ error: "unauthorized" });
  });

  app.get("/health", async () => ({ ok: true, service: "gymfeed-marketing-worker" }));
  if (cmo) {
    app.post("/v1/cmo/execute", async (request) => cmo.execute(request.body ?? {}));
    app.post("/v1/cmo/decisions", async () => cmo.decisions());
    app.get("/v1/cmo/campaigns", async () => cmo.repository.campaignList());
    app.get("/v1/cmo/campaigns/:id", async (request) => cmo.campaigns.status(request.params.id));
    const approveImportAndStart = async (entry) => {
      if (!captureIngestor) throw new Error("Capture intake is not configured");
      const approval = await cmo.ideaDecision(entry, { deferProduction: true, acknowledge: false });
      const content = await cmo.repository.contentById(entry.ideaId);
      if (cmo.progress) {
        await cmo.repository.updateContent(content.id, { decision: { ...content.decision, campaign: { ...content.decision?.campaign, production_blocked: false, production_block_reason: null }, workflow: { stage: "intake", message: "Pending: checking Drive for the requested files.", at: new Date().toISOString() } } });
        await cmo.sync(entry.campaignId);
      }
      let assets;
      try {
        assets = await captureIngestor.importApprovedPlan({
          driveFolderUrl: config.GOOGLE_DRIVE_ASSET_UPLOAD_URL,
          plan: content.decision?.content,
        });
        if (content.content_type === "video") await preflightAppCaptures(content.decision.content, cmo.orchestrator?.appCaptureResolver);
      } catch (error) {
        const decision = {
          ...content.decision,
          campaign: {
            ...content.decision?.campaign,
            production_blocked: true,
            production_block_kind: "capture",
            production_block_reason: error.message,
            production_blocked_at: new Date().toISOString(),
          },
        };
        await cmo.repository.updateContent(content.id, { status: "planned", decision, failure_reason: error.message });
        await cmo.approvalSheet.markIdeaDecision(entry, `Approved - Blocked: ${error.message}`);
        const state = await cmo.sync(entry.campaignId);
        return { action: "idea_approved_blocked", blocked: true, reason: error.message, approval, campaign: state.campaign };
      }

      const refreshed = await cmo.repository.contentById(content.id);
      await cmo.repository.updateContent(content.id, {
        decision: {
          ...refreshed.decision,
          campaign: {
            ...refreshed.decision?.campaign,
            production_blocked: false,
            production_block_kind: null,
            production_block_reason: null,
            production_blocked_at: null,
          },
        },
        failure_reason: null,
      });
      const fingerprint = [...assets.captures, ...assets.images].map((asset) => asset.sha256).filter(Boolean).join(":") || `approved:${entry.version}`;
      await cmo.progress?.(content.id, "generating", "Files downloaded and verified. Generation is starting.");
      let production;
      try {
        production = await cmo.execute({
          action: "start_item",
          campaignId: entry.campaignId,
          contentId: entry.ideaId,
          requestKey: `item:${entry.ideaId}:${entry.version}:${fingerprint}`,
        });
        if (production.action === "batch_in_progress_or_needs_reconciliation") {
          throw new Error(production.reason ?? "Production needs operator reconciliation before it can resume");
        }
      } catch (error) {
        const failed = await cmo.repository.contentById(content.id);
        await cmo.repository.updateContent(content.id, {
          decision: {
            ...failed.decision,
            workflow: { stage: "blocked", message: error.message, at: new Date().toISOString() },
            campaign: {
              ...failed.decision?.campaign,
              production_blocked: true,
              production_block_kind: "production",
              production_block_reason: error.message,
              production_blocked_at: new Date().toISOString(),
            },
          },
          failure_reason: error.message,
        });
        await cmo.approvalSheet.markIdeaDecision(entry, `Approved - Blocked: ${error.message}`);
        const state = await cmo.sync(entry.campaignId);
        return { action: "idea_approved_blocked", blocked: true, reason: error.message, assets, approval, campaign: state.campaign };
      }
      const qaFailed = production.action === "item_qa_failed_pending_content_review";
      await cmo.approvalSheet.markIdeaDecision(entry, qaFailed
        ? `Idea approved; generated asset needs Content Review revision: ${production.reason}`
        : "Idea approved; Drive assets verified and generation completed through QA. Review the asset in Content Review.");
      const state = await cmo.sync(entry.campaignId);
      return {
        action: qaFailed ? "idea_approved_qa_failed" : "idea_approved_generated",
        blocked: false,
        qa_failed: qaFailed,
        assets,
        approval,
        production,
        campaign: state.campaign,
      };
    };
    app.post("/v1/cmo/approve-import-and-start", async (request, reply) => {
      const supplied = request.body?.entry ?? (request.body?.ideaId ? request.body : null);
      if (supplied && (!supplied.ideaId || !supplied.campaignId)) return reply.code(400).send({ error: "Supply an Idea Review entry with ideaId and campaignId, or run with an empty body to check approved rows." });
      const entries = supplied ? [supplied] : (await cmo.approvalSheet.pendingIdeaDecisions()).filter((e) => e.decision === "Approve");
      if (!entries.length) return { action: "no_approved_items", message: "No pending idea approvals or blocked uploads to retry." };
      const results = [];
      for (const entry of entries) {
        try {
          const run = () => approveImportAndStart(entry);
          results.push(cmo.exclusive ? await cmo.exclusive(`intake:${entry.ideaId}`, run) : await run());
        } catch (error) {
          await cmo.approvalSheet.markIdeaDecision(entry, `Approved - Blocked: ${error.message}`).catch(() => {});
          results.push({ action: "idea_approved_blocked", contentId: entry.ideaId, blocked: true, reason: error.message });
        }
      }
      return supplied ? results[0] : { action: "approved_items_checked", results };
    });
    app.post("/v1/cmo/import-capture-and-start", async (request) => {
      if (!captureIngestor) throw new Error("Capture intake is not configured");
      const body = request.body ?? {};
      const content = await cmo.repository.contentById(body.contentId);
      if (content.decision?.campaign?.id !== body.campaignId) throw new Error("Content does not belong to the supplied campaign");
      await cmo.campaigns.assertGenerationAllowed(body.contentId);
      const plan = content.decision?.content ?? {};
      const expectedScreenshots = new Set([
        ...(plan.screenshot_refs ?? []),
        ...(plan.scenes ?? []).map((scene) => scene.screenshot_ref).filter(Boolean),
        ...(plan.slides ?? []).map((slide) => slide.screenshot_ref).filter(Boolean),
      ]);
      for (const image of body.images ?? []) {
        if (!expectedScreenshots.has(image.screenshotRef)) throw new Error(`Screenshot is not required by the approved content plan: ${image.screenshotRef}`);
      }
      const expectedCapture = body.captureRef
        ? (plan.scenes ?? []).find((scene) => scene.capture_ref === body.captureRef)
        : null;
      if (body.captureRef && !expectedCapture) throw new Error("Capture reference is not required by the approved content plan");
      const images = await captureIngestor.importScreenshots(body.images ?? []);
      const capture = body.captureRef ? await captureIngestor.import(body) : null;
      if (content.content_type === "video") await preflightAppCaptures(plan);
      const assetFingerprint = [capture?.sha256, ...images.map((image) => image.sha256)].filter(Boolean).join(":") || "existing-assets";
      const production = await cmo.execute({
        action: "start_item",
        campaignId: body.campaignId,
        contentId: body.contentId,
        requestKey: body.requestKey ?? `drive-assets:${body.contentId}:${assetFingerprint}`,
      });
      return { capture, images, production };
    });
  }
  app.post("/v1/runs/daily", async (request) => {
    const campaignDate = request.body?.campaign_date ? new Date(request.body.campaign_date) : new Date();
    if (Number.isNaN(campaignDate.getTime())) throw new Error("campaign_date must be an ISO date or date-time");
    const revision = request.body?.revision == null ? 1 : Number(request.body.revision);
    return orchestrator.runDaily(campaignDate, { revision });
  });
  app.post("/v1/runs/daily-batch", async (request) => {
    const startDate = request.body?.start_date ? new Date(request.body.start_date) : new Date();
    if (Number.isNaN(startDate.getTime())) throw new Error("start_date must be an ISO date or date-time");
    const days = request.body?.days == null ? 3 : Number(request.body.days);
    const revision = request.body?.revision == null ? 1 : Number(request.body.revision);
    return orchestrator.runDailyBatch(startDate, { days, revision });
  });
  app.post("/v1/runs/weekly", async () => orchestrator.runWeekly());
  app.post("/v1/runs/pipeline", async () => orchestrator.runPipeline());
  app.post("/v1/publications/refresh", async () => {
    const publications = await orchestrator.refreshPublications();
    if (cmo && Array.isArray(publications)) {
      const campaigns = new Set();
      for (const id of new Set(publications.map((p) => p.content_id))) {
        const content = await cmo.repository.contentById(id);
        if (content.decision?.campaign?.id) campaigns.add(content.decision.campaign.id);
      }
      for (const id of campaigns) await cmo.sync(id);
    }
    return publications;
  });
  app.post("/v1/reviews/sync", async () => legacyReview(() => orchestrator.syncApprovalSheet()));
  app.post("/v1/reviews/sync-content", async () => orchestrator.syncApprovalContent());
  app.post("/v1/reviews/claim", async () => legacyReview(() => orchestrator.claimApprovalSheetDecisions()));
  app.post("/v1/reviews/prepare", async (request) => {
    if (cmo) throw new Error("Use the main CMO decision dispatcher; legacy review preparation is disabled");
    return orchestrator.prepareClaimedReview(request.body ?? {});
  });
  app.post("/v1/reviews/complete", async (request) => orchestrator.completeClaimedReview(request.body ?? {}));
  app.post("/v1/content/:id/generate", async (request) => guardedWork(request.params.id, "generate", () => orchestrator.generateContent(request.params.id)));
  app.post("/v1/content/:id/refresh", async (request) => guardedWork(request.params.id, "refresh", () => orchestrator.refreshContent(request.params.id)));
  app.post("/v1/content/:id/qa", async (request) => guardedWork(request.params.id, "qa", () => orchestrator.reviewContent(request.params.id)));
  app.post("/v1/content/:id/process", async (request) => guardedWork(request.params.id, "produce", () => orchestrator.processContentToReview(request.params.id)));
  app.post("/v1/content/:id/approve", async (request) => legacyReview(() => orchestrator.approveContent(request.params.id)));
  app.post("/v1/content/:id/publish", async (request) => guardedWork(request.params.id, "publish", () => orchestrator.publishContent(request.params.id)));

  app.setErrorHandler((error, request, reply) => {
    request.log.error(error);
    reply.code(error.statusCode && error.statusCode < 500 ? error.statusCode : 500).send({ error: error.message });
  });
  return app;
}
