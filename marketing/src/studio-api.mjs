import { createHash } from "node:crypto";
import { canRetryStudioJob, StudioJobs } from "./studio-jobs.mjs";
import { classifyStudioError, redact } from "./studio-errors.mjs";
import { creativeIntelligence } from "./creative-intelligence.mjs";
import { STUDIO_SOURCES, STUDIO_DEPARTMENTS } from "./studio-strategy.mjs";
import { appCaptureCatalog, preflightAppCaptures } from "./app-captures.mjs";
import { requestedCaptures, UPLOAD_LIMIT } from "./capture-storage.mjs";
import { settleOrReleaseOpenAiReservation } from "./orchestrator.mjs";

const unwrap = result => { if (result.error) throw new Error(result.error.message); return result.data; };
const uuid = value => /^[0-9a-f]{8}-[0-9a-f-]{27}$/i.test(value ?? "");
const requireValue = (test, message) => { if (!test) throw Object.assign(new Error(message), { statusCode: 400 }); };
const now = () => new Date().toISOString();

function scheduledPublicationDate(timestamp, timeZone) {
  const date = new Date(timestamp);
  if (!timestamp || !Number.isFinite(date.getTime())) return null;
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone, year: "numeric", month: "2-digit", day: "2-digit",
  }).formatToParts(date);
  const { year, month, day } = Object.fromEntries(parts.map(({ type, value }) => [type, value]));
  return `${year}-${month}-${day}`;
}

export function studioContent(row, detailed = false) {
  const plan = row.decision?.content ?? {}, campaign = row.decision?.campaign ?? {};
  const scenes = row.decision?.generation?.scenes ?? [];
  return {
    id: row.id, key: row.content_key, type: row.content_type, status: row.status,
    title: plan.review_brief?.title ?? plan.title ?? row.topic ?? row.hook ?? "Untitled",
    hook: plan.hook ?? row.hook, concept: plan.review_brief?.description ?? plan.concept ?? row.concept,
    feature: plan.product_feature ?? plan.product_features?.join(", "),
    date: campaign.date ?? row.scheduled_at?.slice(0, 10) ?? row.created_at?.slice(0, 10),
    publicationDate: scheduledPublicationDate(row.scheduled_at, campaign.timezone ?? (campaign.id ? "America/New_York" : "Europe/Belgrade"))
      ?? campaign.date ?? null,
    campaignId: campaign.id, revision: campaign.idea_revision ?? 1, reviewRevision: row.decision?.review_revision ?? 1,
    ideaStatus: campaign.idea_status ?? "pending", blocked: Boolean(campaign.production_blocked),
    error: row.failure_reason ?? campaign.production_block_reason ?? null,
    blockKind: campaign.production_block_kind, progress: row.decision?.workflow,
    assets: row.asset_urls ?? [], thumbnail: row.thumbnail_url, score: row.qa_score,
    createdAt: row.created_at, updatedAt: row.updated_at,
    duration: plan.target_duration_seconds, treatment: plan.creative_treatment,
    sceneProgress: { total: scenes.filter(s => s.asset_type === "generated_video").length,
      complete: scenes.filter(s => s.asset_type === "generated_video" && s.asset_url).length,
      failed: scenes.filter(s => s.status === "failed").length },
    ...(detailed ? { plan, campaign, rationale: row.decision?.rationale, research: row.decision?.research,
      experiment: row.decision?.experiment, candidates: row.decision?.candidate_concepts, qa: row.qa,
      scenes: scenes.map(s => ({ id: s.scene_id, status: s.status, attempt: s.attempt, taskId: s.task_id,
        model: s.model, url: s.asset_url, error: s.failure_reason, history: (s.history ?? []).map(h => ({ attempt: h.attempt, model: h.model, error: h.failure_reason, url: h.asset_url })) })) } : {}),
  };
}

