import { preflightAppCaptures, appCaptureCatalog } from "./app-captures.mjs";

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
  return { ...entry, decision: decision === "reject" ? "Reject" : "Approve", instructions };
}

export function ideaForSheet(idea, config = {}) {
  const content = idea.content;
  const plan = content.decision.content;
  const scenes = plan.scenes ?? [];
  const generatedSeconds = scenes.filter((s) => s.asset_type === "generated_video").reduce((sum, s) => sum + s.source_duration_seconds, 0);
  const research = content.decision.research ?? {};
  return {
    id: content.id, campaign_id: idea.campaign_id ?? content.decision.campaign?.id,
    version: idea.revision, status: idea.idea_status, approved_version: idea.approved_revision,
    planned_date: idea.publication_date, content_type: content.content_type, updated_at: content.updated_at,
    brief: {
      title: plan.review_brief?.title ?? plan.platform_copy?.youtube_title ?? plan.topic,
      hook: plan.hook,
      audience: plan.target_audience ?? "See campaign audience assumptions",
      feature: plan.product_feature ?? plan.product_features,
      objective: plan.review_brief?.objective ?? content.decision.selected_strategy?.primary_success_metric,
      description: plan.review_brief?.description ?? plan.concept,
      storyboard: scenes.length ? scenes : plan.slides,
      dialogue: scenes.filter((s) => s.spoken_dialogue || s.voiceover_text).map((s) => ({ scene: s.scene_id, dialogue: s.spoken_dialogue, narration: s.voiceover_text })),
      caption: plan.platform_copy ?? plan.caption,
      cta: plan.cta,
      evidence: { summary: research.summary, trends: research.trends, gaps: research.gaps, evidence_ids: plan.creative_treatment?.evidence_ids, experiment: content.decision.experiment },
      rationale: plan.review_brief?.rationale ?? content.decision.rationale,
      production_requirements: {
        ...(plan.review_brief ? { brief: plan.review_brief.production_requirements } : {}),
        captures: scenes.filter((s) => s.asset_type === "app_capture").map((s) => s.capture_ref),
        screenshots: plan.screenshot_refs,
        character: plan.character_reference,
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
      const finals = state.ideas.map((i) => i.content).filter((c) => c.status !== "planned");
      if (finals.length) await this.approvalSheet.syncContent(finals);
    }
    return state;
  }

  async decisions() {
    if (!this.approvalSheet?.configured) return { actions: [], reason: "Google Sheets is not configured" };
    // Read decisions before any refresh. Human columns are never machine-owned.
    const [ideas, assets] = await Promise.all([this.approvalSheet.pendingIdeaDecisions(), this.approvalSheet.pendingDecisions()]);
    const actions = ideas.map((entry) => ({ action: "idea_decision", entry }));
    for (const entry of assets) {
      const content = await this.repository.contentById(entry.contentId);
      if (!content.decision?.campaign?.id) continue; // historical rows cannot spend or publish
      const revision = Number(content.decision.review_revision ?? 1);
      if (entry.revision !== revision) continue;
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
      reservation = await this.repository.reserveCost("openai", this.config.OPENAI_ESTIMATED_DAILY_COST_USD, { contentId, runId: content.run_id, metadata: { operation: "idea-revision", revision } });
      const result = await this.orchestrator.brain.reviseContent(content, instructions, { app_captures: await appCaptureCatalog() });
      await this.repository.settleCost(reservation, result.costUsd, result.responseId);
      reservation = null;
      return await this.campaigns.finishIdeaRevision({ campaignId, contentId, revision, token: claim.token, plan: result.data });
    } catch (error) {
      if (reservation) await this.repository.releaseCost(reservation).catch(() => {});
      await this.campaigns.failIdeaRevision({ campaignId, contentId, revision, token: claim.token, error: error.message });
      throw error;
    }
  }

  async execute(input = {}) {
    const action = required(input.action, "action");
    const key = `${action}:${input.entry?.ideaId ?? input.entry?.contentId ?? input.campaignId ?? input.requestKey ?? ""}:${input.entry?.version ?? input.entry?.revision ?? ""}:${input.entry?.fingerprint ?? ""}`;
    return this.exclusive(key, async () => {
      if (action === "plan_campaign") return this.plan(input);
      if (action === "status") return this.campaigns.status(required(input.campaignId, "campaignId"));
      if (action === "idea_decision") return this.ideaDecision(input.entry);
      if (action === "asset_decision") return this.assetDecision(input.entry);
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
      const result = await this.orchestrator.runDaily(date, { campaignId: campaign.id });
      const ids = result.content?.map((c) => c.id) ?? result.run?.output?.content_ids ?? [];
      if (!ids.length) throw new Error(`Planning ${dateKey} has no completed content IDs. Inspect its running/failed CMO execution before retrying.`);
      await this.campaigns.registerDay({ campaignId: campaign.id, date: dateKey, contentIds: ids });
      await this.sync(campaign.id);
    }
    await this.campaigns.submit(campaign.id);
    return this.sync(campaign.id);
  }

  async ideaDecision(entry) {
    entry = normalizeReview(entry, "idea");
    const result = await this.campaigns.decideIdea({ campaignId: entry.campaignId, contentId: entry.ideaId, revision: entry.version, decision: entry.decision.toLowerCase(), instructions: entry.instructions, requestKey: `idea:${entry.ideaId}:${entry.version}:${entry.fingerprint}` });
    if (entry.decision.toLowerCase() === "reject") {
      const current = await this.campaigns.status(entry.campaignId);
      if (current.ideas.find((idea) => idea.content_id === entry.ideaId)?.revision === entry.version) await this.reviseIdea(entry.campaignId, entry.ideaId, entry.version);
    }
    await this.approvalSheet.markIdeaDecision(entry, entry.decision === "Reject" ? "Revised idea submitted for approval; no media generated" : "Idea approved. Start the first/next seven-day batch explicitly after all ideas are approved.");
    const state = await this.sync(entry.campaignId);
    return { action: "idea_reviewed", result, campaign: state.campaign };
  }

  async assetDecision(entry) {
    entry = normalizeReview(entry, "asset");
    const content = await this.repository.contentById(entry.contentId);
    const campaignId = required(content.decision?.campaign?.id, "campaign membership");
    const { review, reused } = await this.repository.createContentReview({ contentId: content.id, revision: entry.revision, decision: entry.decision.toLowerCase(), instructions: entry.instructions, sourceRef: `row:${entry.rowNumber}` });
    if (reused && review.status === "processed") {
      const result = { reused: true, result: review.result };
      if (review.decision === "approve") result.release = await this.releaseIfReady(campaignId, content.decision.campaign.batch_id);
      return result;
    }
    if (Number(content.decision.review_revision ?? 1) !== Number(entry.revision)) {
      if (reused && review.decision === "reject" && Number(content.decision.review_revision) === Number(entry.revision) + 1) {
        const result = { action: "revised_idea_requires_approval", contentId: content.id };
        await this.repository.finishContentReview(review.id, "processed", { result });
        await this.sync(campaignId);
        return result;
      }
      throw new Error("Stale asset revision");
    }
    let result;
    if (entry.decision === "Reject") {
      // Changed creative direction must be visible as a new idea version, never silently spend on it.
      await this.campaigns.decideIdea({ campaignId, contentId: content.id, revision: content.decision.campaign.idea_revision, decision: "reject", instructions: entry.instructions, requestKey: `asset-reject:${review.id}` });
      await this.reviseIdea(campaignId, content.id, content.decision.campaign.idea_revision);
      result = { action: "revised_idea_requires_approval", contentId: content.id };
    } else {
      await this.campaigns.assertGenerationAllowed(content.id);
      const approval = await this.orchestrator.approveContent(content.id);
      if (approval.skipped && approval.content.status !== "approved") throw new Error(`Cannot approve asset in ${approval.content.status}`);
      result = { action: "asset_approved", contentId: content.id, next: "When every asset in this batch is approved, use release_batch to schedule it in Buffer." };
    }
    await this.sync(campaignId);
    if (entry.decision === "Approve") {
      result.release = await this.releaseIfReady(campaignId, content.decision.campaign.batch_id);
    }
    await this.repository.finishContentReview(review.id, "processed", { result });
    await this.approvalSheet.markContentDecision(entry, result.action === "asset_approved" ? "Asset approved; Buffer release follows when every asset in this batch is approved" : "Revised idea awaits approval in Idea Review; no regeneration yet");
    return result;
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
      const result = await this.campaigns.withWork(content.id, "produce", () => this.orchestrator.processContentToReview(content.id, { maxWaitMs: 30 * 60_000 }));
      if (result.skipped && !result.content) return { action: "batch_in_progress_or_needs_reconciliation", batchId, contentId: content.id, reason: result.reason };
      results.push({ id: content.id, status: result.content?.status, pending: result.pending });
      await this.sync(campaignId);
      if (result.content?.status !== "awaiting_approval") throw new Error(`Batch stopped at ${content.content_key}: ${result.content?.failure_reason ?? result.content?.status}. Resolve this item then resume this batch; no later batch was started.`);
    }
    return { action: "batch_ready_for_asset_review", batchId, results, state: await this.sync(campaignId) };
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
