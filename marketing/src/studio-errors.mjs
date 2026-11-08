export function redact(value, secrets = []) {
  if (typeof value === "string") {
    let text = value.replace(/(Bearer\s+)[\w.\-]+/gi, "$1[redacted]")
      .replace(/([?&](?:key|token|mcp_token|api_key|access_token)=)[^&\s]+/gi, "$1[redacted]")
      .replace(/\b(?:sk-|key_)[A-Za-z0-9_-]{16,}/g, "[redacted]");
    for (const secret of secrets.filter(s => typeof s === "string" && s.length >= 12)) text = text.split(secret).join("[redacted]");
    return text.slice(0, 12000);
  }
  if (Array.isArray(value)) return value.map(v => redact(v, secrets));
  if (value && typeof value === "object") return Object.fromEntries(Object.entries(value).map(([key, item]) =>
    [key, /password|authorization|api.?key|service.?role|private.?key|credential|lock_token/i.test(key) ? "[redacted]" : redact(item, secrets)]));
  return value;
}

export function classifyStudioError(error, { safeToRetry = false, secrets = [] } = {}) {
  const message = redact(error?.message ?? String(error), secrets);
  const status = Number(error?.statusCode ?? error?.status ?? 0);
  let category = "application", code = "OPERATION_FAILED", retryable = false;
  let next_action = "Open the job details, correct the cause, then retry this operation.";
  if (/budget|credit|insufficient funds|balance/i.test(message)) {
    category = "budget"; code = "BUDGET_BLOCKED"; next_action = "Review available provider credits and the existing budget. Limits have not been raised.";
  } else if (/missing|not found|no such file|ENOENT|required Drive|capture.*unavailable/i.test(message)) {
    category = "missing_asset"; code = "ASSET_REQUIRED"; next_action = "Upload the exact requested file, then retry intake for this item.";
  } else if (status === 401 || status === 403 || /unauthoriz|permission|invalid.*key|credential|oauth/i.test(message)) {
    category = "authorization"; code = "CONNECTION_REQUIRED"; next_action = "Reconnect the named service or correct its server credentials, then retry.";
  } else if (/content_policy|moderation|responsible ai|safety filter/i.test(message)) {
    category = "moderation"; code = "PROVIDER_REJECTED"; next_action = "Review the provider rejection and the affected scene. Revise the idea before another generation.";
  } else if (/stale|revision|approved.*hash|not.*approved/i.test(message)) {
    category = "review"; code = "REVIEW_REQUIRED"; next_action = "Refresh the item and review its current revision before approving.";
  } else if (/uncertain|reconciliation|heartbeat|interrupted|work_needs_completion/i.test(message)) {
    category = "interrupted"; code = "RECONCILIATION_REQUIRED"; next_action = "Inspect saved provider task IDs and the last attempt before resuming. Completed scenes must be reused.";
  } else if (status === 429 || status >= 500 || /ETIMEDOUT|ECONNRESET|ECONNREFUSED|fetch failed|timeout|timed out|rate.?limit|temporarily unavailable/i.test(message)) {
    category = "connection"; code = status === 429 ? "RATE_LIMITED" : "SERVICE_UNAVAILABLE";
    retryable = safeToRetry || error?.safeToRetry === true;
    next_action = retryable ? "A temporary failure will retry with backoff. You can inspect every attempt below."
      : "The request may have reached the provider. Inspect saved tasks before resuming to avoid duplicate charges.";
  }
  return { code, category, message, retryable, next_action, status: status || null, at: new Date().toISOString() };
}
