import { preflightAppCaptures, appCaptureCatalog, resolveAppCapture } from "./app-captures.mjs";
import { extractVideoContactSheet } from "./extract-video-frame.mjs";
import { generationPromptForContent, settleOrReleaseOpenAiReservation } from "./orchestrator.mjs";
import { campaignDate } from "./campaigns.mjs";

function required(value, name) {
  if (typeof value !== "string" || !value.trim()) throw new Error(`${name} is required`);
  return value.trim();
}

export function normalizeReview(entry, phase) {
  if (!entry || typeof entry !== "object") throw new Error("Review entry is required");
  const decision = String(entry.decision ?? "").trim().toLowerCase();
  if (!["approve", "reject"].includes(decision)) throw new Error("Decision must be Approve or Reject");
  const version = phase === "idea" ? entry.version : entry.revision;
  if (!Number.isInteger(version) || version < 1) throw new Error("Review requires an explicit positive revision");
  if (entry.instructions != null && typeof entry.instructions !== "string") throw new Error("Instructions must be text");
  const instructions = (entry.instructions ?? "").trim();
  if (decision === "reject" && instructions.length < 5) throw new Error("Reject requires specific revision instructions");
  const plannedDate = phase === "idea" ? campaignDate(String(entry.plannedDate ?? "").trim()) : entry.plannedDate;
  return { ...entry, decision: decision === "reject" ? "Reject" : "Approve", instructions, plannedDate };
}

export function ideaForSheet(idea, config = {}) {
  const content = idea.content;
  const plan = content.decision.content;
  const productionBlockReason = content.decision?.campaign?.production_block_reason ?? "";
  const approvedBlocked = idea.idea_status === "approved" && Boolean(productionBlockReason)
    && !["failed", "qa_failed", "scheduled", "published"].includes(content.status);
  const workflow = content.decision?.workflow ?? {};
  const displayStatus = workflow.stage === "repairing" ? "Repairing"
    : workflow.stage === "intake" ? "Pending"
    : workflow.stage === "generating" ? "Generating"
    : ["failed", "qa_failed"].includes(content.status) ? "Needs Review"
    : content.status === "generating" ? "Generating"
    : content.status === "awaiting_approval" ? "Ready in Content Review"
    : ["scheduled", "published"].includes(content.status) ? content.status === "scheduled" ? "Scheduled" : "Published"
    : workflow.stage === "intake" ? "Pending"
    : idea.idea_status;
  const scenes = plan.scenes ?? [];
  const generatedSeconds = scenes.filter((s) => s.asset_type === "generated_video").reduce((sum, s) => sum + s.source_duration_seconds, 0);
  const research = content.decision.research ?? {};
  return {
    id: content.id, campaign_id: idea.campaign_id ?? content.decision.campaign?.id,
    version: idea.revision,
    status: approvedBlocked ? "Approved - Blocked" : displayStatus,
    approved_version: idea.approved_revision,
    production_block_reason: approvedBlocked ? productionBlockReason : "",
    production_block_kind: content.decision?.campaign?.production_block_kind,
    progress_message: workflow.message || content.failure_reason || "",
    progress_at: workflow.at,
    planned_date: idea.publication_date, content_type: content.content_type, updated_at: content.updated_at,
    instructions: idea.instructions ?? "",
    brief: {
      title: plan.review_brief?.title ?? plan.platform_copy?.youtube_title ?? plan.topic,
      hook: plan.hook,
      audience: plan.target_audience ?? "See campaign audience assumptions",
      feature: plan.product_feature ?? plan.product_features,
      objective: plan.review_brief?.objective ?? content.decision.selected_strategy?.primary_success_metric,
      description: plan.review_brief?.description ?? plan.concept,
      generation_prompt: generationPromptForContent(content),
      storyboard: scenes.length ? scenes : plan.slides,
      dialogue: scenes.filter((s) => s.spoken_dialogue || s.voiceover_text).map((s) => ({ scene: s.scene_id, speaker: s.speaker_id || "narrator", dialogue: s.spoken_dialogue, narration: s.voiceover_text })),
      caption: plan.platform_copy ?? plan.caption,
      cta: plan.cta,
      evidence: { summary: research.summary, trends: research.trends, gaps: research.gaps, evidence_ids: plan.creative_treatment?.evidence_ids, experiment: content.decision.experiment },
      rationale: plan.review_brief?.rationale ?? content.decision.rationale,
      production_requirements: {
        ...(plan.review_brief ? { brief: plan.review_brief.production_requirements } : {}),
        captures: scenes.filter((s) => s.asset_type === "app_capture").map((s) => s.capture_ref),
        screenshots: plan.screenshot_refs,
        upload_folder_url: config.GOOGLE_DRIVE_ASSET_UPLOAD_URL,
        character: plan.character_reference,
        cast: plan.cast ?? [],
        estimated_video_cost_usd_per_attempt: Number((generatedSeconds * (config.FAL_VIDEO_USD_PER_SECOND ?? 0)).toFixed(2)),
        cost_note: "Video estimate excludes reference images, narration, QA and retries. Provider budget limits still apply.",
        model: config.FAL_REFERENCE_VIDEO_MODEL,
      },
    },
  };
}

