import test from "node:test";
import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { zodTextFormat } from "openai/helpers/zod";
import { VideoPlanSchema } from "../src/contracts.mjs";
import { MarketingBrain, responseCost, validateVideoProductionPlan } from "../src/brain.mjs";
import { MarketingOrchestrator, referenceImagePrompt, videoScenePrompt } from "../src/orchestrator.mjs";
import { sceneReferenceUrls, storyFingerprint, storyReviewPassed } from "../src/video-story.mjs";

const actor = (id) => ({ character_id: id, role: "gym friend", appearance: `${id} is a distinct fictional adult`, wardrobe: `${id} plain shirt`, voice_direction: `${id} warm relaxed English voice` });
function plan() {
  const scene = (id, speaker, purpose, extra = {}) => ({
    scene_id: id, asset_type: "generated_video", purpose, duration_seconds: 4, source_duration_seconds: 5,
    source_start_seconds: 0, character_ids: [speaker], speaker_id: speaker, spoken_dialogue: "Ready? Not quite yet.",
    audio_strategy: "native", voiceover_text: "", screenshot_ref: "", capture_ref: "", overlay_text: "A familiar gym moment", ...extra,
  });
  return { production_version: 3, target_duration_seconds: 20, audio_mode: "mixed", captions_enabled: true,
    narrative: { format: "dialogue_story", situation: "Two friends arrive at the gym", tension: "One friend cannot choose the first exercise", product_turn: "Their existing routine is ready in Train", payoff: "They stop deliberating and begin training", exception_reason: "" },
    cast: [actor("alex"), actor("sam")], character_reference: { required: true, environment_anchor: "unbranded gym" },
    creative_treatment: { visual_mode: "hybrid" }, review_brief: { production_requirements: [] },
    scenes: [scene("hook", "alex", "hook"), scene("reply", "sam", "problem"),
      scene("proof", "", "product_proof", { asset_type: "app_capture", character_ids: [], audio_strategy: "voiceover", spoken_dialogue: "", voiceover_text: "Open Train and start your routine.", capture_ref: "train" }),
      scene("payoff", "alex", "payoff"), scene("cta", "sam", "cta", { overlay_text: "Ready to begin. Get started with GymFeed." })] };
}
const pass = () => ({ accept: true, scores: { hook: 90, natural_dialogue: 90, product_causality: 90, payoff: 90, filmability: 90 }, required_fixes: [], summary: "Specific human story with a causal product turn." });

test("version 3 requires a real exchange and a human payoff, while legacy plans remain supported", () => {
  const p = plan();
  assert.equal(validateVideoProductionPlan(p), p);
  const bad = structuredClone(p);
  bad.scenes.forEach((scene) => { if (scene.audio_strategy === "native") { scene.voiceover_text = scene.spoken_dialogue; scene.spoken_dialogue = ""; scene.audio_strategy = "voiceover"; scene.speaker_id = ""; } });
  assert.throws(() => validateVideoProductionPlan(bad), /two distinct speakers/);
  const swapped = structuredClone(p); swapped.scenes[0].speaker_id = "sam";
  assert.throws(() => validateVideoProductionPlan(swapped), /visible speaker_id/);
  const duplicate = structuredClone(p); duplicate.cast[1].character_id = "alex";
  assert.throws(() => validateVideoProductionPlan(duplicate), /unique/);
});

test("cast reference routing matches prompt numbering and fails closed on a missing identity", () => {
  const p = plan(); const scene = { ...p.scenes[0], character_ids: ["sam", "alex"], speaker_id: "sam" };
  const content = { decision: { content: p } };
  assert.deepEqual(sceneReferenceUrls(p, scene, { alex: "a.png", sam: "s.png" }), ["s.png", "a.png"]);
  assert.throws(() => sceneReferenceUrls(p, scene, { alex: "a.png" }), /Missing locked reference for sam/);
  const prompt = videoScenePrompt(content, scene);
  assert.match(prompt, /<IMAGE_REF_0> = sam/); assert.match(prompt, /<IMAGE_REF_1> = alex/);
  assert.match(prompt, /ONLY SPEAKER: sam/);
  assert.match(referenceImagePrompt(content, p.cast[1]), /individual identity reference for sam/);
  assert.doesNotMatch(referenceImagePrompt(content, p.cast[1]), /alex is a distinct/);
});

