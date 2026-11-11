const FALLBACK_MODEL = "gpt-6-luna";

export type AiFeature =
  | "ai_coach"
  | "equipment_scan"
  | "body_scan"
  | "food_scan"
  | "starter_plan";

type ChatPayload = Record<string, unknown>;

function messageStartsWith(
  messages: unknown,
  role: string,
  prefix: string,
): boolean {
  if (!Array.isArray(messages)) return false;
  return messages.some((message) => {
    if (!message || message.role !== role) return false;
    const content = message.content;
    if (typeof content === "string") {
      return content.trimStart().startsWith(prefix);
    }
    return Array.isArray(content) &&
      content.some((part) =>
        part?.type === "text" && typeof part.text === "string" &&
        part.text.trimStart().startsWith(prefix)
      );
  });
}

// Installed builds send fixed model IDs. Pair those IDs with the app's own
// prompt signatures so other calls that happen to use the same model pass through.
export function legacyAiFeature(payload: ChatPayload): AiFeature | null {
  const { model, messages } = payload;
  const startsWith = (role: string, prefix: string) =>
    messageStartsWith(messages, role, prefix);
  if (model === "gpt-5-mini") {
    if (
      startsWith("system", "You are GymFeed AI Coach,") ||
      startsWith("system", "You are GymFeed's private workout-action compiler.")
    ) {
      return "ai_coach";
    }
  }
  if (model === "gpt-5.4-mini") {
    if (
      startsWith("user", "Identify the exact gym machine or exercise equipment")
    ) {
      return "equipment_scan";
    }
    if (
      startsWith(
        "user",
        "Check first that one full person is visible from head to feet.",
      )
    ) {
      return "body_scan";
    }
  }
  if (model === "gpt-4o-mini") {
    if (
      startsWith("user", "Analyze only the plated food visible in this image.")
    ) {
      return "food_scan";
    }
    if (
      startsWith(
        "system",
        "You create safe, practical four-week fitness plans for GymFeed.",
      ) ||
      startsWith(
        "system",
        "You create practical four-week nutrition plans for GymFeed.",
      )
    ) {
      return "starter_plan";
    }
  }
  return null;
}

export async function rewriteLegacyAiRequest(
  body: ArrayBuffer,
  lookup: (feature: AiFeature) => Promise<string | undefined>,
): Promise<ArrayBuffer | string> {
  let payload: ChatPayload;
  try {
    payload = JSON.parse(new TextDecoder().decode(body));
    if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
      return body;
    }
  } catch {
    return body;
  }

  const feature = legacyAiFeature(payload);
  if (!feature) return body;

  const model = (await lookup(feature)) ?? FALLBACK_MODEL;
  if (model === payload.model) return body;

  const isGpt6 = model.startsWith("gpt-6");
  const usesReasoning = /^(?:gpt-[56](?:[.-]|$)|o[134](?:-|$))/.test(model);
  const tokenLimit = payload.max_completion_tokens ?? payload.max_tokens;
  payload.model = model;
  delete payload.max_tokens;
  delete payload.max_completion_tokens;
  if (tokenLimit !== undefined) {
    payload[usesReasoning ? "max_completion_tokens" : "max_tokens"] =
      tokenLimit;
  }
  if (usesReasoning) {
    delete payload.temperature;
    delete payload.top_p;
    if (isGpt6 && payload.reasoning_effort === undefined) {
      payload.reasoning_effort = model.startsWith("gpt-6-luna")
        ? "none"
        : "low";
    }
  } else {
    delete payload.reasoning_effort;
  }
  return JSON.stringify(payload);
}

export async function fetchModelSetting(
  feature: AiFeature,
  authorization: string | null,
): Promise<string | undefined> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const apiKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!supabaseUrl || !apiKey || !authorization) return undefined;
  const url = new URL("/rest/v1/ai_model_settings", supabaseUrl);
  url.searchParams.set("feature", "eq." + feature);
  url.searchParams.set("select", "model");
  try {
    const response = await fetch(url, {
      headers: { apikey: apiKey, authorization },
      signal: AbortSignal.timeout(3000),
    });
    if (!response.ok) return undefined;
    const rows = await response.json();
    const model = rows?.[0]?.model;
    if (typeof model === "string" && model.length > 0) return model;
  } catch {
    // Older apps can still use Luna when the settings lookup is unavailable.
  }
}