export class CmoController {
  constructor({ orchestrator, campaigns, repository, approvalSheet, config }) {
    Object.assign(this, { orchestrator, campaigns, repository, approvalSheet, config });
    this.running = new Map();
  }

  async exclusive(key, task) {
    if (this.running.has(key)) return this.running.get(key);
    const pending = Promise.resolve().then(task);
    this.running.set(key, pending);
    try { return await pending; } finally { this.running.delete(key); }
  }

  async sync(campaignId) {
    const state = await this.campaigns.status(campaignId);
    if (this.approvalSheet?.configured) {
      await this.approvalSheet.syncIdeas(state.ideas.map((idea) => ideaForSheet({ ...idea, campaign_id: campaignId }, this.config)));
      const finals = state.ideas.map((i) => i.content).filter((c) => c.status !== "planned" || ["generating", "repairing"].includes(c.decision?.workflow?.stage));
      if (this.repository.publicationByContent) {
        for (const content of finals) content.publications = await this.repository.publicationByContent(content.id);
      }
      if (finals.length) await this.approvalSheet.syncContent(finals);
    }
    return state;
  }

  async decisions() {
    if (!this.approvalSheet?.configured) return { actions: [], reason: "Google Sheets is not configured" };
    // Read decisions before any refresh. Human columns are never machine-owned.
    const [ideas, assets] = await Promise.all([this.approvalSheet.pendingIdeaDecisions(), this.approvalSheet.pendingDecisions()]);
    const actions = [];
    for (const entry of ideas) {
      actions.push({ action: "idea_decision", entry });
    }
    for (const entry of assets) {
      const content = await this.repository.contentById(entry.contentId);
      if (!content.decision?.campaign?.id) continue; // historical rows cannot spend or publish
      const revision = Number(content.decision.review_revision ?? 1);
      if (entry.revision !== revision) continue;
      if (entry.currentStatus && entry.currentStatus !== content.status || entry.contentUpdatedAt && entry.contentUpdatedAt !== content.updated_at) {
        await this.sync(content.decision.campaign.id);
        continue;
      }
      if (entry.decision === "Approve" && !["awaiting_approval", "qa_failed", "failed", "approved"].includes(content.status)) {
        const score = content.qa_score == null ? "" : ` (${content.qa_score})`;
        const reason = content.failure_reason ?? `Content is ${content.status} and is not ready for final approval`;
        const blocked = `Approved - Blocked: ${content.status === "qa_failed" ? `QA failed${score}` : content.status}: ${reason}`;
        if (entry.processingResult !== blocked) await this.approvalSheet.markContentDecision(entry, blocked);
        continue;
      }
      if (entry.decision === "Reject" && !["awaiting_approval", "qa_failed", "failed"].includes(content.status)) continue;
      actions.push({ action: "asset_decision", entry });
    }
    return { actions };
  }

