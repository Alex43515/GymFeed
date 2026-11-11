import assert from "node:assert/strict";
import { rewriteLegacyAiRequest } from "./model_settings.ts";

function body(value: unknown) {
  return new TextEncoder().encode(JSON.stringify(value)).buffer;
}

const cases = [
  [
    "ai_coach",
    "gpt-5-mini",
    "system",
    "You are GymFeed AI Coach, a personalized fitness and nutrition coach.",
    "low",
  ],
  [
    "equipment_scan",
    "gpt-5.4-mini",
    "user",
    "Identify the exact gym machine or exercise equipment visible in the image.",
    "medium",
  ],
  [
    "body_scan",
    "gpt-5.4-mini",
    "user",
    "Check first that one full person is visible from head to feet.",
    "medium",
  ],
  [
    "food_scan",
    "gpt-4o-mini",
    "user",
    "Analyze only the plated food visible in this image.",
    undefined,
  ],
  [
    "starter_plan",
    "gpt-4o-mini",
    "system",
    "You create safe, practical four-week fitness plans for GymFeed.",
    undefined,
  ],
  [
    "starter_plan",
    "gpt-4o-mini",
    "system",
    "You create practical four-week nutrition plans for GymFeed.",
    undefined,
  ],
] as const;

for (const [feature, model, role, text, effort] of cases) {
  Deno.test("routes legacy " + feature + " from " + text, async () => {
    const request = {
      model,
      messages: [{
        role,
        content: role === "user" ? [{ type: "text", text }] : text,
      }],
      ...(effort
        ? { max_completion_tokens: 1800, reasoning_effort: effort }
        : { max_tokens: 1800, temperature: 0.1 }),
      response_format: { type: "json_object" },
      store: false,
    };
    const output = await rewriteLegacyAiRequest(body(request), async (key) => {
      assert.equal(key, feature);
      return "gpt-6-luna";
    });
    assert.equal(typeof output, "string");
    const result = JSON.parse(output as string);
    assert.equal(result.model, "gpt-6-luna");
    assert.equal(result.max_completion_tokens, 1800);
    assert.equal(result.reasoning_effort, effort ?? "none");
    assert.equal(result.max_tokens, undefined);
    assert.equal(result.temperature, undefined);
    assert.equal(result.store, false);
    assert.deepEqual(result.messages, request.messages);
    assert.deepEqual(result.response_format, request.response_format);
  });
}

Deno.test("applies later setting changes, including a non-reasoning model", async () => {
  const request = body({
    model: "gpt-5.4-mini",
    messages: [{
      role: "user",
      content: "Identify the exact gym machine or exercise equipment",
    }],
    reasoning_effort: "medium",
    max_completion_tokens: 1800,
  });
  const result = await rewriteLegacyAiRequest(
    request,
    async () => "gpt-4o-mini",
  );
  assert.deepEqual(JSON.parse(result as string), {
    model: "gpt-4o-mini",
    messages: [{
      role: "user",
      content: "Identify the exact gym machine or exercise equipment",
    }],
    max_tokens: 1800,
  });
  const missing = await rewriteLegacyAiRequest(request, async () => undefined);
  assert.equal(JSON.parse(missing as string).model, "gpt-6-luna");
});

Deno.test("passes through unrelated requests and requests already using Luna", async () => {
  for (
    const request of [
      {
        model: "gpt-4o-mini",
        messages: [{ role: "user", content: "A separate AI feature" }],
      },
      {
        model: "gpt-6-luna",
        messages: [{
          role: "user",
          content: "Analyze only the plated food visible in this image.",
        }],
      },
    ]
  ) {
    const encoded = body(request);
    assert.strictEqual(
      await rewriteLegacyAiRequest(encoded, async () => {
        throw new Error("Unexpected lookup");
      }),
      encoded,
    );
  }
});
