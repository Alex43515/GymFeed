import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2.112.3";
import { createDeleteAccountHandler } from "./handler.mjs";

const url = Deno.env.get("SUPABASE_URL")!;
const options = { auth: { persistSession: false, autoRefreshToken: false } };

Deno.serve(createDeleteAccountHandler({
  userClient: (authorization: string) => createClient(
    url,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { ...options, global: { headers: { Authorization: authorization } } },
  ),
  adminClient: () => createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, options),
  bunnyApiKey: Deno.env.get("BUNNY_STREAM_API_KEY"),
  bunnyLibraryId: Deno.env.get("BUNNY_STREAM_LIBRARY_ID") ?? "721103",
}));