  async reviseIdea(campaignId, contentId, revision) {
    const claim = await this.campaigns.claimIdeaRevision({ campaignId, contentId, revision });
    if (!claim.claimed) return claim;
    let reservation;
    try {
      const content = await this.repository.contentById(contentId);
      const instructions = claim.instructions ?? content.decision.campaign?.instructions;
      const captureVisuals = [];
      const refs = [...new Set((content.decision?.content?.scenes ?? []).filter((s) => s.asset_type === "app_capture").map((s) => s.capture_ref))];
      for (const ref of refs) {
        try {
          const capture = await (this.orchestrator.appCaptureResolver ?? resolveAppCapture)(ref);
          const frames = 36;
          const sheet = await extractVideoContactSheet(capture.buffer, capture.duration_seconds, frames);
          captureVisuals.push({ ref, duration: capture.duration_seconds, frames, image: `data:image/jpeg;base64,${sheet.toString("base64")}` });
        } catch (error) {
          if (!/Missing verified|ENOENT/.test(error.message)) throw error;
        }
      }
      reservation = await this.repository.reserveCost("openai", this.config.OPENAI_ESTIMATED_DAILY_COST_USD, { contentId, runId: content.run_id, metadata: { operation: "idea-revision", revision } });
      const result = await this.orchestrator.brain.reviseContent(content, instructions, { app_captures: await appCaptureCatalog(), captureVisuals });
      await this.repository.settleCost(reservation, result.costUsd, result.responseId);
      reservation = null;
      return await this.campaigns.finishIdeaRevision({ campaignId, contentId, revision, token: claim.token, plan: result.data });
    } catch (error) {
      await settleOrReleaseOpenAiReservation(this.repository, reservation, error);
      await this.campaigns.failIdeaRevision({ campaignId, contentId, revision, token: claim.token, error: error.message });
      throw error;
    }
  }

  async execute(input = {}) {
    const action = required(input.action, "action");
    const key = input.entry?.contentId ? `asset:${input.entry.contentId}` : `${action}:${input.entry?.ideaId ?? input.campaignId ?? input.requestKey ?? ""}:${input.entry?.version ?? ""}:${input.entry?.fingerprint ?? ""}`;
    return this.exclusive(key, async () => {
      if (action === "plan_campaign") return this.plan(input);
      if (action === "status") return this.campaigns.status(required(input.campaignId, "campaignId"));
      if (action === "sync") return this.sync(required(input.campaignId, "campaignId"));
      if (action === "idea_decision") return this.ideaDecision(input.entry);
      if (action === "asset_decision") {
        try { return await this.assetDecision(input.entry); }
        catch (error) {
          await this.progress(input.entry.contentId, "blocked", `Needs Review: ${error.message}`).catch(() => {});
          await this.approvalSheet.markContentDecision(input.entry, `Needs Review: ${error.message}`).catch(() => {});
          return { action: "asset_decision_blocked", blocked: true, contentId: input.entry.contentId, reason: error.message };
        }
      }
      if (action === "start_item") {
        const campaignId = required(input.campaignId, "campaignId");
        const contentId = required(input.contentId, "contentId");
        const requestKey = required(input.requestKey, "requestKey");
        const started = await this.campaigns.startItem({ campaignId, contentId, requestKey });
        return this.produce(campaignId, started.batch?.id ?? started.id);
      }
      if (action === "start_batch") {
        const campaignId = required(input.campaignId, "campaignId");
        const requestKey = required(input.requestKey, "requestKey");
        const batch = await this.campaigns.startBatch({ campaignId, requestKey });
        if (batch.complete) return batch;
        return this.produce(campaignId, batch.batch?.id ?? batch.id);
      }
      if (action === "resume_batch") return this.produce(required(input.campaignId, "campaignId"), required(input.batchId, "batchId"));
      if (action === "release_batch") return this.release(required(input.campaignId, "campaignId"), required(input.batchId, "batchId"));
      throw new Error(`Unknown CMO action: ${action}`);
    });
  }

