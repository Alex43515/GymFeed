import { randomUUID } from "node:crypto";

// The database RPC is the authority for state transitions. Never replace these
// calls with a read/check/write sequence: multiple n8n executions may race.
function nonempty(value, label) {
  if (typeof value !== "string" || !value.trim()) throw new Error(`${label} is required`);
  return value.trim();
}

export function campaignDate(value) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value ?? "")) throw new Error("A YYYY-MM-DD date is required");
  const date = new Date(`${value}T12:00:00.000Z`);
  if (!Number.isFinite(date.getTime()) || date.toISOString().slice(0, 10) !== value) {
    throw new Error("Invalid campaign date");
  }
  return value;
}

export function campaignDates(startDate, days) {
  campaignDate(startDate);
  if (!Number.isInteger(days) || days < 1 || days > 31) throw new Error("Campaign days must be between 1 and 31");
  const start = Date.parse(`${startDate}T12:00:00.000Z`);
  return Array.from({ length: days }, (_, index) => new Date(start + index * 864e5).toISOString().slice(0, 10));
}

function revisionNumber(value) {
  if (!Number.isInteger(value) || value < 1) throw new Error("An explicit positive idea revision is required");
  return value;
}

// A review card shows the evidence actually saved with this idea, not invented
// metrics or a promise that the concept will go viral.
export function campaignIdeaCard(idea) {
  const content = idea.content ?? {};
  const decision = content.decision ?? {};
  const plan = decision.content ?? {};
  const treatment = plan.creative_treatment ?? {};
  const cited = new Set(treatment.evidence_ids ?? []);
  const research = decision.research ?? {};
  return {
    campaign_id: idea.campaign_id ?? decision.campaign?.id,
    content_id: idea.content_id ?? content.id,
    content_key: content.content_key,
    date: idea.publication_date,
    format: content.content_type,
    revision: idea.revision,
    idea_status: idea.idea_status,
    title: plan.title ?? plan.platform_copy?.youtube_title ?? plan.topic ?? content.topic ?? "",
    hook: plan.hook ?? content.hook ?? "",
    description: plan.concept ?? content.concept ?? "",
    audience: plan.target_audience ?? decision.target_audience ?? "Not specified; needs review",
    features: plan.product_features ?? plan.feature_sequence ?? [plan.product_feature].filter(Boolean),
    rationale: decision.rationale ?? "",
    evidence: (research.trends ?? []).map((trend) => ({ ...trend, explicitly_cited: cited.has(trend.evidence_id) })),
    evidence_gaps: research.gaps ?? [],
    hypothesis: decision.experiment?.hypothesis ?? "Not specified; needs review",
    success_metric: decision.selected_strategy?.primary_success_metric ?? decision.experiment?.success_metric ?? "",
    creative_treatment: treatment,
    shots_or_slides: plan.scenes ?? plan.slides ?? [],
    dialogue: plan.voiceover_script || (plan.scenes ?? []).map((scene) => scene.spoken_dialogue).filter(Boolean).join("\n"),
    caption: plan.caption ?? plan.platform_copy?.instagram_caption ?? "",
    platform_copy: plan.platform_copy ?? {},
    cta: plan.cta ?? "",
    references: plan.screenshot_refs ?? [],
    continuity: plan.character_reference ?? {},
    estimated_cost_usd: decision.estimated_cost_usd ?? null,
    instructions: idea.instructions ?? "",
  };
}

export class MarketingCampaigns {
  constructor({ repository, brain, revise } = {}) {
    if (!repository?.campaignCommand) throw new Error("Campaign repository is required");
    this.repository = repository;
    // Pass a budget-aware callback from the orchestrator. The optional brain
    // adapter is useful in isolated tests but must itself enforce cost limits.
    this.revise = revise ?? (brain ? (content, instructions) => brain.reviseContent(content, instructions) : null);
  }

  command(action, payload) {
    return this.repository.campaignCommand(action, payload);
  }

  async create({ name, startDate, days = 28, timezone = "Europe/Belgrade", requestKey }) {
    campaignDates(startDate, days);
    try { new Intl.DateTimeFormat("en", { timeZone: timezone }).format(); }
    catch { throw new Error("A valid IANA campaign timezone is required"); }
    return this.command("create", {
      name: nonempty(name, "Campaign name"), start_date: startDate, days, timezone,
      request_key: nonempty(requestKey, "Campaign request key"),
    });
  }

  status(campaignId) {
    return this.command("status", { campaign_id: nonempty(campaignId, "Campaign ID") });
  }

