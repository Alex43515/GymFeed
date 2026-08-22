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
  assert.equal(config.BYTEPLUS_SEEDANCE_MODEL, "dreamina-seedance-2-0-260128");
});

test("execution switches parse explicit true values", () => {
  const config = loadConfig(requiredEnv({ GENERATE_ASSETS: "true", AUTO_PUBLISH: "true" }));
  assert.equal(config.GENERATE_ASSETS, true);
  assert.equal(config.AUTO_PUBLISH, true);
});

test("blank optional provider keys are treated as unconfigured", () => {
  const config = loadConfig(requiredEnv({
    OPENAI_API_KEY: "",
    GEMINI_API_KEY: "  ",
    BYTEPLUS_API_KEY: "",
    BLOTATO_API_KEY: "",
  }));
  assert.equal(config.OPENAI_API_KEY, undefined);
  assert.equal(config.GEMINI_API_KEY, undefined);
  assert.equal(config.BYTEPLUS_API_KEY, undefined);
  assert.equal(config.BLOTATO_API_KEY, undefined);
});