  async plan(input) {
    const created = await this.campaigns.create({ name: required(input.name, "name"), startDate: required(input.startDate, "startDate"), days: input.days ?? 28, timezone: input.timezone ?? "America/New_York", requestKey: required(input.requestKey, "requestKey") });
    const campaign = created.campaign ?? created;
    const existing = await this.campaigns.status(campaign.id);
    if (existing.campaign.status !== "planning") return this.sync(campaign.id);
    for (let offset = 0; offset < campaign.days; offset += 1) {
      const date = new Date(`${campaign.start_date}T12:00:00Z`);
      date.setUTCDate(date.getUTCDate() + offset);
      const dateKey = date.toISOString().slice(0, 10);
      if (existing.ideas.some((idea) => idea.publication_date === dateKey)) continue;
      const result = await this.orchestrator.runDaily(date, { campaignId: campaign.id, retryFailed: input.retryFailed === true });
      const ids = result.content?.map((c) => c.id) ?? result.run?.output?.content_ids ?? [];
      if (!ids.length) throw new Error(`Planning ${dateKey} has no completed content IDs. Inspect its running/failed CMO execution before retrying.`);
      await this.campaigns.registerDay({ campaignId: campaign.id, date: dateKey, contentIds: ids });
      await this.sync(campaign.id);
    }
    await this.campaigns.submit(campaign.id);
    return this.sync(campaign.id);
  }

  async ideaDecision(entry, { deferProduction = false, acknowledge = true } = {}) {
    entry = normalizeReview(entry, "idea");
    if (entry.decision === "Approve") {
      await this.campaigns.rescheduleIdea({
        campaignId: entry.campaignId,
        contentId: entry.ideaId,
        revision: entry.version,
        date: entry.plannedDate,
      });
    }
    const result = await this.campaigns.decideIdea({ campaignId: entry.campaignId, contentId: entry.ideaId, revision: entry.version, decision: entry.decision.toLowerCase(), instructions: entry.instructions, requestKey: `idea:${entry.ideaId}:${entry.version}:${entry.fingerprint}` });
    if (entry.decision.toLowerCase() === "reject") {
      const current = await this.campaigns.status(entry.campaignId);
      if (current.ideas.find((idea) => idea.content_id === entry.ideaId)?.revision === entry.version) await this.reviseIdea(entry.campaignId, entry.ideaId, entry.version);
    }
    let production = null;
    if (entry.decision === "Approve" && !deferProduction) {
      const started = await this.campaigns.startItem({
        campaignId: entry.campaignId,
        contentId: entry.ideaId,
        requestKey: `item:${entry.ideaId}:${entry.version}`,
      });
      production = await this.produce(entry.campaignId, started.batch?.id ?? started.id);
    }
    if (entry.decision === "Approve" && deferProduction) production = { deferred: true, next: "automatic_drive_intake" };
    if (acknowledge) await this.approvalSheet.markIdeaDecision(entry, entry.decision === "Reject" ? "Revised idea submitted for approval; no media generated" : deferProduction ? "Idea approved; automatic Drive intake started" : "Idea approved; generation started for this item. Review the finished asset in Content Review.");
    const state = await this.sync(entry.campaignId);
    return { action: "idea_reviewed", result, production, campaign: state.campaign };
  }

