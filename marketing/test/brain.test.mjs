import test from "node:test";
import assert from "node:assert/strict";
import { responseCost } from "../src/brain.mjs";

test("response cost includes model tokens and web searches", () => {
  const response = {
    usage: { input_tokens: 1_000_000, output_tokens: 100_000 },
    output: [{ type: "web_search_call" }, { type: "message" }, { type: "web_search_call" }],
  };
  const config = {
    OPENAI_WEEKLY_MODEL: "gpt-5.6-sol",
    OPENAI_INPUT_USD_PER_MILLION: 2,
    OPENAI_OUTPUT_USD_PER_MILLION: 12,
    OPENAI_WEEKLY_INPUT_USD_PER_MILLION: 5,
    OPENAI_WEEKLY_OUTPUT_USD_PER_MILLION: 30,
    OPENAI_WEB_SEARCH_USD_PER_CALL: 0.01,
  };
  assert.equal(responseCost(response, config), 3.22);
});

test("response cost uses Sol rates for the weekly model", () => {
  const response = {
    model: "gpt-5.6-sol",
    usage: { input_tokens: 1_000_000, output_tokens: 100_000 },
    output: [],
  };
  const config = {
    OPENAI_WEEKLY_MODEL: "gpt-5.6-sol",
    OPENAI_INPUT_USD_PER_MILLION: 2.5,
    OPENAI_OUTPUT_USD_PER_MILLION: 15,
    OPENAI_WEEKLY_INPUT_USD_PER_MILLION: 5,
    OPENAI_WEEKLY_OUTPUT_USD_PER_MILLION: 30,
    OPENAI_WEB_SEARCH_USD_PER_CALL: 0.01,
  };
  assert.equal(responseCost(response, config), 8);
});
