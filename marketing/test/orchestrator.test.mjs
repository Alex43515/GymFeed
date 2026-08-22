import test from "node:test";
import assert from "node:assert/strict";
import { MarketingOrchestrator } from "../src/orchestrator.mjs";

test("pipeline does nothing while generation is disabled", async () => {
  const orchestrator = new MarketingOrchestrator({ config: { GENERATE_ASSETS: false } });
  assert.deepEqual(await orchestrator.runPipeline(), {
    skipped: true,
    reason: "asset generation disabled",
    actions: [],
  });
});

test("daily run is idempotent when a run already exists", async () => {
  const existing = { id: "run-1", status: "succeeded" };
  const repository = {
    startRun: async () => ({ run: existing, reused: true }),
  };
  const orchestrator = new MarketingOrchestrator({ config: {}, repository });
  assert.deepEqual(await orchestrator.runDaily(new Date("2026-08-12T10:00:00Z")), { reused: true, run: existing });
});