  async assetDecision(entry) {
    entry = normalizeReview(entry, "asset");
    let content = await this.repository.contentById(entry.contentId);
    if (Number(content.decision?.review_revision ?? 1) !== entry.revision) throw new Error("Stale asset revision; refresh Content Review");
    if (entry.decision === "Approve" && (entry.qaOverride != null || content.status === "qa_failed" && content.asset_urls?.length)) {
      const score = entry.qaOverride == null ? null : Number(entry.qaOverride);
      if (score != null && (!Number.isFinite(score) || score < 85 || score > 100)) throw new Error("Manual QA score must be between 85 and 100");
      if (!content.asset_urls?.length || !["qa_failed", "awaiting_approval", "approved"].includes(content.status)) throw new Error("Manual QA approval requires a completed asset for this revision");
      if (entry.contentUpdatedAt && entry.contentUpdatedAt !== content.updated_at) throw new Error("Media changed since this QA override; review the current asset");
      content = await this.repository.updateContent(content.id, {
        status: "awaiting_approval", ...(score == null ? {} : { qa_score: score }), failure_reason: null,
        qa: { ...content.qa, human_override: { score, original_score: content.qa?.human_override?.original_score ?? content.qa_score, original_review: content.qa?.human_override?.original_review ?? content.qa, original_reason: content.failure_reason, revision: entry.revision, source: "google_sheets", at: new Date().toISOString() } },
      });
    } else if (entry.decision === "Approve" && ["qa_failed", "failed"].includes(content.status)) {
      return this.repairAndApprove(entry, content);
    }
    const campaignId = required(content.decision?.campaign?.id, "campaign membership");
    const { review, reused } = await this.repository.createContentReview({ contentId: content.id, revision: entry.revision, decision: entry.decision.toLowerCase(), instructions: entry.instructions, sourceRef: `row:${entry.rowNumber}` });
    if (reused && review.status === "processed") {
      const result = { reused: true, result: review.result };
      if (review.decision === "approve") {
        if (content.status === "awaiting_approval") await this.orchestrator.approveContent(content.id);
        result.release = await this.releaseItem(campaignId, content.id);
      }
      return result;
    }
    const currentReviewRevision = Number(content.decision.review_revision ?? 1);
    const resumingReplacement = reused && review.decision === "reject" && currentReviewRevision === Number(entry.revision) + 1;
    if (currentReviewRevision !== Number(entry.revision) && !resumingReplacement) throw new Error("Stale asset revision");
    let result;
    try {
      if (entry.decision === "Reject") {
        if (!resumingReplacement) {
          const ideaRevision = Number(content.decision.campaign.idea_revision);
          await this.campaigns.decideIdea({
            campaignId, contentId: content.id, revision: ideaRevision, decision: "reject",
            instructions: entry.instructions, requestKey: `asset-reject:${review.id}`,
          });
          await this.reviseIdea(campaignId, content.id, ideaRevision);
        }

        let state = await this.campaigns.status(campaignId);
        let idea = state.ideas.find((candidate) => candidate.content_id === content.id);
        if (!idea) throw new Error("Campaign idea disappeared during asset revision");
        if (idea.idea_status === "pending") {
          await this.campaigns.decideIdea({
            campaignId, contentId: content.id, revision: idea.revision, decision: "approve",
            instructions: entry.instructions, requestKey: `asset-revision-approve:${review.id}:${idea.revision}`,
            reviewer: "finished_asset_reviewer",
          });
          state = await this.campaigns.status(campaignId);
          idea = state.ideas.find((candidate) => candidate.content_id === content.id);
        }
        if (idea?.idea_status !== "approved") throw new Error(`Revised asset plan is ${idea?.idea_status ?? "missing"}`);

        await this.approvalSheet.markContentDecision(entry, `Rejected revision ${entry.revision}; replacement is being generated`);
        const started = await this.campaigns.startItem({
          campaignId, contentId: content.id, requestKey: `item:${content.id}:${idea.revision}`,
        });
        const production = await this.produce(campaignId, started.batch?.id ?? started.id);
        result = {
          action: "asset_replaced_pending_review",
          contentId: content.id,
          revision: Number(idea.content?.decision?.review_revision ?? entry.revision + 1),
          production,
        };
      } else {
        await this.campaigns.assertGenerationAllowed(content.id);
        const approval = await this.orchestrator.approveContent(content.id);
        if (approval.skipped && approval.content.status !== "approved") throw new Error(`Cannot approve asset in ${approval.content.status}`);
        result = { action: "asset_approved", contentId: content.id };
        result.release = await this.releaseItem(campaignId, content.id);
        await this.approvalSheet.markContentDecision(entry, "Scheduled in Buffer; post IDs are shown in Buffer posts.");
      }
      await this.repository.finishContentReview(review.id, "processed", { result });
      await this.sync(campaignId);
      return result;
    } catch (error) {
      await this.repository.finishContentReview(review.id, "failed", { error: error.message }).catch(() => {});
      await this.progress(content.id, "blocked", `Needs Review: ${error.message}`).catch(() => {});
      const blockedMessage = entry.decision === "Reject"
        ? `Rejected - Blocked: replacement generation failed: ${error.message}`
        : `ERROR: ${error.message}`;
      await this.approvalSheet.markContentDecision(entry, blockedMessage).catch(() => {});
      await this.sync(campaignId).catch(() => {});
      if (entry.decision === "Reject") {
        return { action: "asset_replacement_blocked", blocked: true, contentId: content.id, reason: error.message };
      }
      return { action: "asset_approval_blocked", blocked: true, contentId: content.id, reason: error.message };
    }
  }

