// Drains the trusted lifecycle_emails queue and sends each email through
// Resend. Callers cannot choose recipients or content: database triggers and
// the queue_premium_reminders() cron job are the only source of queued rows,
// and the address is read from auth.users at claim time.

import { emailFor } from "./templates.mjs";

const RESEND_URL = "https://api.resend.com/emails";

function json(status, body) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
  });
}

async function finish(admin, id, status, error = null) {
  const { error: rpcError } = await admin.rpc("finish_lifecycle_email", {
    p_id: id,
    p_status: status,
    p_error: error,
  });
  if (rpcError) throw new Error(`finish_lifecycle_email: ${rpcError.message}`);
}

export async function drainLifecycleEmails({
  admin,
  resendApiKey,
  from,
  replyTo,
  fetchImpl = fetch,
  now = () => new Date(),
  batchSize = 20,
}) {
  if (!resendApiKey) {
    // Not configured yet: still drop emails that are no longer worth sending,
    // so nothing stale goes out the day the key is added.
    const { error } = await admin.rpc("expire_lifecycle_emails");
    if (error) throw new Error(`expire_lifecycle_emails: ${error.message}`);
    return { configured: false, sent: 0, skipped: 0, retried: 0, failed: 0 };
  }

  const { data, error } = await admin.rpc("claim_lifecycle_emails", { p_batch_size: batchSize });
  if (error) throw new Error(`claim_lifecycle_emails: ${error.message}`);

  const result = { configured: true, sent: 0, skipped: 0, retried: 0, failed: 0 };
  for (const row of data ?? []) {
    const email = row.email ? emailFor(row, now()) : null;
    if (!email) {
      await finish(admin, row.id, "skipped", row.email ? "not applicable" : "no address");
      result.skipped++;
      continue;
    }
    try {
      const response = await fetchImpl(RESEND_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${resendApiKey}`,
          "Content-Type": "application/json",
          // Resend drops a repeat with the same key, so a retry after a lost
          // response cannot send the same email twice.
          "Idempotency-Key": `gymfeed-lifecycle-${row.id}`,
        },
        body: JSON.stringify({
          from,
          to: [row.email],
          ...(replyTo ? { reply_to: replyTo } : {}),
          subject: email.subject,
          text: email.text,
          html: email.html,
          tags: [{ name: "kind", value: row.kind }],
        }),
      });
      if (response.ok) {
        await finish(admin, row.id, "sent");
        result.sent++;
      } else {
        const detail = (await response.text().catch(() => "")).slice(0, 300);
        // 4xx other than rate limits will not succeed on retry.
        const permanent = response.status >= 400 && response.status < 500 && response.status !== 429;
        await finish(admin, row.id, permanent ? "failed" : "retry", `resend ${response.status}: ${detail}`);
        if (permanent) result.failed++;
        else result.retried++;
      }
    } catch (sendError) {
      await finish(admin, row.id, "retry", String(sendError?.message ?? sendError).slice(0, 300));
      result.retried++;
    }
  }
  return result;
}

export function createLifecycleEmailHandler(options) {
  return async (request) => {
    if (request.method !== "POST") return json(405, { error: "method not allowed" });
    try {
      const result = await drainLifecycleEmails({ ...options, admin: options.adminClient() });
      return json(200, result);
    } catch (error) {
      return json(500, { error: String(error?.message ?? error) });
    }
  };
}