export function registerStudioRoutes(app, { config, cmo, repository, orchestrator, captureStorage, editor }) {
  const client = repository.client;
  const secrets = Object.entries(config).filter(([key]) => /KEY|TOKEN|PASSWORD/.test(key)).map(([, value]) => value);
  let cache = null, cachedAt = 0;
  const invalidate = () => { cachedAt = 0; };
  let jobs;
  const contentEntry = content => ({ campaignId: content.decision.campaign.id, ideaId: content.id,
    contentId: content.id, version: Number(content.decision.campaign.idea_revision), revision: Number(content.decision.review_revision ?? 1),
    plannedDate: content.decision.campaign.date, storedPlannedDate: content.decision.campaign.date,
    fingerprint: `studio:${content.id}:${content.decision.campaign.idea_revision}`, contentUpdatedAt: content.updated_at });

  const execute = async job => {
    if (job.kind === "media_edit") return editor.edit(job);
    if (job.kind === "media_publish") return editor.publish(job);
    const p = job.payload;
    if (job.kind === "plan_campaign") {
      const result = await cmo.execute({ action: "plan_campaign", name: p.name,
        startDate: p.startDate, days: p.days ?? 7, timezone: "America/New_York", requestKey: job.request_key,
        retryFailed: job.attempts > 1, resumeBefore: p.resumeBefore });
      return { campaignId: result.campaign?.id ?? result.id, action: result.action, plannedDays: p.days ?? 7, next: "Review ideas before starting production" };
    }
    if (job.kind === "weekly_review") {
      const result = await orchestrator.runWeekly(new Date(), { retryFailed: job.attempts > 1 });
      return { runId: result.run?.id, reused: result.reused, review: result.run?.output?.review ?? result.review };
    }
    if (job.kind === "sync") { await cmo.sync(p.campaignId); return { synced: true }; }
    if (job.kind === "department_brief") {
      const context = await orchestrator.decisionContext();
      const reservation = await repository.reserveCost("openai", config.OPENAI_ESTIMATED_WEEKLY_COST_USD, { metadata: { operation: "studio-brief", department: p.department } });
      try {
        const result = await orchestrator.brain.studioBrief(context, p);
        await repository.settleCost(reservation, result.costUsd, result.responseId);
        return { ...result.data, costUsd: result.costUsd, department: p.department, delivery: "draft_only" };
      } catch (error) { await settleOrReleaseOpenAiReservation(repository, reservation, error); throw error; }
    }
    let content = await repository.contentById(job.content_id);
    requireValue(content.decision?.campaign?.id, "This item is not registered in a campaign");
    const entry = { ...contentEntry(content), source: "marketing_studio", sourceRef: `studio-job:${job.id}` };
    requireValue(p.revision === (job.kind.startsWith("asset_") ? entry.revision : entry.version), "Stale revision. Refresh the item before acting.");
    if (job.kind.startsWith("asset_")) {
      entry.decision = job.kind.endsWith("approve") ? "Approve" : "Reject";
      entry.instructions = p.instructions ?? "";
      const result = await cmo.assetDecision(entry);
      return { action: result.action, status: (await repository.contentById(content.id)).status,
        blocked: result.blocked, reason: result.reason };
    }
    if (job.kind === "idea_reject") {
      await cmo.ideaDecision({ ...entry, decision: "Reject", instructions: p.instructions }, { acknowledge: false });
      return { revised: true, contentId: content.id };
    }
    if (job.kind === "idea_approve") {
      await cmo.ideaDecision({ ...entry, decision: "Approve", instructions: "" }, { acknowledge: false, deferProduction: true });
      content = await repository.contentById(content.id);
    }
    if (["idea_approve", "resume_content"].includes(job.kind)) {
      try {
        if (content.content_type === "video") {
          await preflightAppCaptures(content.decision.content, orchestrator.appCaptureResolver);
        }
        const latest = await repository.contentById(content.id);
        await repository.updateContent(content.id, { failure_reason: null, decision: { ...latest.decision,
          campaign: { ...latest.decision.campaign, production_blocked: false, production_block_reason: null, production_block_kind: null } } });
        if (job.kind === "idea_approve" || !content.decision.campaign.batch_id) {
          const result = await cmo.execute({ action: "start_item", campaignId: entry.campaignId, contentId: content.id, requestKey: `studio-item:${content.id}:${entry.version}:${job.id}` });
          const current = await repository.contentById(content.id);
          if (["failed", "planned"].includes(current.status)) throw new Error(current.failure_reason ?? result.reason ?? "Production did not reach review");
          return { contentId: content.id, status: current.status, pending: current.status === "generating" };
        }
        // Guarded process resumes saved provider task IDs and preserves completed clips.
        const result = await cmo.campaigns.withWork(content.id, "produce", () => orchestrator.processContentToReview(content.id), { requestKey: `studio-resume:${job.id}` });
        await cmo.sync(entry.campaignId);
        const current = await repository.contentById(content.id);
        if (current.status === "failed") throw new Error(current.failure_reason ?? "Production failed");
        const complete = ["awaiting_approval", "qa_failed", "approved", "scheduled", "published"].includes(current.status);
        return { contentId: content.id, status: current.status, pending: complete ? false : result.pending,
          skipped: complete ? false : result.skipped, reason: complete ? undefined : result.reason };
      } catch (error) {
        const latest = await repository.contentById(content.id);
        const info = classifyStudioError(error, { secrets });
        await repository.updateContent(content.id, { failure_reason: info.message, decision: { ...latest.decision,
          workflow: { stage: "blocked", message: info.message, at: now() },
          campaign: { ...latest.decision.campaign, production_blocked: true,
            production_block_kind: info.category === "missing_asset" ? "capture" : "production", production_block_reason: info.message } } });
        await cmo.sync(entry.campaignId).catch(() => {});
        throw error;
      }
    }
    throw new Error("Unsupported studio action");
  };
  jobs = new StudioJobs({ repository, execute, secrets, onChange: invalidate });

  app.get("/v1/studio/snapshot", async () => {
    if (cache && Date.now() - cachedAt < 15000) return cache;
    const [context, queue, events, campaigns, runs, research, captures] = await Promise.all([
      repository.loadContext(), client.from("marketing_studio_jobs").select("*").order("created_at", { ascending: false }).limit(80),
      client.from("marketing_studio_events").select("*").order("created_at", { ascending: false }).limit(100),
      repository.campaignList(), client.from("marketing_runs").select("id,workflow,status,error,started_at,completed_at,actual_cost_usd,output").order("started_at", { ascending: false }).limit(30),
      client.from("marketing_research").select("id,summary,trends,sources,valid_until,created_at").order("created_at", { ascending: false }).limit(8), appCaptureCatalog(),
    ]);
    const content = context.content.filter(row => !row.master_content_id);
    const costs = context.costs.filter(c => c.status !== "released");
    const totals = costs.reduce((out, c) => { const key = c.status === "reserved" ? "reserved" : "spent";
      out[key] += Number(c.actual_cost_usd ?? c.estimated_cost_usd ?? 0); return out; }, { spent: 0, reserved: 0 });
    const eventCounts = context.events_30d.reduce((out, e) => { const name = e.event_name ?? "unknown"; out[name] = (out[name] ?? 0) + Number(e.event_count ?? 1); return out; }, {});
    cache = redact({ fetchedAt: now(), content: content.slice(0, 240).map(row => studioContent(row)),
      jobs: unwrap(queue).map(({ payload, lock_token, ...job }) => ({ ...job, canRetry: canRetryStudioJob(job) })),
      events: unwrap(events), campaigns, runs: unwrap(runs), research: unwrap(research),
      learnings: context.learnings, publications: context.publications, costs: context.costs.map(({ metadata, ...c }) => c), totals,
      eventCounts, intelligence: creativeIntelligence(content, context.publications, context.events_30d),
      captures: captures.map(({ id, filename, description, duration_seconds, feature }) => ({ id, filename, description, duration_seconds, feature })),
      settings: { brand: "GymFeed", reviewMode: config.MARKETING_REVIEW_MODE, videoModel: config.FAL_VIDEO_MODEL,
        referenceModel: config.FAL_REFERENCE_VIDEO_MODEL, imageModel: config.FAL_IMAGE_MODEL,
        videoUsdPerSecond: config.FAL_VIDEO_USD_PER_SECOND, autoPublish: config.AUTO_PUBLISH,
        scheduler: process.env.STUDIO_SCHEDULER ?? "local_worker",
        connections: { openai: Boolean(config.OPENAI_API_KEY), fal: Boolean(config.FAL_KEY), buffer: Boolean(config.BUFFER_API_KEY),
          googleDrive: Boolean(config.GOOGLE_SHEETS_CREDENTIALS), ga4: Boolean(config.GA4_PROPERTY_ID), email: false, crm: false },
      }, sources: STUDIO_SOURCES, departments: STUDIO_DEPARTMENTS,
    }, secrets);
    cachedAt = Date.now();
    return cache;
  });
  app.get("/v1/studio/content/:id", async request => {
    requireValue(uuid(request.params.id), "Invalid content ID");
    const content = await repository.contentById(request.params.id);
    const detail = studioContent(content, true);
    const refs = requestedCaptures(detail.plan);
    if (refs.length && captureStorage) {
      const local = await appCaptureCatalog();
      detail.captureUploads = Object.fromEntries(await Promise.all(refs.map(async ref => {
        const uploaded = await captureStorage.info(ref);
        const asset = uploaded ?? local.find(entry => entry.id === ref);
        return [ref, asset ? { duration: asset.duration_seconds, source: uploaded ? "storage" : "library" } : null];
      })));
    }
    return redact(detail, secrets);
  });
  app.post("/v1/studio/jobs", async (request, reply) => {
    const body = request.body ?? {}, p = body.payload ?? {};
    requireValue(!["media_edit", "media_publish"].includes(body.kind), "Use the Studio editor to create a media job");
    requireValue(typeof p === "object" && !Array.isArray(p), "Invalid payload");
    requireValue(!body.contentId || uuid(body.contentId), "Invalid content ID");
    if (body.kind === "plan_campaign") {
      requireValue(/^\d{4}-\d{2}-\d{2}$/.test(p.startDate) && Number.isFinite(Date.parse(p.startDate)), "Choose a valid start date");
      requireValue(typeof p.name === "string" && p.name.trim().length >= 3 && p.name.length <= 160, "Campaign name is required");
      requireValue(Number.isInteger(p.days) && p.days >= 1 && p.days <= 14, "Plan between 1 and 14 days");
    }
    if (body.kind === "department_brief") requireValue(STUDIO_DEPARTMENTS[p.department] && typeof p.instructions === "string" && p.instructions.length <= 12000, "Choose a department and a valid brief");
    if (body.kind === "sync") requireValue(uuid(p.campaignId), "A campaign ID is required");
    if (["idea_approve","idea_reject","asset_approve","asset_reject","resume_content"].includes(body.kind)) {
      requireValue(uuid(body.contentId) && Number.isInteger(p.revision) && p.revision >= 1, "Content and explicit revision are required");
      if (body.kind.endsWith("reject")) requireValue(typeof p.instructions === "string" && p.instructions.trim().length >= 5 && p.instructions.length <= 20000, "Describe the requested changes");
    }
    const allowed = Object.fromEntries(Object.entries(p).filter(([key]) => ["name","startDate","days","department","instructions","revision","campaignId"].includes(key)));
    const job = await jobs.enqueue({ kind: body.kind, contentId: body.contentId, payload: allowed, requestKey: request.headers["idempotency-key"] });
    reply.code(202);
    return redact(job, secrets);
  });
  app.post("/v1/studio/jobs/:id/retry", async request => { requireValue(uuid(request.params.id), "Invalid job ID"); return redact(await jobs.retry(request.params.id), secrets); });
  app.post("/v1/studio/jobs/:id/cancel", async request => { requireValue(uuid(request.params.id), "Invalid job ID"); return redact(await jobs.cancel(request.params.id), secrets); });
  app.post("/v1/studio/tick", async () => { void jobs.tick().catch(error => app.log.error(error)); return { accepted: true, busy: jobs.running }; });
  app.post("/v1/studio/incidents", async request => {
    const body = request.body ?? {};
    const error = classifyStudioError(new Error(String(body.message ?? "n8n workflow failed")), { secrets });
    invalidate();
    return jobs.event({ level: "error", stage: "n8n", message: error.message,
      detail: { ...error, workflow: String(body.workflow ?? "unknown").slice(0, 150), node: String(body.node ?? "unknown").slice(0, 150), executionId: String(body.executionId ?? "").slice(0, 100) } });
  });
  app.post("/v1/studio/incidents/:id/resolve", async request => {
    requireValue(uuid(request.params.id), "Invalid incident ID"); invalidate();
    return unwrap(await client.from("marketing_studio_events").update({ resolved_at: now() }).eq("id", request.params.id).select().single());
  });
  app.addContentTypeParser("application/octet-stream", { parseAs: "buffer", bodyLimit: UPLOAD_LIMIT }, (_request, body, done) => done(null, body));
  editor?.register(app, jobs, secrets);
  app.post("/v1/studio/content/:id/upload", { bodyLimit: UPLOAD_LIMIT }, async request => {
    requireValue(uuid(request.params.id), "Invalid content ID");
    requireValue(request.headers["x-owner-verified"] === "true", "Confirm that you reviewed the recording and removed personal data");
    const content = await repository.contentById(request.params.id), plan = content.decision?.content;
    const ref = request.headers["x-capture-ref"];
    const refs = requestedCaptures(plan);
    requireValue(refs.includes(ref), "Recording is not requested by this content");
    const actions = decodeURIComponent(String(request.headers["x-observed-actions"] ?? "")).split("\n").map(action => action.trim()).filter(Boolean);
    requireValue(actions.length && actions.join(" ").length >= 10, "Describe the actions actually visible in your recording");
    requireValue(Buffer.isBuffer(request.body) && request.body.length > 1000, "Upload an MP4 recording");
    const asset = await captureStorage.save(ref, request.body, { feature: plan.product_feature ?? plan.product_features?.[0] ?? "GymFeed", actions });
    invalidate();
    await jobs.event({ contentId: content.id, stage: "upload", message: `Owner-verified recording uploaded: ${asset.filename}`, detail: { sha256: asset.sha256, duration: asset.duration_seconds } });
    const latest = await repository.contentById(content.id);
    const campaign = latest.decision?.campaign;
    let resumeQueued = false;
    if (latest.status === "planned" && campaign?.idea_status === "approved" && campaign.production_block_kind === "capture") {
      const currentRefs = requestedCaptures(latest.decision.content);
      const local = await appCaptureCatalog();
      const ready = await Promise.all(currentRefs.map(async id => local.some(entry => entry.id === id) || Boolean(await captureStorage.info(id))));
      if (currentRefs.includes(ref) && ready.every(Boolean)) {
        const revision = Number(campaign.idea_revision);
        const key = createHash("sha256").update(String(campaign.production_blocked_at ?? latest.updated_at)).digest("hex");
        await jobs.enqueue({ kind: "resume_content", contentId: content.id, payload: { revision }, requestKey: `capture-upload:${content.id}:${revision}:${key}` });
        resumeQueued = true;
      }
    }
    return { uploaded: true, filename: asset.filename, duration: asset.duration_seconds, resumeQueued };
  });
  app.addHook("onError", async (request, _reply, error) => {
    if (!request.url.startsWith("/v1/") || error.statusCode === 401) return;
    await jobs.event({ level: "error", stage: "api", message: error.message,
      detail: { ...classifyStudioError(error, { secrets }), path: request.url.split("?")[0], requestId: request.id } }).catch(() => {});
  });
  const timer = setInterval(() => { void jobs.tick().catch(error => app.log.error(error)); }, 5000);
  timer.unref();
  app.addHook("onClose", async () => clearInterval(timer));
  return jobs;
}
