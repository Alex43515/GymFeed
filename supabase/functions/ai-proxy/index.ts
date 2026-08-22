// ai-proxy — server-side reverse proxy for OpenAI + Gemini.
//
// Why: today the OpenAI key (lib/backend/api_requests/api_calls.dart) and Gemini
// key (lib/backend/gemini/gemini.dart) are hardcoded in the client and ship in the
// app binary. This function holds the keys server-side; the client calls it with a
// Supabase JWT instead. verify_jwt is on, so only signed-in GymFeed users reach it.
//
// Routing:
//   POST /functions/v1/ai-proxy/openai/v1/chat/completions  -> api.openai.com/v1/chat/completions
//   POST /functions/v1/ai-proxy/gemini/v1beta/models/...     -> generativelanguage.googleapis.com/...
// The upstream path after the provider segment is preserved verbatim (query too),
// so it is a drop-in for the existing call sites — only the base URL + auth change.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const OPENAI_BASE = "https://api.openai.com";
const GEMINI_BASE = "https://generativelanguage.googleapis.com";

const OPENAI_KEY = Deno.env.get("OPENAI_API_KEY");
const GEMINI_KEY = Deno.env.get("GEMINI_API_KEY");

// Only these upstream path prefixes may be proxied. Keeps the key from being used
// as an open OpenAI/Gemini relay even by an authenticated user.
const OPENAI_ALLOW = [
  "/v1/chat/completions",
  "/v1/completions",
  "/v1/responses",
  "/v1/threads",     // Assistants v2: threads, messages, runs
  "/v1/assistants",
  "/v1/images/generations",
  "/v1/images/edits",
  "/v1/images/variations",
  "/v1/embeddings",
  "/v1/audio/speech",
  "/v1/audio/transcriptions",
  "/v1/audio/translations",
  "/v1/moderations",
];
const GEMINI_ALLOW = [
  "/v1beta/models",
  "/v1/models",
];

const CORS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, openai-beta",
  "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
};

function pathAllowed(prefixes: string[], path: string): boolean {
  return prefixes.some((p) => path === p || path.startsWith(p + "/"));
}

function json(status: number, obj: unknown): Response {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { ...CORS, "content-type": "application/json" },
  });
}

function passthrough(upstream: Response): Response {
  const headers = new Headers(CORS);
  const ct = upstream.headers.get("content-type");
  if (ct) headers.set("content-type", ct);
  // upstream.body is a stream, so SSE (stream:true) chat completions pass through.
  return new Response(upstream.body, { status: upstream.status, headers });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  const url = new URL(req.url);
  const trimmed = url.pathname
    .replace(/^\/functions\/v1\/ai-proxy/, "")
    .replace(/^\/ai-proxy/, "");
  const seg = trimmed.split("/").filter(Boolean); // ["openai","v1","chat","completions"]
  const provider = seg.shift();
  const upstreamPath = "/" + seg.join("/");

  const method = req.method;
  const body =
    method === "GET" || method === "HEAD" ? undefined : await req.arrayBuffer();

  try {
    if (provider === "openai") {
      if (!OPENAI_KEY) return json(500, { error: "OPENAI_API_KEY not configured" });
      if (!pathAllowed(OPENAI_ALLOW, upstreamPath)) {
        return json(403, { error: `path not allowed: ${upstreamPath}` });
      }
      const headers = new Headers();
      headers.set("Authorization", `Bearer ${OPENAI_KEY}`);
      const ct = req.headers.get("content-type");
      if (ct) headers.set("content-type", ct);
      const beta = req.headers.get("openai-beta");
      if (beta) headers.set("OpenAI-Beta", beta);
      const upstream = await fetch(OPENAI_BASE + upstreamPath + url.search, {
        method,
        headers,
        body,
      });
      return passthrough(upstream);
    }

    if (provider === "gemini") {
      if (!GEMINI_KEY) return json(500, { error: "GEMINI_API_KEY not configured" });
      if (!pathAllowed(GEMINI_ALLOW, upstreamPath)) {
        return json(403, { error: `path not allowed: ${upstreamPath}` });
      }
      const target = new URL(GEMINI_BASE + upstreamPath);
      for (const [k, v] of url.searchParams) {
        if (k !== "key") target.searchParams.set(k, v); // never trust a client key
      }
      const headers = new Headers();
      headers.set("x-goog-api-key", GEMINI_KEY);
      const ct = req.headers.get("content-type");
      if (ct) headers.set("content-type", ct);
      const upstream = await fetch(target.toString(), { method, headers, body });
      return passthrough(upstream);
    }

    return json(404, { error: "unknown provider; use /openai/* or /gemini/*" });
  } catch (e) {
    return json(502, { error: String(e) });
  }
});