test("story gate checks every score and fingerprints invalidate stale reviews", () => {
  assert.equal(storyReviewPassed(pass()), true);
  assert.equal(storyReviewPassed({ ...pass(), scores: { ...pass().scores, payoff: 84 } }), false);
  assert.equal(storyReviewPassed({ ...pass(), required_fixes: ["Fix the hook"] }), false);
  assert.equal(storyReviewPassed({ accept: true }), false);
  const p = plan(); const original = storyFingerprint(p); p.scenes[0].spoken_dialogue = "Different hook";
  assert.notEqual(storyFingerprint(p), original);
  assert.equal(zodTextFormat(VideoPlanSchema, "test").schema.properties.production_version.const, 3);
});

test("story rejection is stored and stops all paid image/video calls", async () => {
  let content = { id: "pilot", content_type: "video", decision: { content: plan() } };
  const orchestration = new MarketingOrchestrator({ config: {},
    repository: { reserveCost: async () => "r", settleCost: async () => {}, updateContent: async (_id, patch) => (content = { ...content, ...patch }) },
    brain: { storyQualityReview: async () => ({ data: { ...pass(), accept: false, required_fixes: ["hook: make the question specific"] }, costUsd: 0.01, responseId: "review" }) },
    mediaProvider: { generateReferenceImage: async () => assert.fail("must not generate"), createTask: async () => assert.fail("must not render") },
    appCaptureResolver: async () => ({ duration_seconds: 20 }),
  });
  await assert.rejects(() => orchestration.generateVideo(content), (error) => /Creative story QA failed.*hook/.test(error.message) && error.safeToRetry === true && error.storyQaFailed === true);
  assert.equal(content.status, "failed"); assert.equal(content.decision.story_review.accept, false);
});

test("successful story generates one reference per actor and routes the right image to each shot", async () => {
  let content = { id: "pilot", content_key: "pilot", content_type: "video", decision: { content: plan() } };
  const prompts = []; const tasks = [];
  const orchestration = new MarketingOrchestrator({ config: { FAL_VIDEO_USD_PER_SECOND: 0.1, FAL_ESTIMATED_IMAGE_COST_USD: 0.08 },
    repository: { reserveCost: async () => "r", settleCost: async () => {}, uploadAsset: async (path) => `https://example.com/${path}`, updateContent: async (_id, patch) => (content = { ...content, ...patch }) },
    brain: { storyQualityReview: async () => ({ data: pass(), costUsd: 0.01, responseId: "review" }) },
    mediaProvider: { generateReferenceImage: async (prompt) => { prompts.push(prompt); return { buffer: Buffer.from("image") }; }, createTask: async (input) => { tasks.push(input); return { id: `t${tasks.length}`, model: "gemini" }; } },
    appCaptureResolver: async () => ({ duration_seconds: 20 }),
  });
  assert.equal((await orchestration.generateVideo(content)).pending, true);
  assert.equal(prompts.length, 2); assert.equal(tasks.length, 4);
  assert.match(tasks[0].referenceImageUrls[0], /character-reference-alex.png$/);
  assert.match(tasks[1].referenceImageUrls[0], /character-reference-sam.png$/);
  assert.match(tasks[2].referenceImageUrls[0], /character-reference-alex.png$/);
  assert.equal(Object.keys(content.decision.generation.character_reference_urls).length, 2);
});

