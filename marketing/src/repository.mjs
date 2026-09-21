import { createClient } from "@supabase/supabase-js";

function unwrap(result, label) {
  if (result.error) throw new Error(`${label}: ${result.error.message}`);
  return result.data;
}

function contentKeys(now, revision = 1) {
  const date = now.toISOString().slice(0, 10).replaceAll("-", "");
  const suffix = String(revision).padStart(3, "0");
  return { video: `GF-${date}-V${suffix}`, instagram: `GF-${date}-I${suffix}` };
}

export class MarketingRepository {
  constructor(config, client) {
    this.config = config;
    this.client = client ?? createClient(config.SUPABASE_URL, config.SUPABASE_SERVICE_ROLE_KEY, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
  }

  async brandConfig() {
    return unwrap(
      await this.client.from("marketing_brand_config").select("*").eq("id", "gymfeed").single(),
      "load marketing brand config",
    );
  }

  async loadContext() {
    const since30 = new Date(Date.now() - 30 * 864e5).toISOString();
    const since7 = new Date(Date.now() - 7 * 864e5).toISOString();
    const [brand, learnings, content, publications, events30, events7, costs] = await Promise.all([
      this.brandConfig(),
      this.client.from("marketing_learnings").select("*").neq("status", "retired").order("confidence", { ascending: false }).limit(50),
      this.client.from("marketing_content").select("*").gte("created_at", since30).order("created_at", { ascending: false }).limit(100),
      this.client.from("marketing_publications").select("*").gte("created_at", since30).order("created_at", { ascending: false }).limit(200),
      this.client.from("marketing_events").select("*").gte("occurred_at", since30).order("occurred_at", { ascending: false }).limit(2000),
      this.client.from("marketing_events").select("*").gte("occurred_at", since7).order("occurred_at", { ascending: false }).limit(1000),
      this.client.from("marketing_cost_ledger").select("*").gte("created_at", since30).order("created_at", { ascending: false }).limit(500),
    ]);
    return {
      brand,
      learnings: unwrap(learnings, "load learnings"),
      content: unwrap(content, "load content"),
      publications: unwrap(publications, "load publications"),
      events_30d: unwrap(events30, "load 30-day events"),
      events_7d: unwrap(events7, "load 7-day events"),
      costs: unwrap(costs, "load marketing costs"),
    };
  }

  async startRun(workflow, idempotencyKey, input = {}) {
    const result = await this.client.from("marketing_runs").insert({
      workflow,
      idempotency_key: idempotencyKey,
      input,
    }).select("*").single();
    if (!result.error) return { run: result.data, reused: false };
    if (result.error.code !== "23505") throw new Error(`start marketing run: ${result.error.message}`);
    const existing = unwrap(
      await this.client.from("marketing_runs").select("*").eq("idempotency_key", idempotencyKey).single(),
      "load existing marketing run",
    );
    if (["failed", "skipped"].includes(existing.status)) {
      const restarted = unwrap(await this.client.from("marketing_runs").update({
        status: "running",
        input,
        output: {},
        error: null,
        actual_cost_usd: null,
        started_at: new Date().toISOString(),
        completed_at: null,
      }).eq("id", existing.id).select("*").single(), "restart marketing run");
      return { run: restarted, reused: false };
    }
    return { run: existing, reused: true };
  }

  async finishRun(id, status, output = {}, actualCostUsd = null, error = null) {
    return unwrap(await this.client.from("marketing_runs").update({
      status,
      output,
      actual_cost_usd: actualCostUsd,
      error,
      completed_at: new Date().toISOString(),
    }).eq("id", id).select("*").single(), "finish marketing run");
  }

  async saveDailyDecision(runId, decision, now = new Date(), revision = 1, campaignId = null) {
    const sources = [...new Set(decision.trends.flatMap((trend) => trend.source_urls))];
    unwrap(await this.client.from("marketing_research").insert({
      run_id: runId,
      summary: decision.research_summary,
      trends: decision.trends,
      sources,
      valid_until: new Date(now.getTime() + 36 * 36e5).toISOString(),
    }), "save daily research");

    const keys = contentKeys(now, revision);
    if (campaignId) for (const kind of Object.keys(keys)) keys[kind] = `${keys[kind]}-${campaignId}`;
    const common = {
      run_id: runId,
      status: "planned",
    };
    const inserted = unwrap(await this.client.from("marketing_content").upsert([
      {
        ...common,
        content_key: keys.video,
        content_type: "video",
        topic: decision.video.topic,
        concept: decision.video.concept,
        hook: decision.video.hook,
        decision: {
          content: decision.video,
          experiment: decision.experiment,
          rationale: decision.decision_rationale,
          risk_flags: decision.risk_flags,
          research: {
            summary: decision.research_summary,
            trends: decision.trends,
            gaps: decision.research_gaps,
          },
          candidate_concepts: decision.candidate_concepts,
          selected_strategy: decision.selected_strategy,
        },
      },
      {
        ...common,
        content_key: keys.instagram,
        content_type: decision.instagram.format,
        topic: decision.instagram.topic,
        concept: decision.instagram.concept,
        hook: decision.instagram.hook,
        decision: {
          content: decision.instagram,
          experiment: decision.experiment,
          rationale: decision.decision_rationale,
          risk_flags: decision.risk_flags,
          research: {
            summary: decision.research_summary,
            trends: decision.trends,
            gaps: decision.research_gaps,
          },
          candidate_concepts: decision.candidate_concepts,
          selected_strategy: decision.selected_strategy,
        },
      },
    ], { onConflict: "content_key", ignoreDuplicates: true }).select("*"), "save daily content decisions");
    return inserted;
  }

  async contentById(id) {
    return unwrap(await this.client.from("marketing_content").select("*").eq("id", id).single(), "load marketing content");
  }

  async campaignCommand(action, payload = {}) {
    return unwrap(await this.client.rpc("marketing_campaign_command", { p_action: action, p_payload: payload }), `campaign ${action}`);
  }

  async campaignList() {
    return unwrap(await this.client.from("marketing_campaigns").select("id,name,start_date,days,status").order("created_at", { ascending: false }).limit(50), "list campaigns");
  }

  async approvalSheetContent() {
    return unwrap(
      await this.client
        .from("marketing_content")
        .select("*")
        .in("status", ["generating", "generated", "qa_failed", "awaiting_approval", "approved", "scheduled", "published", "failed"])
        .order("updated_at", { ascending: false })
        .limit(200),
      "load approval sheet content",
    );
  }

  async nextContent(status) {
    const rows = unwrap(await this.client.from("marketing_content").select("*").eq("status", status).order("created_at").limit(1), `load ${status} content`);
    return rows[0] ?? null;
  }

  async updateContent(id, patch) {
    return unwrap(await this.client.from("marketing_content").update(patch).eq("id", id).select("*").single(), "update marketing content");
  }

  async resetContentForRevision(content, revisedPlan, instructions) {
    const previousRevision = Number(content.decision?.review_revision ?? 1);
    const history = [...(content.decision?.review_history ?? []), {
      revision: previousRevision,
      rejected_at: new Date().toISOString(),
      instructions,
      asset_urls: content.asset_urls ?? [],
      thumbnail_url: content.thumbnail_url ?? null,
      qa_score: content.qa_score ?? null,
      qa: content.qa ?? {},
    }];
    return this.updateContent(content.id, {
      status: "planned",
      topic: revisedPlan.topic,
      concept: revisedPlan.concept,
      hook: revisedPlan.hook,
      decision: {
        ...content.decision,
        content: revisedPlan,
        review_revision: previousRevision + 1,
        review_instructions: instructions,
        review_history: history,
        generation: {},
      },
      provider: null,
      provider_task_id: null,
      asset_urls: [],
      thumbnail_url: null,
      qa_score: null,
      qa: {},
      failure_reason: null,
      approved_by: null,
      approved_at: null,
      scheduled_at: null,
      published_at: null,
    });
  }

  async createContentReview({ contentId, revision, decision, instructions = "", sourceRef = null }) {
    const inserted = await this.client.from("marketing_content_reviews").insert({
      content_id: contentId,
      revision,
      decision,
      instructions,
      source: "google_sheets",
      source_ref: sourceRef,
    }).select("*").single();
    if (!inserted.error) return { review: inserted.data, reused: false };
    if (inserted.error.code !== "23505") throw new Error(`create content review: ${inserted.error.message}`);
    const existing = unwrap(
      await this.client.from("marketing_content_reviews").select("*").eq("content_id", contentId).eq("revision", revision).single(),
      "load existing content review",
    );
    if (["pending", "processed"].includes(existing.status)) return { review: existing, reused: true };
    const refreshed = unwrap(await this.client.from("marketing_content_reviews").update({
      decision,
      instructions,
      source_ref: sourceRef,
      status: "pending",
      result: {},
      error: null,
      processed_at: null,
    }).eq("id", existing.id).select("*").single(), "refresh content review");
    return { review: refreshed, reused: false };
  }

  async contentReviewById(id) {
    return unwrap(
      await this.client.from("marketing_content_reviews").select("*").eq("id", id).single(),
      "load content review",
    );
  }

  async finishContentReview(id, status, { result = {}, error = null } = {}) {
    return unwrap(await this.client.from("marketing_content_reviews").update({
      status,
      result,
      error,
      processed_at: status === "processed" ? new Date().toISOString() : null,
    }).eq("id", id).select("*").single(), "finish content review");
  }

  async reserveCost(provider, estimatedCostUsd, { runId = null, contentId = null, metadata = {} } = {}) {
    return unwrap(await this.client.rpc("reserve_marketing_cost", {
      p_provider: provider,
      p_estimated_cost_usd: estimatedCostUsd,
      p_run_id: runId,
      p_content_id: contentId,
      p_metadata: metadata,
    }), `reserve ${provider} cost`);
  }

  async settleCost(reservationId, actualCostUsd, externalRef = null) {
    unwrap(await this.client.rpc("settle_marketing_cost", {
      p_reservation_id: reservationId,
      p_actual_cost_usd: actualCostUsd,
      p_external_ref: externalRef,
    }), "settle marketing cost");
  }

  async releaseCost(reservationId) {
    unwrap(await this.client.rpc("release_marketing_cost", { p_reservation_id: reservationId }), "release marketing cost");
  }

  async uploadAsset(path, data, contentType) {
    unwrap(await this.client.storage.from(this.config.SUPABASE_MARKETING_BUCKET).upload(path, data, {
      contentType,
      upsert: true,
      cacheControl: "31536000",
    }), "upload marketing asset");
    const { data: publicData } = this.client.storage.from(this.config.SUPABASE_MARKETING_BUCKET).getPublicUrl(path);
    return publicData.publicUrl;
  }

  async upsertPublication(publication) {
    return unwrap(await this.client.from("marketing_publications").upsert(publication, {
      onConflict: "content_id,platform",
    }).select("*").single(), "save marketing publication");
  }

  async publicationByContent(contentId) {
    return unwrap(await this.client.from("marketing_publications").select("*").eq("content_id", contentId), "load content publications");
  }

  async pendingPublications() {
    const staleBefore = new Date(Date.now() - 23 * 36e5).toISOString();
    const [active, stalePublished] = await Promise.all([
      this.client.from("marketing_publications").select("*").in("status", ["pending", "scheduled", "publishing"]).not("provider_request_id", "is", null).order("created_at").limit(25),
      this.client.from("marketing_publications").select("*").eq("status", "published").not("provider_request_id", "is", null).or(`last_metrics_sync_at.is.null,last_metrics_sync_at.lt.${staleBefore}`).order("published_at", { ascending: false }).limit(25),
    ]);
    return [
      ...unwrap(active, "load pending publications"),
      ...unwrap(stalePublished, "load stale publication metrics"),
    ].slice(0, 50);
  }

  async updatePublication(id, patch) {
    return unwrap(await this.client.from("marketing_publications").update(patch).eq("id", id).select("*").single(), "update marketing publication");
  }

  async saveWeeklyReview(runId, review) {
    if (!review.findings.length) return [];
    return unwrap(await this.client.from("marketing_learnings").insert(review.findings.map((finding) => ({
      run_id: runId,
      ...finding,
    }))).select("*"), "save weekly learnings");
  }
}
