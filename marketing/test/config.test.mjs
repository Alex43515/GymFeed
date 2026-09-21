import test from "node:test";
import assert from "node:assert/strict";
import { loadConfig } from "../src/config.mjs";

function requiredEnv(overrides = {}) {
  return {
    MARKETING_INTERNAL_TOKEN: "i".repeat(32),
    MARKETING_APPROVAL_TOKEN: "a".repeat(32),
    SUPABASE_URL: "https://example.supabase.co",
    SUPABASE_SERVICE_ROLE_KEY: "s".repeat(32),
    ...overrides,
  };
}

test("safe execution switches default to false", () => {
  const config = loadConfig(requiredEnv());
  assert.equal(config.GENERATE_ASSETS, false);
  assert.equal(config.AUTO_PUBLISH, false);
  assert.equal(config.OPENAI_DAILY_MODEL, "gpt-5.6-terra");
  assert.equal(config.FAL_IMAGE_MODEL, "fal-ai/nano-banana-2");
  assert.equal(config.FAL_VIDEO_MODEL, "google/gemini-omni-flash/v1.1/text-to-video");
  assert.equal(config.FAL_REFERENCE_VIDEO_MODEL, "google/gemini-omni-flash/v1.1/reference-to-video");
  assert.equal(config.FAL_VIDEO_USD_PER_SECOND, 0.10);
  assert.equal(config.FAL_SCENE_MAX_ATTEMPTS, 2);
  assert.equal(config.FAL_SCENE_QA_THRESHOLD, 88);
  assert.equal(config.BUFFER_YOUTUBE_PRIVACY, "private");
  assert.equal(config.OPENAI_TTS_MODEL, "gpt-4o-mini-tts");
  assert.equal(config.OPENAI_TTS_VOICE, "coral");
  assert.equal(config.OPENAI_TRANSCRIBE_MODEL, "gpt-4o-mini-transcribe");
  assert.equal(config.OPENAI_ESTIMATED_TRANSCRIPTION_COST_USD, 0.01);
  assert.equal(config.GOOGLE_SHEETS_APPROVAL_ID, undefined);
  assert.equal(config.GOOGLE_SHEETS_APPROVAL_TAB, "Content Review");
});

test("execution switches parse explicit true values", () => {
  const config = loadConfig(requiredEnv({ GENERATE_ASSETS: "true", AUTO_PUBLISH: "true" }));
  assert.equal(config.GENERATE_ASSETS, true);
  assert.equal(config.AUTO_PUBLISH, true);
});

test("blank optional provider keys are treated as unconfigured", () => {
  const config = loadConfig(requiredEnv({
    OPENAI_API_KEY: "",
    FAL_KEY: "  ",
    BUFFER_API_KEY: "",
    GOOGLE_SHEETS_APPROVAL_ID: "",
    GOOGLE_SHEETS_CREDENTIALS: "  ",
  }));
  assert.equal(config.OPENAI_API_KEY, undefined);
  assert.equal(config.FAL_KEY, undefined);
  assert.equal(config.BUFFER_API_KEY, undefined);
  assert.equal(config.GOOGLE_SHEETS_APPROVAL_ID, undefined);
  assert.equal(config.GOOGLE_SHEETS_CREDENTIALS, undefined);
});