test("a saved low story score can generate a review-only preview after bounded repair", async () => {
  const p = plan();
  const fingerprint = storyFingerprint(p);
  const badReview = { ...pass(), accept: false, required_fixes: ["Clarify whose routine is shown"], fingerprint };
  let content = { id: "pilot", content_key: "pilot", content_type: "video", decision: { content: p, story_review: badReview, workflow: { story_preview_authorized_fingerprint: fingerprint } } };
  let tasks = 0;
  const orchestration = new MarketingOrchestrator({ config: { FAL_VIDEO_USD_PER_SECOND: 0.1, FAL_ESTIMATED_IMAGE_COST_USD: 0.08 },
    repository: { reserveCost: async () => "r", settleCost: async () => {}, uploadAsset: async (path) => `https://example.com/${path}`, updateContent: async (_id, patch) => (content = { ...content, ...patch }) },
    brain: { storyQualityReview: async () => assert.fail("saved story review should be reused") },
    mediaProvider: { generateReferenceImage: async () => ({ buffer: Buffer.from("image") }), createTask: async () => ({ id: `t${++tasks}`, model: "gemini" }) },
    appCaptureResolver: async () => ({ duration_seconds: 20 }),
  });
  assert.equal((await orchestration.generateVideo(content)).pending, true);
  assert.equal(tasks, 4);
  assert.equal(content.decision.story_review.accept, false);
});

test("budget-limited story review is recorded before generation and does not spend on media yet", async () => {
  let content = { id: "pilot", content_type: "video", decision: { content: plan() } };
  const orchestration = new MarketingOrchestrator({ config: {},
    repository: { reserveCost: async () => { throw new Error("openai provider budget exceeded"); }, updateContent: async (_id, patch) => (content = { ...content, ...patch }) },
    brain: { storyQualityReview: async () => assert.fail("budget must prevent call") },
    mediaProvider: { generateReferenceImage: async () => assert.fail("story preview requires authorization first") },
    appCaptureResolver: async () => ({ duration_seconds: 20 }),
  });
  await assert.rejects(() => orchestration.generateVideo(content), /Creative story QA failed/);
  assert.equal(content.decision.story_review.review_status, "budget_blocked");
  assert.equal(content.decision.story_review.fingerprint, storyFingerprint(content.decision.content));
});

test("budget-limited narration is replaced with an explicitly marked silent preview track", async (t) => {
  try { await promisify(execFile)(process.env.FFMPEG_PATH || "ffmpeg", ["-version"]); }
  catch { t.skip("ffmpeg unavailable"); return; }
  const orchestration = new MarketingOrchestrator({ config: {}, repository: { reserveCost: async () => { throw new Error("openai provider budget exceeded"); } }, voiceProvider: { generate: async () => assert.fail("budget must prevent TTS") } });
  const buffers = await orchestration.sceneAudio({ id: "v", decision: { content: { scenes: [{ scene_id: "proof", audio_strategy: "voiceover", voiceover_text: "The workout opens.", duration_seconds: 1.5 }] } } });
  assert.equal(buffers.length, 1);
  assert.equal(buffers[0].missingNarration, true);
  assert.ok(Buffer.isBuffer(buffers[0].buffer) && buffers[0].buffer.length > 100);
});

test("Astra usage is billed at Astra rates even when the default creative model remains Sol", () => {
  const cost = responseCost({ model: "gpt-6-astra", usage: { input_tokens: 1000, output_tokens: 1000 }, output: [] }, { OPENAI_WEEKLY_MODEL: "gpt-6-sol", OPENAI_WEB_SEARCH_USD_PER_CALL: 0.01 });
  assert.equal(cost, 0.06);
});

test("pilot is a single explicitly selected model call without research or campaign planning", async () => {
  const calls = [];
  const brain = new MarketingBrain({ OPENAI_CREATIVE_MODEL: "gpt-6-sol", OPENAI_WEB_SEARCH_USD_PER_CALL: 0.01 }, { responses: { parse: async (input) => { calls.push(input); return { id: "one", model: "gpt-6-astra", output_parsed: null, usage: { input_tokens: 1000, output_tokens: 10 } }; } } });
  await assert.rejects(() => brain.draftVideo("one story", { model: "gpt-6-astra" }), (error) => error.openaiCostUsd === 0.0105);
  assert.equal(calls.length, 1); assert.equal(calls[0].model, "gpt-6-astra"); assert.equal(calls[0].tools, undefined);
});
