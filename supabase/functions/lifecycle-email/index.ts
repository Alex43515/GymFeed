// Called every 5 minutes by the gymfeed-lifecycle-email cron job.
// Set RESEND_API_KEY (and optionally EMAIL_FROM, EMAIL_REPLY_TO) as function
// secrets to start sending. Without the key it only expires stale rows.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2.112.3";
import { createLifecycleEmailHandler } from "./handler.mjs";

const url = Deno.env.get("SUPABASE_URL")!;
const options = { auth: { persistSession: false, autoRefreshToken: false } };

Deno.serve(createLifecycleEmailHandler({
  adminClient: () => createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, options),
  resendApiKey: Deno.env.get("RESEND_API_KEY") ?? "",
  from: Deno.env.get("EMAIL_FROM") ?? "GymFeed <hello@gymfeed.io>",
  replyTo: Deno.env.get("EMAIL_REPLY_TO") ?? "",
}));