  async progress(contentId, stage, message, extra = {}) {
    const content = await this.repository.contentById(contentId);
    await this.repository.updateContent(contentId, { decision: { ...content.decision, workflow: { ...content.decision?.workflow, ...extra, stage, message, at: new Date().toISOString() } } });
    if (content.decision?.campaign?.id) await this.sync(content.decision.campaign.id);
  }

  async repairAndApprove(entry, content) {
    for (let attempt = 1; attempt <= 2; attempt++) {
      const instructions = [...new Set([
        "Automatically repair the failed quality checks. Preserve the approved concept, people and dialogue; use the existing verified captures. Request a new recording only when the required real interaction is absent.",
        "When a generated human action repeatedly fails, simplify the shot's blocking while preserving its narrative purpose. Avoid arbitrary hand-side, exact phone-height and multiple-movement requirements. Prefer one clear reaction or simple physical action that can be observed reliably.",
        content.failure_reason, ...(content.qa?.required_fixes ?? []),
        ...(content.decision?.generation?.scenes ?? []).flatMap((s) => s.qa?.required_fixes ?? []),
      ].filter(Boolean))].join("\n");
      await this.progress(content.id, "repairing", `Automatic QA repair ${attempt}/2 is running.`, { repair_attempt: attempt });
      const result = await this.assetDecision({ ...entry, decision: "Reject", qaOverride: undefined, instructions, revision: Number(content.decision?.review_revision ?? 1), automaticRepair: true });
      content = await this.repository.contentById(content.id);
      if (content.status === "awaiting_approval") return this.assetDecision({ ...entry, revision: Number(content.decision?.review_revision ?? 1), contentUpdatedAt: content.updated_at, instructions: entry.instructions ?? "" });
      if (result.blocked && !(content.status === "failed" && /Scene QA failed after maximum attempts/i.test(content.failure_reason ?? ""))) break;
    }
    const sceneReasons = (content.decision?.generation?.scenes ?? []).filter((s) => s.qa?.accept === false)
      .map((s) => `${s.scene_id}: ${s.qa?.defects?.[0] || s.qa?.required_fixes?.[0] || s.qa?.summary || "Scene QA failed"}`);
    const reason = [content.failure_reason, ...sceneReasons.slice(0, 2)].filter(Boolean).join("\n").slice(0, 700)
      || "Automatic QA repair did not pass. Review the latest asset or enter a manual QA score of 85-100.";
    await this.progress(content.id, "blocked", `Needs Review: ${reason}`);
    await this.approvalSheet.markContentDecision({ ...entry, revision: Number(content.decision?.review_revision ?? 1), instructions: "" }, `Needs Review: ${reason}`);
    return { action: "automatic_repair_needs_review", blocked: true, reason };
  }