  registerDay({ campaignId, date, contentIds }) {
    if (!Array.isArray(contentIds) || contentIds.length !== 2 || new Set(contentIds).size !== 2) {
      throw new Error("Register exactly one video and one carousel/image content ID per day");
    }
    contentIds.forEach((id) => nonempty(id, "Content ID"));
    return this.command("register_day", {
      campaign_id: nonempty(campaignId, "Campaign ID"), date: campaignDate(date), content_ids: contentIds,
    });
  }

  submit(campaignId) {
    return this.command("submit", { campaign_id: nonempty(campaignId, "Campaign ID") });
  }

  decideIdea({ campaignId, contentId, revision, decision, instructions = "", requestKey, reviewer = "google_sheets" }) {
    const normalized = String(decision).trim().toLowerCase();
    if (!["approve", "reject"].includes(normalized)) throw new Error("Idea decision must be approve or reject");
    if (normalized === "reject") nonempty(instructions, "Revision instructions");
    return this.command("decide_idea", {
      campaign_id: nonempty(campaignId, "Campaign ID"), content_id: nonempty(contentId, "Content ID"),
      revision: revisionNumber(revision), decision: normalized, instructions: instructions.trim(),
      request_key: nonempty(requestKey, "Decision request key"), reviewer: nonempty(reviewer, "Reviewer"),
    });
  }

  claimIdeaRevision({ campaignId, contentId, revision }) {
    return this.command("claim_revision", {
      campaign_id: nonempty(campaignId, "Campaign ID"), content_id: nonempty(contentId, "Content ID"),
      revision: revisionNumber(revision),
    });
  }

  finishIdeaRevision({ campaignId, contentId, revision, token, plan, metadata = {} }) {
    if (!plan || typeof plan !== "object" || Array.isArray(plan)) throw new Error("Revised plan is required");
    for (const field of ["topic", "concept", "hook"]) nonempty(plan[field], `Revised ${field}`);
    return this.command("finish_revision", {
      campaign_id: campaignId, content_id: contentId, revision: revisionNumber(revision),
      token: nonempty(token, "Revision claim token"), plan, metadata,
    });
  }

  failIdeaRevision({ campaignId, contentId, revision, token, error }) {
    return this.command("fail_revision", {
      campaign_id: campaignId, content_id: contentId, revision: revisionNumber(revision),
      token: nonempty(token, "Revision claim token"), error: String(error?.message ?? error).slice(0, 2000),
    });
  }

  async reviseIdea(input) {
    if (!this.revise) throw new Error("Budget-aware idea revision callback is not configured");
    const claim = await this.claimIdeaRevision(input);
    if (!claim.claimed) return claim;
    try {
      const revised = await this.revise(claim.content, claim.instructions);
      return await this.finishIdeaRevision({
        ...input, token: claim.token, plan: revised.data ?? revised,
        metadata: { response_id: revised.responseId ?? null, cost_usd: revised.costUsd ?? null },
      });
    } catch (error) {
      await this.failIdeaRevision({ ...input, token: claim.token, error });
      throw error;
    }
  }

  startBatch({ campaignId, requestKey }) {
    return this.command("start_batch", {
      campaign_id: nonempty(campaignId, "Campaign ID"), request_key: nonempty(requestKey, "Batch request key"),
    });
  }

  assertGenerationAllowed(contentId) {
    return this.command("assert_generation", { content_id: nonempty(contentId, "Content ID") });
  }

  assertPublicationAllowed(contentId) {
    return this.command("assert_publication", { content_id: nonempty(contentId, "Content ID") });
  }

  acquireWork(contentId, operation, requestKey = randomUUID()) {
    return this.command("acquire_work", {
      content_id: nonempty(contentId, "Content ID"), operation: nonempty(operation, "Work operation"),
      request_key: nonempty(requestKey, "Work request key"),
    });
  }

  finishWork(contentId, token, { state = "completed", result = {}, error = null } = {}) {
    if (!["completed", "failed", "uncertain"].includes(state)) throw new Error("Invalid work completion state");
    return this.command("finish_work", { content_id: contentId, token, state, result, error });
  }

  async withWork(contentId, operation, work, { requestKey = randomUUID() } = {}) {
    const claim = await this.acquireWork(contentId, operation, requestKey);
    if (!claim.acquired) return { skipped: true, reason: claim.reason, reused: claim.reused, result: claim.result ?? null };
    let result;
    try { result = await work(); }
    catch (error) {
      // A timeout is not evidence that an external provider did no work. Do not
      // automatically charge again after an ambiguous request or worker crash.
      await this.finishWork(contentId, claim.token, {
        state: error.safeToRetry === true ? "failed" : "uncertain", error: String(error.message).slice(0, 2000),
      });
      throw error;
    }
    await this.finishWork(contentId, claim.token, { result });
    return result;
  }
}
