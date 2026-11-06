import test from "node:test";
import assert from "node:assert/strict";
import { MarketingOrchestrator } from "../src/orchestrator.mjs";
import { FalMediaProvider } from "../src/providers/fal.mjs";

test("the edit adapter sends the source video and preserves original audio", async () => {
  let request;
  const provider = new FalMediaProvider({ apiKey: "test", client: { config() {}, queue: {
    submit: async (model, options) => { request = { model, ...options }; return { request_id: "edit-1" }; },
  } } });
  const result = await provider.editTask({ videoUrl: "raw.mp4", prompt: "Fix the lighting" });
  assert.equal(result.id, "edit-1");
  assert.equal(request.input.video_url, "raw.mp4");
  assert.equal(request.input.audio_setting, "origin");
  assert.equal(request.input.duration, 0);
});

test("QA edits a near-acceptable human scene once, then regenerates on another failure", async () => {
  const scene = { scene_id: "hook", asset_type: "generated_video", duration_seconds: 4,
    source_duration_seconds: 4, action: "picks up a bag", purpose: "hook", character_ids: [], spoken_dialogue: "" };
  let content = { id: "v", content_type: "video", status: "generating", content_key: "test", decision: {
    content: { scenes: [scene], audio_mode: "mixed" }, generation: { reference_image_url: "reference.png", scenes: [{
      scene_id: "hook", asset_type: "generated_video", status: "generated", attempt: 1,
      asset_url: "raw.mp4", contact_sheet_url: "raw.jpg", technical: { duration_seconds: 4.04 }, history: [],
    }] },
  } };
  const calls = [];
  const orchestrator = new MarketingOrchestrator({
    config: { FAL_SCENE_EDIT_ENABLED: true, FAL_EDIT_MODEL: "fal-ai/wan/v2.7/edit-video",
      FAL_EDIT_USD_PER_SECOND: 0.15, FAL_VIDEO_USD_PER_SECOND: 0.2, FAL_SCENE_MAX_ATTEMPTS: 4 },
    repository: { contentById: async () => content, reserveCost: async (_provider, amount) => { calls.push(amount); return "r"; },
      settleCost: async () => {}, updateContent: async (_id, patch) => (content = { ...content, ...patch }) },
    brain: { sceneQualityReview: async () => ({ costUsd: 0, responseId: "qa", data: { accept: false,
      scores: { scene_match: 90, motion_continuity: 90, visual_quality: 70 }, required_fixes: ["Fix background flicker"], retry_prompt: "Correct the background" } }) },
    mediaProvider: { editTask: async (input) => { calls.push(input.videoUrl); return { id: "edit", model: "editor" }; },
      createTask: async () => { calls.push("regenerate"); return { id: "new", model: "generator" }; } },
  });
  const first = await orchestrator.refreshContent("v");
  let record = first.content.decision.generation.scenes[0];
  assert.equal(first.pending, true);
  assert.equal(record.operation, "edit");
  assert.equal(record.source_asset_url, "raw.mp4");
  assert.equal(record.edit_attempts, 1);
  assert.ok(calls.includes(0.75));
  assert.equal(record.history[0].asset_url, "raw.mp4");
  content.decision.generation.scenes[0] = { ...record, status: "generated", asset_url: "edited.mp4",
    contact_sheet_url: "edited.jpg", technical: { duration_seconds: 4.04 } };
  await orchestrator.refreshContent("v");
  record = content.decision.generation.scenes[0];
  assert.equal(record.attempt, 3);
  assert.equal(record.edit_attempts, 1);
  assert.equal(calls.filter((value) => value === "raw.mp4").length, 1);
  assert.ok(calls.includes("regenerate"));
});

test("app footage, missing action and incorrect speech never enter the editing API", async () => {
  const orchestrator = new MarketingOrchestrator({ config: { FAL_SCENE_EDIT_ENABLED: true },
    mediaProvider: { editTask: async () => { throw new Error("must not edit"); } } });
  const record = { asset_type: "generated_video", asset_url: "raw.mp4", technical: { duration_seconds: 4, dialogue_match: false } };
  const qa = { scores: { scene_match: 90 }, required_fixes: ["Change lighting"] };
  assert.equal(await orchestrator.queueSceneEdit({}, { spoken_dialogue: "Hi" }, record, qa, 80), null);
  assert.equal(await orchestrator.queueSceneEdit({}, {}, { ...record, asset_type: "app_capture" }, qa, 80), null);
  assert.equal(await orchestrator.queueSceneEdit({}, {}, record, { ...qa, scores: { scene_match: 40 } }, 80), null);
});