  async releaseItem(campaignId, contentId) {
    await this.progress(contentId, "publishing", "Sending the approved asset to Buffer.");
    try {
      await this.campaigns.assertPublicationAllowed(contentId);
      const result = await this.campaigns.withWork(contentId, "publish", () => this.orchestrator.publishContent(contentId, { explicitBatchRelease: true }));
      const publications = this.repository.publicationByContent ? await this.repository.publicationByContent(contentId) : result.publications ?? [];
      if (result.skipped || !publications.length || publications.some((p) => !p.provider_request_id || p.error)) {
        throw new Error(result.reason || publications.filter((p) => p.error).map((p) => `${p.platform}: ${p.error}`).join("; ") || "Buffer has not confirmed scheduling");
      }
      await this.progress(contentId, "scheduled", `Buffer confirmed ${publications.length} post(s).`);
      return { action: "item_scheduled", publications };
    } catch (error) {
      await this.progress(contentId, "blocked", `Approved - Blocked: ${error.message}`);
      throw error;
    }
  }

  async releaseIfReady(campaignId, batchId) {
    const state = await this.campaigns.status(campaignId);
    const batch = state.batches.find((b) => b.id === batchId);
    if (!batch || !batch.manifest.every((m) => ["approved", "scheduled", "published"].includes(state.ideas.find((i) => i.content_id === m.content_id)?.content.status))) return { pending: true };
    return this.release(campaignId, batch.id);
  }

  async produce(campaignId, batchId) {
    const state = await this.campaigns.status(campaignId);
    const batch = state.batches.find((b) => b.id === batchId);
    if (!batch) throw new Error("Unknown batch for this campaign");
    const contents = batch.manifest.map((m) => state.ideas.find((i) => i.content_id === m.content_id)?.content);
    if (contents.some((c) => !c)) throw new Error("Batch contains a missing content item");
    // Check the whole batch before the first paid media call, not halfway through it.
    for (const content of contents) {
      await this.campaigns.assertGenerationAllowed(content.id);
      if (content.content_type === "video") await preflightAppCaptures(content.decision.content, this.orchestrator.appCaptureResolver);
    }
    const results = [];
    for (const content of contents) {
      if (["awaiting_approval", "approved", "scheduled", "published"].includes(content.status)) continue;
      await this.progress(content.id, "generating", "Generating media and running QA. No publication has been requested yet.");
      const result = await this.produceWithStoryRepair(campaignId, content.id);
      if (result.skipped && !result.content) return { action: "batch_in_progress_or_needs_reconciliation", batchId, contentId: content.id, reason: result.reason };
      results.push({ id: content.id, status: result.content?.status, pending: result.pending });
      const current = await this.repository.contentById(content.id);
      await this.repository.updateContent(content.id, { decision: { ...current.decision, campaign: {
        ...current.decision.campaign, production_blocked: false, production_block_reason: null, production_block_kind: null,
      } } });
      await this.progress(content.id, result.content?.status === "awaiting_approval" ? "review" : "blocked",
        result.content?.status === "awaiting_approval" ? "QA passed. Review this asset in Content Review." : result.content?.failure_reason || "Production did not finish. Review the failure before retrying.");
      if (result.content?.status === "qa_failed") {
        return {
          action: "item_qa_failed_pending_content_review",
          batchId,
          contentId: content.id,
          reason: result.content.failure_reason,
          results,
          state: await this.campaigns.status(campaignId),
        };
      }
      if (result.content?.status !== "awaiting_approval") throw new Error(`Batch stopped at ${content.content_key}: ${result.content?.failure_reason ?? result.content?.status}. Resolve this item then resume this batch; no later batch was started.`);
    }
    return { action: "batch_ready_for_asset_review", batchId, results, state: await this.sync(campaignId) };
  }

