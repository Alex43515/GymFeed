// Public landing page for externally shared GymFeed posts.
// Deploy with JWT verification disabled: recipients are not required to have a
// Supabase session just to open a public post link.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const APP_SCHEME = "com.flutterflow.gymfeedofficial";
const ANDROID_PACKAGE = "com.flutterflow.gymfeedofficial";
const PUBLIC_SITE_URL = (Deno.env.get("PUBLIC_SITE_URL") || "https://gymfeed.io").replace(/\/$/, "");
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

const securityHeaders: Record<string, string> = {
  "content-type": "text/html; charset=utf-8",
  "cache-control": "public, max-age=60, stale-while-revalidate=300",
  "x-content-type-options": "nosniff",
  "referrer-policy": "no-referrer",
  "content-security-policy": "default-src 'none'; img-src https: data:; style-src 'unsafe-inline'; script-src 'unsafe-inline'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
};

function escapeHtml(value: unknown): string {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function page(status: number, body: string): Response {
  return new Response(body, { status, headers: securityHeaders });
}

function messagePage(title: string, message: string, status = 404): Response {
  return page(status, `<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><title>${escapeHtml(title)}</title><style>body{margin:0;background:#080808;color:#fff;font-family:system-ui,sans-serif;display:grid;min-height:100vh;place-items:center}.card{max-width:420px;padding:32px;text-align:center}h1{font-size:25px}p{color:#a8a8a8;line-height:1.5}</style></head><body><main class="card"><h1>${escapeHtml(title)}</h1><p>${escapeHtml(message)}</p></main></body></html>`);
}

Deno.serve(async (req: Request) => {
  if (req.method !== "GET" && req.method !== "HEAD") {
    return messagePage("Method not allowed", "Open this link in a browser.", 405);
  }

  const url = new URL(req.url);
  const pieces = url.pathname.split("/").filter(Boolean);
  const functionIndex = pieces.lastIndexOf("share-post");
  const id = (functionIndex >= 0 ? pieces[functionIndex + 1] : "") || url.searchParams.get("post") || "";
  if (!UUID.test(id)) return messagePage("Invalid GymFeed link", "This post link is not valid.", 400);

  const admin = createClient(SUPABASE_URL, SERVICE_KEY);
  const { data: post, error } = await admin
    .from("posts")
    .select("id, caption, food_post, food_title, legacy_photo_url, video_thumbnail")
    .eq("id", id)
    .eq("deleted", false)
    .maybeSingle();
  if (error) return messagePage("GymFeed is unavailable", "Please try this link again shortly.", 503);
  if (!post) return messagePage("Post unavailable", "This post may have been removed.");

  const title = (post.food_post ? post.food_title : post.caption)?.trim() || "GymFeed post";
  const description = post.caption?.trim() || "Open this post in GymFeed.";
  const image = post.video_thumbnail?.trim() || post.legacy_photo_url?.trim() || "";
  const encodedId = encodeURIComponent(id);
  const appUrl = `${APP_SCHEME}:/postDetails?post=${encodedId}`;
  const androidIntent = `intent:///postDetails?post=${encodedId}#Intent;scheme=${APP_SCHEME};package=${ANDROID_PACKAGE};end`;
  const canonical = `${PUBLIC_SITE_URL}/post/${encodedId}`;

  const html = `<!doctype html>
<html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${escapeHtml(title)} · GymFeed</title>
<link rel="canonical" href="${escapeHtml(canonical)}">
<meta property="og:type" content="article"><meta property="og:site_name" content="GymFeed">
<meta property="og:title" content="${escapeHtml(title)}"><meta property="og:description" content="${escapeHtml(description)}">
<meta property="og:url" content="${escapeHtml(canonical)}">
${image ? `<meta property="og:image" content="${escapeHtml(image)}">` : ""}
<style>body{margin:0;background:#080808;color:#fff;font-family:system-ui,sans-serif;display:grid;min-height:100vh;place-items:center}.card{width:min(420px,calc(100% - 40px));text-align:center}.logo{font-size:30px;font-weight:800}.logo span{color:#14e77c}.preview{margin:24px 0;padding:22px;background:#141414;border:1px solid #2b2b2b;border-radius:22px;text-align:left}.preview img{width:100%;max-height:360px;object-fit:cover;border-radius:15px;margin-bottom:16px}.preview h1{font-size:20px;margin:0}.preview p{color:#aaa;line-height:1.5}.open{display:block;background:#14e77c;color:#03170c;text-decoration:none;font-weight:800;padding:17px;border-radius:999px}.hint{font-size:13px;color:#777;margin-top:14px}</style>
</head><body><main class="card"><div class="logo">Gym<span>Feed</span></div><article class="preview">${image ? `<img src="${escapeHtml(image)}" alt="Post preview">` : ""}<h1>${escapeHtml(title)}</h1><p>${escapeHtml(description)}</p></article><a class="open" id="open" href="${escapeHtml(appUrl)}">Open in GymFeed</a><p class="hint">If the app does not open automatically, tap the button.</p></main>
<script>const app=${JSON.stringify(appUrl)};const intent=${JSON.stringify(androidIntent)};const target=/Android/i.test(navigator.userAgent)?intent:app;document.getElementById('open').href=target;setTimeout(()=>location.href=target,180);</script>
</body></html>`;
  return req.method === "HEAD" ? new Response(null, { status: 200, headers: securityHeaders }) : page(200, html);
});
