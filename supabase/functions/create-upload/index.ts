// create-upload — issues a presigned Bunny Stream TUS upload ticket.
//
// The client never sees the Bunny API key. Flow:
//   1. Authenticate the caller (Supabase JWT — verify_jwt is on).
//   2. Enforce a per-user daily video quota (cost lever).
//   3. Create the Bunny video object (server-side, with the API key).
//   4. Write a media_assets row (status=pending).
//   5. Return a one-hour presigned TUS signature the client uploads with directly.
//
// Signature spec (Bunny): SHA256(libraryId + apiKey + expire + videoId), hex.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Non-secret config (library id is sent by clients during upload; cdn host is public).
const LIBRARY_ID = Deno.env.get("BUNNY_STREAM_LIBRARY_ID") ?? "721103";
const CDN_HOST = Deno.env.get("BUNNY_STREAM_CDN_HOST") ?? "vz-55fc89c2-aab.b-cdn.net";
const BUNNY_API_KEY = Deno.env.get("BUNNY_STREAM_API_KEY"); // secret

const DAILY_VIDEO_LIMIT = Number(Deno.env.get("DAILY_VIDEO_LIMIT") ?? "50");
const TUS_ENDPOINT = "https://video.bunnycdn.com/tusupload";
const BUNNY_API = "https://video.bunnycdn.com";

const CORS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(status: number, obj: unknown): Response {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { ...CORS, "content-type": "application/json" },
  });
}

async function sha256Hex(input: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(input));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json(405, { error: "method not allowed" });
  if (!BUNNY_API_KEY) return json(500, { error: "BUNNY_STREAM_API_KEY not configured" });

  // 1. Who is calling?
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error: userErr } = await userClient.auth.getUser();
  if (userErr || !user) return json(401, { error: "not authenticated" });

  const admin = createClient(SUPABASE_URL, SERVICE_KEY);

  // 2. Daily quota — caps how fast one account can grow storage.
  const dayStart = new Date();
  dayStart.setUTCHours(0, 0, 0, 0);
  const { count, error: countErr } = await admin
    .from("media_assets")
    .select("id", { count: "exact", head: true })
    .eq("owner_id", user.id)
    .eq("kind", "video")
    .gte("created_at", dayStart.toISOString());
  if (countErr) return json(500, { error: `quota check failed: ${countErr.message}` });
  if ((count ?? 0) >= DAILY_VIDEO_LIMIT) {
    return json(429, { error: "daily upload limit reached", limit: DAILY_VIDEO_LIMIT });
  }

  // 3. Create the Bunny video object.
  let title = "GymFeed upload";
  try {
    const parsed = await req.json();
    if (parsed && typeof parsed.title === "string" && parsed.title.trim()) {
      title = parsed.title.trim().slice(0, 200);
    }
  } catch (_) { /* empty body is fine */ }

  const createRes = await fetch(`${BUNNY_API}/library/${LIBRARY_ID}/videos`, {
    method: "POST",
    headers: { AccessKey: BUNNY_API_KEY, "content-type": "application/json", accept: "application/json" },
    body: JSON.stringify({ title }),
  });
  if (!createRes.ok) {
    return json(502, { error: `bunny create failed: ${createRes.status} ${await createRes.text()}` });
  }
  const video = await createRes.json();
  const guid: string = video.guid;
  const playbackUrl = `https://${CDN_HOST}/${guid}/playlist.m3u8`;

  // 4. Track the asset.
  const { data: asset, error: insErr } = await admin
    .from("media_assets")
    .insert({
      owner_id: user.id,
      kind: "video",
      provider: "bunny_stream",
      bunny_video_guid: guid,
      playback_url: playbackUrl,
      status: "pending",
    })
    .select("id")
    .single();
  if (insErr) return json(500, { error: `asset insert failed: ${insErr.message}` });

  // 5. Presign the TUS ticket (valid 1h).
  const expire = Math.floor(Date.now() / 1000) + 3600;
  const signature = await sha256Hex(`${LIBRARY_ID}${BUNNY_API_KEY}${expire}${guid}`);

  return json(200, {
    assetId: asset.id,
    videoId: guid,
    libraryId: LIBRARY_ID,
    tusEndpoint: TUS_ENDPOINT,
    authorizationSignature: signature,
    authorizationExpire: expire,
    cdnHost: CDN_HOST,
    playlistUrl: playbackUrl,
    thumbnailUrl: `https://${CDN_HOST}/${guid}/thumbnail.jpg`,
  });
});