  async produceWithStoryRepair(campaignId, contentId) {
    for (;;) {
      const content = await this.repository.contentById(contentId);
      const storyFailure = content.status === "failed"
        && String(content.failure_reason ?? "").startsWith("Creative story QA failed before media generation:");
      if (storyFailure) {
        // A known pre-media rejection is repairable; an ambiguous provider failure is not.
        if (content.asset_urls?.length || content.provider_task_id || content.decision?.generation?.scenes?.some((s) => s.task_id)) throw new Error("Story repair cannot restart existing media tasks; reconcile them first.");
        const attempt = Number(content.decision?.workflow?.story_repair_attempt ?? 0) + 1;
        if (attempt > 2 || content.decision?.story_review?.review_status === "budget_blocked") {
          const fingerprint = content.decision?.story_review?.fingerprint;
          if (!fingerprint) throw new Error("Creative story review has no saved fingerprint for a review-only preview");
          await this.progress(contentId, "generating", "Creative QA findings retained. Generating a video for human review.", { story_preview_authorized_fingerprint: fingerprint });
        } else {
          const revision = Number(content.decision.campaign.idea_revision);
          const instructions = [
            "Automatically correct the pre-production script findings. Keep the approved concept, hook, cast and product feature; do not replace this with a different campaign or remove the human dialogue.",
            "Keep phone and routine ownership coherent. Do not imply sharing or cross-device synchronization. Use the supplied real source frames to select a truthful cut and describe only what it shows. A demo account must be anonymized, not renamed to a fictional actor.",
            content.failure_reason, ...(content.decision.story_review?.required_fixes ?? []),
          ].join("\n");
          await this.progress(contentId, "repairing", `Automatic script repair ${attempt}/2. No video has been generated yet.`, { story_repair_attempt: attempt });
          await this.campaigns.decideIdea({ campaignId, contentId, revision, decision: "reject", instructions, requestKey: `story-repair:${contentId}:${revision}`, reviewer: "automatic_story_repair" });
          await this.reviseIdea(campaignId, contentId, revision);
          const revised = await this.repository.contentById(contentId);
          const nextRevision = Number(revised.decision.campaign.idea_revision);
          if (nextRevision !== revision + 1 || revised.status !== "planned") throw new Error("Script revision did not finish; production remains stopped.");
          await this.campaigns.decideIdea({ campaignId, contentId, revision: nextRevision, decision: "approve", instructions, requestKey: `story-repair-approve:${contentId}:${nextRevision}`, reviewer: "automatic_story_repair" });
          await this.campaigns.startItem({ campaignId, contentId, requestKey: `item:${contentId}:${nextRevision}` });
          await this.progress(contentId, "generating", "Script revised. Rechecking creative QA before media generation.");
        }
      }
      try {
        return await this.campaigns.withWork(contentId, "produce", () => this.orchestrator.processContentToReview(contentId, { maxWaitMs: 30 * 60_000 }));
      } catch (error) {
        if (error.storyQaFailed !== true || error.safeToRetry !== true) throw error;
      }
    }
  }

  async release(campaignId, batchId) {
    const state = await this.campaigns.status(campaignId);
    const batch = state.batches.find((b) => b.id === batchId);
    if (!batch) throw new Error("Unknown batch");
    for (const item of batch.manifest) await this.campaigns.assertPublicationAllowed(item.content_id);
    const results = [];
    // Validate every date before submitting any platform post.
    for (const item of batch.manifest) {
      const content = state.ideas.find((i) => i.content_id === item.content_id).content;
      if (!["scheduled", "published"].includes(content.status)) this.orchestrator.scheduledTime(content, "instagram");
    }
    for (const item of batch.manifest) results.push(await this.campaigns.withWork(item.content_id, "publish", () => this.orchestrator.publishContent(item.content_id, { explicitBatchRelease: true })));
    return { action: "batch_release_attempted", results, state: await this.sync(campaignId) };
  }
}
