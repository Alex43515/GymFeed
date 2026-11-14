import { classifyStudioError, redact } from "./studio-errors.mjs";

const unwrap = (result) => { if (result.error) throw new Error(result.error.message); return result.data; };
export const STUDIO_JOB_KINDS = ["plan_campaign", "weekly_review", "idea_approve", "idea_reject", "asset_approve", "asset_reject", "resume_content", "sync", "department_brief", "media_edit", "media_publish", "content_republish"];
const SAFE_RETRY = new Set(["sync"]);

export function hasResumableMediaEdit(result) {
  if (!result?.parts) return Boolean(result?.requestId);
  return !result.parts.some(part => part.submitting && !part.requestId)
    && result.parts.some(part => part.requestId);
}

function canResumeCampaign(job) {
  return job.kind === "plan_campaign" &&
    (job.error?.category === "connection" || job.error?.code === "WORKER_INTERRUPTED");
}

function requiresReconciliation(job) {
  if (job.kind === "content_republish") return Boolean(job.result?.submitting || job.result?.rejectedPostId);
  return ["connection", "interrupted"].includes(job.error?.category) &&
    !job.error?.retryable && !canResumeCampaign(job) &&
    !(job.kind === "media_edit" && hasResumableMediaEdit(job.result));
}

export function canRetryStudioJob(job) {
  return ["failed", "needs_attention"].includes(job.status) && job.attempts < job.max_attempts &&
    !["moderation", "review"].includes(job.error?.category) && !requiresReconciliation(job);
}

export class StudioJobs {
  constructor({ repository, execute, secrets = [], onChange = () => {}, heartbeatMs = 20000 }) {
    Object.assign(this, { repository, execute, secrets, onChange, heartbeatMs });
    this.client = repository.client;
    this.running = false;
  }
  async event({ jobId = null, contentId = null, level = "info", stage, message, detail = {} }) {
    return unwrap(await this.client.from("marketing_studio_events").insert({ job_id: jobId, content_id: contentId,
      level, stage, message: redact(message, this.secrets), detail: redact(detail, this.secrets) }).select().single());
  }
  async enqueue({ kind, contentId = null, payload = {}, requestKey }) {
    if (!STUDIO_JOB_KINDS.includes(kind)) throw Object.assign(new Error("Unsupported operation"), { statusCode: 400 });
    if (typeof requestKey !== "string" || requestKey.trim().length < 5 || requestKey.length > 220) throw Object.assign(new Error("A stable request key is required"), { statusCode: 400 });
    const result = await this.client.from("marketing_studio_jobs").insert({ kind, content_id: contentId,
      payload, request_key: requestKey }).select().single();
    if (result.error?.code === "23505") return unwrap(await this.client.from("marketing_studio_jobs").select().eq("request_key", requestKey).single());
    const job = unwrap(result);
    await this.event({ jobId: job.id, contentId, stage: "queued", message: `${kind} queued`, detail: { attempt: 0 } });
    this.onChange();
    return job;
  }
  async retry(id) {
    const job = unwrap(await this.client.from("marketing_studio_jobs").select().eq("id", id).single());
    if (!["failed", "needs_attention"].includes(job.status)) throw Object.assign(new Error("Only stopped jobs can be retried"), { statusCode: 409 });
    if (["moderation", "review"].includes(job.error?.category)) throw Object.assign(new Error("Review or revise the content before another attempt"), { statusCode: 409 });
    // Ambiguous writes require a content-level resume, never a repeat of the original submission.
    if (requiresReconciliation(job)) {
      throw Object.assign(new Error("Reconciliation required: open the content and resume its saved tasks"), { statusCode: 409 });
    }
    if (job.attempts >= job.max_attempts) throw Object.assign(new Error("Retry limit reached. Resolve the cause and create a new explicit operation."), { statusCode: 409 });
    const updated = unwrap(await this.client.from("marketing_studio_jobs").update({ status: "queued", next_run_at: new Date().toISOString(),
      ...(canResumeCampaign(job) ? { payload: { ...job.payload, resumeBefore: job.updated_at } } : {}),
      completed_at: null, lock_token: null, updated_at: new Date().toISOString() })
      .eq("id", id).eq("status", job.status).eq("attempts", job.attempts).select().maybeSingle());
    if (!updated) throw Object.assign(new Error("Job status changed. Refresh before retrying."), { statusCode: 409 });
    await this.event({ jobId: id, contentId: job.content_id, stage: "retry", message: `Manual retry requested after attempt ${job.attempts}`, detail: { previous_error: job.error } });
    this.onChange();
    return updated;
  }
  async cancel(id) {
    const job = unwrap(await this.client.from("marketing_studio_jobs").update({ status: "cancelled", completed_at: new Date().toISOString() })
      .eq("id", id).in("status", ["queued", "retry_wait"]).select().maybeSingle());
    if (!job) throw Object.assign(new Error("Only queued jobs can be cancelled; an accepted provider task cannot be undone"), { statusCode: 409 });
    await this.event({ jobId: id, contentId: job.content_id, stage: "cancelled", message: "Queued operation cancelled" });
    this.onChange();
    return job;
  }
  async tick() {
    if (this.running) return { busy: true };
    this.running = true;
    let heartbeat;
    let job;
    try {
      job = unwrap(await this.client.rpc("marketing_studio_claim_job"));
      if (!job) return { idle: true };
      this.onChange();
      const update = async (patch) => unwrap(await this.client.from("marketing_studio_jobs").update({ ...patch, updated_at: new Date().toISOString() })
        .eq("id", job.id).eq("lock_token", job.lock_token).eq("status", "running").select().maybeSingle());
      heartbeat = setInterval(() => update({ heartbeat_at: new Date().toISOString() }).catch(() => {}), this.heartbeatMs);
      heartbeat.unref?.();
      await this.event({ jobId: job.id, contentId: job.content_id, stage: "running", message: `Started ${job.kind}, attempt ${job.attempts}/${job.max_attempts}` });
      try {
        const result = await this.execute(job);
        if (result?.pending || result?.blocked || result?.skipped && result?.reason) {
          throw Object.assign(new Error(result.reason ?? "Operation is still pending; inspect its saved state before resuming"), { needsAttention: true });
        }
        await update({ status: "succeeded", completed_at: new Date().toISOString(), error: null, result: redact(result, this.secrets) });
        await this.event({ jobId: job.id, contentId: job.content_id, stage: "completed", message: `${job.kind} completed` });
      } catch (error) {
        const info = classifyStudioError(error, { safeToRetry: SAFE_RETRY.has(job.kind), secrets: this.secrets });
        if (job.kind === "plan_campaign" && info.category === "connection" && !info.retryable) {
          info.next_action = "The completed days are saved. Resume the campaign to retry the unfinished day.";
        }
        const retry = info.retryable && job.attempts < job.max_attempts;
        const nextRun = new Date(Date.now() + Math.min(300000, 15000 * 2 ** (job.attempts - 1)) + Math.floor(Math.random() * 3000)).toISOString();
        await update({ status: retry ? "retry_wait" : error.needsAttention || ["interrupted", "connection"].includes(info.category) ? "needs_attention" : "failed",
          error: info, next_run_at: nextRun, completed_at: retry ? null : new Date().toISOString() });
        await this.event({ jobId: job.id, contentId: job.content_id, level: "error", stage: retry ? "retry_wait" : "failed",
          message: info.message, detail: { ...info, attempt: job.attempts, next_retry_at: retry ? nextRun : null } });
      }
      return { processed: job.id };
    } finally {
      clearInterval(heartbeat);
      this.running = false;
      this.onChange();
    }
  }
}
