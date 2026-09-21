import assert from "node:assert/strict";
import test from "node:test";
import { overallQaScore } from "../src/contracts.mjs";

test("overall QA score averages the review dimensions", () => {
  assert.equal(overallQaScore({ scores: {
    brand_fit: 90,
    visual_quality: 80,
    hook_quality: 85,
    factual_confidence: 95,
    platform_fit: 80,
    conversion_potential: 80,
  } }), 85);
});
