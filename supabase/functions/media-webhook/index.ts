// media-webhook — reacts to Bunny Stream encoding callbacks and flips media_assets.
//
// verify_jwt is OFF: Bunny can't present a Supabase JWT. Authenticity is instead
// guaranteed two ways:
//   1. Optional shared secret in the webhook URL (?secret=…), checked if the
//      BUNNY_WEBHOOK_SECRET env var is set.
//   2. We never trust the payload's Status — we re-fetch the authoritative video
//      object from Bunny and map ITS status. A spoofed "finished" POST can't
//      publish anything, and the re-fetch also yields the metadata we need.
//
// Bunny video-object status: 4=Finished, 5=Error, 6=UploadFailed, 2/3=processing.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const LIBRARY_ID = Deno.env.get("BUNNY_STREAM_LIBRARY_ID") ?? "721103";
const CDN_HOST = Deno.env.get("BUNNY_STREAM_CDN_HOST") ?? "vz-55fc89c2-aab.b-cdn.net";
const BUNNY_API_KEY = Deno.env.get("BUNNY_STREAM_API_KEY");
const WEBHOOK_SECRET = Deno.env.get("BUNNY_WEBHOOK_SECRET"); // optional
const BUNNY_API = "https://video.bunnycdn.com";

function json(status: number, obj: unknown): Response {
  return new Response(JSON.stringify(obj), { status, headers: { "content-type": "application/json" } });
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json(405, { error: "method not allowed" });
  if (!BUNNY_API_KEY) return json(500, { error: "BUNNY_STREAM_API_KEY not configured" });

  // Optional shared-secret gate.
  if (WEBHOOK_SECRET) {
    const provided = new URL(req.url).searchParams.get("secret");
    if (provided !== WEBHOOK_SECRET) return json(401, { error: "bad secret" });
  }

  let payload: { VideoGuid?: string; VideoLibraryId?: number; Status?: number };
  try {
    payload = await req.json();
  } catch (_) {
    return json(400, { error: "invalid json" });
  }
  const guid = payload.VideoGuid;
  if (!guid) return json(400, { error: "missing VideoGuid" });

  // Re-fetch the authoritative video object (source of truth, not the payload).
  const vres = await fetch(`${BUNNY_API}/library/${LIBRARY_ID}/videos/${guid}`, {
    headers: { AccessKey: BUNNY_API_KEY, accept: "application/json" },
  });
  if (!vres.ok) {
    // 200 so Bunny doesn't hammer retries; a pg_cron reconciler will re-check later.
    return json(200, { ok: false, note: `bunny lookup ${vres.status}` });
  }
  const v = await vres.json();

  const admin = createClient(SUPABASE_URL, SERVICE_KEY);
  let status: string | null = null;
  let extra: Record<string, unknown> = {};

  switch (v.status) {
    case 4: // Finished — fully available.
      status = "ready";
      // TODO(moderation): gate ready vs 'quarantined' via Gemini vision here (Phase 4).
      extra = {
        width: v.width ?? null,
        height: v.height ?? null,
        duration_seconds: v.length ?? null,
        bytes: v.storageSize ?? null,
        thumbnail_url: `https://${CDN_HOST}/${guid}/${v.thumbnailFileName ?? "thumbnail.jpg"}`,
        preview_url: `https://${CDN_HOST}/${guid}/preview.webp`,
      };
      break;
    case 5: // Error
    case 6: // UploadFailed
      status = "failed";
      break;
    case 2: // Processing
    case 3: // Transcoding
      status = "processing";
      break;
    default:
      status = null; // Created/Uploaded — nothing to do yet.
  }

  if (status) {
    const { error } = await admin
      .from("media_assets")
      .update({ status, ...extra })
      .eq("bunny_video_guid", guid);
    if (error) return json(500, { error: error.message });
  }

  return json(200, { ok: true, guid, status });
});
