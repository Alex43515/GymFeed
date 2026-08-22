// RevenueCat webhook -> trusted subscription outcomes for marketing analytics.
//
// Deploy with JWT verification disabled because RevenueCat is not a Supabase
// user. Authenticity is enforced with the Authorization header configured in
// RevenueCat and stored as REVENUECAT_WEBHOOK_AUTH in Supabase secrets.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("MARKETING_SUPABASE_SECRET_KEY") ??
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const WEBHOOK_AUTH = Deno.env.get("REVENUECAT_WEBHOOK_AUTH");

type RevenueCatEvent = {
  id?: string;
  type?: string;
  app_user_id?: string;
  original_app_user_id?: string;
  aliases?: string[];
  product_id?: string;
  entitlement_ids?: string[];
  price?: number;
  price_in_purchased_currency?: number;
  currency?: string;
  store?: string;
  environment?: string;
  event_timestamp_ms?: number;
  purchased_at_ms?: number;
  expiration_at_ms?: number;
  cancel_reason?: string;
  is_family_share?: boolean;
};

const EVENT_NAMES: Record<string, string> = {
  INITIAL_PURCHASE: "subscription_started",
  RENEWAL: "subscription_renewed",
  PRODUCT_CHANGE: "subscription_changed",
  CANCELLATION: "subscription_cancelled",
  UNCANCELLATION: "subscription_uncancelled",
  EXPIRATION: "subscription_expired",
  BILLING_ISSUE: "subscription_billing_issue",
  SUBSCRIBER_ALIAS: "subscription_alias_changed",
  TRANSFER: "subscription_transferred",
  NON_RENEWING_PURCHASE: "one_time_purchase",
  SUBSCRIPTION_PAUSED: "subscription_paused",
  SUBSCRIPTION_EXTENDED: "subscription_extended",
  TEST: "subscription_webhook_test",
};

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

function isUuid(value: string | undefined): value is string {
  return !!value && /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

function expectedAuthorization(secret: string): string {
  return secret.toLowerCase().startsWith("bearer ") ? secret : `Bearer ${secret}`;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json(405, { error: "method not allowed" });
  if (!WEBHOOK_AUTH) return json(500, { error: "REVENUECAT_WEBHOOK_AUTH not configured" });
  if (req.headers.get("authorization") !== expectedAuthorization(WEBHOOK_AUTH)) {
    return json(401, { error: "unauthorized" });
  }

  let event: RevenueCatEvent;
  try {
    const payload = await req.json();
    event = payload?.event ?? payload;
  } catch (_) {
    return json(400, { error: "invalid json" });
  }

  if (!event.id || !event.type || !event.app_user_id) {
    return json(400, { error: "missing event id, type, or app user id" });
  }

  const eventName = EVENT_NAMES[event.type] ?? `subscription_${event.type.toLowerCase()}`;
  const candidateUserId = isUuid(event.app_user_id)
    ? event.app_user_id
    : [event.original_app_user_id, ...(event.aliases ?? [])].find(isUuid) ?? null;
  const occurredAt = event.event_timestamp_ms || event.purchased_at_ms
    ? new Date(event.event_timestamp_ms ?? event.purchased_at_ms!).toISOString()
    : new Date().toISOString();
  const value = event.price_in_purchased_currency ?? event.price ?? null;

  const admin = createClient(SUPABASE_URL, SERVICE_KEY);
  let userId: string | null = null;
  if (candidateUserId) {
    const { data: profile, error: profileError } = await admin
      .from("profiles")
      .select("id")
      .eq("id", candidateUserId)
      .maybeSingle();
    if (profileError) return json(500, { error: profileError.message });
    userId = profile?.id ?? null;
  }

  let attribution: { content_id: string | null; publication_id: string | null; attribution_key: string } | null = null;
  if (userId) {
    const { data } = await admin
      .from("marketing_attributions")
      .select("content_id,publication_id,attribution_key")
      .eq("user_id", userId)
      .maybeSingle();
    attribution = data;
  }

  const { error } = await admin.from("marketing_events").upsert({
    user_id: userId,
    content_id: attribution?.content_id ?? null,
    publication_id: attribution?.publication_id ?? null,
    attribution_key: attribution?.attribution_key ?? null,
    event_name: eventName,
    source: "revenuecat",
    value_usd: value,
    currency: event.currency ?? "USD",
    occurred_at: occurredAt,
    dedupe_key: `revenuecat:${event.id}`,
    properties: {
      revenuecat_event_id: event.id,
      revenuecat_event_type: event.type,
      app_user_id: event.app_user_id,
      original_app_user_id: event.original_app_user_id ?? null,
      product_id: event.product_id ?? null,
      entitlement_ids: event.entitlement_ids ?? [],
      store: event.store ?? null,
      environment: event.environment ?? null,
      expiration_at: event.expiration_at_ms
        ? new Date(event.expiration_at_ms).toISOString()
        : null,
      cancel_reason: event.cancel_reason ?? null,
      is_family_share: event.is_family_share ?? false,
    },
  }, { onConflict: "dedupe_key", ignoreDuplicates: true });

  if (error) return json(500, { error: error.message });
  return json(200, { ok: true, event: eventName, attributed: !!attribution });
});
