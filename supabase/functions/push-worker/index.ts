// Drains the trusted push_queue table and delivers audible FCM HTTP v1
// notifications. Callers cannot provide recipients or notification content;
// database triggers are the sole source of queued jobs.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const SERVICE_ACCOUNT_RAW = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");

const CHANNEL_ID = "gymfeed_alerts_v2";
const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token";

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
  token_uri?: string;
};

type PushJob = {
  id: string;
  recipient_ids: string[];
  title: string;
  body: string;
  image_url: string;
  initial_page: string;
  parameter_data: Record<string, unknown>;
};

type DeviceToken = {
  id: string;
  token: string;
};

let cachedAccessToken: { value: string; expiresAt: number } | null = null;

function json(status: number, value: unknown): Response {
  return new Response(JSON.stringify(value), {
    status,
    headers: { "content-type": "application/json" },
  });
}

function base64Url(value: string | Uint8Array): string {
  const bytes = typeof value === "string"
    ? new TextEncoder().encode(value)
    : value;
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/, "");
}

function pemToBytes(pem: string): Uint8Array {
  const body = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replaceAll(/\s/g, "");
  return Uint8Array.from(atob(body), (char) => char.charCodeAt(0));
}

async function serviceAccountAccessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && cachedAccessToken.expiresAt > now + 60) {
    return cachedAccessToken.value;
  }

  const header = base64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64Url(JSON.stringify({
    iss: account.client_email,
    scope: FCM_SCOPE,
    aud: account.token_uri ?? GOOGLE_TOKEN_URL,
    iat: now,
    exp: now + 3600,
  }));
  const unsigned = `${header}.${claims}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToBytes(account.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const assertion = `${unsigned}.${base64Url(new Uint8Array(signature))}`;
  const response = await fetch(account.token_uri ?? GOOGLE_TOKEN_URL, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  const payload = await response.json();
  if (!response.ok || typeof payload.access_token !== "string") {
    throw new Error(`Google OAuth failed (${response.status}): ${JSON.stringify(payload)}`);
  }
  cachedAccessToken = {
    value: payload.access_token,
    expiresAt: now + Number(payload.expires_in ?? 3600),
  };
  return cachedAccessToken.value;
}

function messageFor(job: PushJob, token: string) {
  const image = job.image_url?.trim();
  return {
    message: {
      token,
      notification: {
        title: job.title,
        body: job.body,
        ...(image ? { image } : {}),
      },
      data: {
        pushId: job.id,
        initialPageName: job.initial_page || "Notifications",
        parameterData: JSON.stringify(job.parameter_data ?? {}),
      },
      android: {
        priority: "high",
        notification: {
          channel_id: CHANNEL_ID,
          sound: "default",
          default_vibrate_timings: true,
          notification_priority: "PRIORITY_MAX",
          ...(image ? { image } : {}),
        },
      },
      apns: {
        headers: { "apns-priority": "10" },
        payload: {
          aps: {
            sound: "default",
            badge: 1,
            "content-available": 1,
          },
        },
        ...(image ? { fcm_options: { image } } : {}),
      },
    },
  };
}

async function deliver(
  account: ServiceAccount,
  accessToken: string,
  job: PushJob,
  device: DeviceToken,
): Promise<{ sent: boolean; invalid: boolean; error?: string }> {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        authorization: `Bearer ${accessToken}`,
        "content-type": "application/json",
      },
      body: JSON.stringify(messageFor(job, device.token)),
    },
  );
  const responseText = await response.text();
  if (response.ok) return { sent: true, invalid: false };

  const invalid = response.status === 404 ||
    /UNREGISTERED|registration-token-not-registered/i.test(responseText);
  return {
    sent: false,
    invalid,
    error: `FCM ${response.status}: ${responseText.slice(0, 500)}`,
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok");
  if (req.method !== "POST") return json(405, { error: "method not allowed" });
  if (!SERVICE_ACCOUNT_RAW) {
    return json(503, { error: "FIREBASE_SERVICE_ACCOUNT_JSON not configured" });
  }

  let serviceAccount: ServiceAccount;
  try {
    serviceAccount = JSON.parse(SERVICE_ACCOUNT_RAW) as ServiceAccount;
    if (!serviceAccount.project_id || !serviceAccount.client_email || !serviceAccount.private_key) {
      throw new Error("required service-account fields are missing");
    }
  } catch (error) {
    return json(503, { error: `invalid Firebase service account: ${error}` });
  }

  const admin = createClient(SUPABASE_URL, SERVICE_KEY);
  let accessToken: string;
  try {
    accessToken = await serviceAccountAccessToken(serviceAccount);
  } catch (error) {
    return json(503, { error: String(error) });
  }

  const { data: claimed, error: claimError } = await admin.rpc(
    "claim_push_notifications",
    { p_batch_size: 25 },
  );
  if (claimError) return json(500, { error: claimError.message });

  const jobs = (claimed ?? []) as PushJob[];
  let jobsSent = 0;
  let notificationsSent = 0;
  const errors: string[] = [];

  for (const job of jobs) {
    const { data: tokenRows, error: tokenError } = await admin
      .from("fcm_tokens")
      .select("id,token")
      .in("user_id", job.recipient_ids ?? []);
    if (tokenError) {
      await admin.from("push_queue").update({
        status: "queued",
        error: tokenError.message,
      }).eq("id", job.id);
      errors.push(tokenError.message);
      continue;
    }

    let sent = 0;
    let transientFailures = 0;
    const jobErrors: string[] = [];
    for (const device of (tokenRows ?? []) as DeviceToken[]) {
      const result = await deliver(serviceAccount, accessToken, job, device);
      if (result.sent) {
        sent += 1;
      } else if (result.invalid) {
        await admin.from("fcm_tokens").delete().eq("id", device.id);
      } else {
        transientFailures += 1;
      }
      if (result.error) jobErrors.push(result.error);
    }

    const shouldRetry = sent === 0 && transientFailures > 0;
    await admin.from("push_queue").update({
      status: shouldRetry ? "queued" : "sent",
      num_sent: sent,
      error: jobErrors.length ? jobErrors.join(" | ").slice(0, 2000) : null,
      processed_at: shouldRetry ? null : new Date().toISOString(),
    }).eq("id", job.id);
    if (!shouldRetry) jobsSent += 1;
    notificationsSent += sent;
    errors.push(...jobErrors);
  }

  return json(200, {
    claimed: jobs.length,
    jobs_sent: jobsSent,
    notifications_sent: notificationsSent,
    errors: errors.slice(0, 10),
  });
});
