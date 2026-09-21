import test from "node:test";
import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { mkdtemp, readFile, writeFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { normalizeRequestedCaptureRequirements, validateVideoProductionPlan } from "../src/brain.mjs";
import { productionTimeline, renderProductVideo, validateAppCaptureSource, validateRetainedCut } from "../src/render-product-video.mjs";

const execFileAsync = promisify(execFile);
const ffmpeg = process.env.FFMPEG_PATH || "ffmpeg";
const ffprobe = process.env.FFPROBE_PATH || "ffprobe";

function story() {
  const scene = (id, asset, purpose, duration, audio, text, extra = {}) => ({
    scene_id: id, asset_type: asset, purpose, duration_seconds: duration,
    source_duration_seconds: asset === "gymfeed_screen" ? 0 : 10,
    source_start_seconds: 0, screenshot_ref: asset === "gymfeed_screen" ? "train.png" : "", capture_ref: "",
    subject: "the same fictional adult trainee", action: "walks into the gym and glances at the phone",
    overlay_text: text, audio_strategy: audio, spoken_dialogue: audio === "native" ? text : "",
    voiceover_text: audio === "voiceover" ? text : "", ...extra,
  });
  return {
    production_version: 2, target_duration_seconds: 18, audio_mode: "mixed", captions_enabled: true,
    character_reference: { required: true }, creative_treatment: { visual_mode: "hybrid" },
    review_brief: { production_requirements: [] }, reviewer_instruction_map: [],
    scenes: [
      scene("arrival", "generated_video", "hook", 4, "voiceover", "Ready to train. What comes first?", { source_start_seconds: 1 }),
      scene("train", "app_capture", "product_proof", 6, "voiceover", "Open today's Train session and complete the first set.", { capture_ref: "train-complete", source_duration_seconds: 20, source_start_seconds: 4 }),
      scene("resolve", "generated_video", "payoff", 4, "native", "Now I know my next move."),
      scene("cta", "gymfeed_screen", "cta", 4, "voiceover", "Your next move, ready. Get started with GymFeed."),
    ],
  };
}

test("production director permits meaningful phone action and multiple connected shots", () => {
  const plan = story();
  assert.equal(validateVideoProductionPlan(plan, { appCaptures: [{ capture_ref: "train-complete" }] }), plan);
  assert.equal(plan.scenes[0].source_start_seconds, 1);
});

test("missing footage is an explicit reviewable production requirement, never a made-up verified capture", () => {
  const plan = story();
  assert.throws(() => validateVideoProductionPlan(plan, { appCaptures: [] }), /Unavailable verified app capture/);
  plan.scenes[1].capture_ref = "requested:train-complete";
  assert.throws(() => validateVideoProductionPlan(plan, { appCaptures: [] }), /production_requirements/);
  plan.review_brief.production_requirements.push("Record requested:train-complete showing the same dated routine and completed set.");
  assert.equal(validateVideoProductionPlan(plan, { appCaptures: [] }), plan);
});

test("requested capture references are normalized into review requirements", () => {
  const plan = story();
  plan.scenes[1].capture_ref = "requested:train-complete";
  const normalized = normalizeRequestedCaptureRequirements(plan);
  assert.notEqual(normalized, plan);
  assert.match(normalized.review_brief.production_requirements.at(-1), /requested:train-complete/);
  assert.equal(validateVideoProductionPlan(normalized, { appCaptures: [] }), normalized);
});

test("production checks reject silent product proof and cut ranges that lose action", () => {
  const plan = story();
  plan.scenes[1].audio_strategy = "silent";
  plan.scenes[1].voiceover_text = "";
  assert.throws(() => validateVideoProductionPlan(plan), /requires narration/);
  const overrun = story();
  overrun.scenes[0].source_start_seconds = 8;
  assert.throws(() => validateVideoProductionPlan(overrun), /covering the exact retained cut/);
});

test("timeline retains source cuts, product captions and narration per scene", () => {
  const plan = story();
  const timeline = productionTimeline(plan, [{ sceneId: "arrival", buffer: Buffer.from("first") }, { sceneId: "resolve", buffer: Buffer.from("last") }]);
  assert.equal(timeline[0].start, 1);
  assert.equal(timeline[1].type, "app_capture");
  assert.equal(timeline[1].start, 4);
  assert.equal(timeline[1].subtitle, plan.scenes[1].voiceover_text);
  assert.equal(timeline[3].showOverlay, true);
});

test("renderer requires an actual verified capture and checks the physical source duration", async () => {
  const scene = { sceneId: "train", captureRef: "train", start: 2, duration: 4 };
  assert.throws(() => validateAppCaptureSource(scene, { verified: true, path: "example.mp4", duration_seconds: 8 }), /recorded interactions/);
  const asset = { verified: true, buffer: Buffer.from("test"), duration_seconds: 8, recorded_interactions: ["Open routine"] };
  assert.equal(validateAppCaptureSource(scene, asset), asset);
  assert.throws(() => validateRetainedCut(scene, 5), /Source does not cover/);
  await assert.rejects(() => renderProductVideo({ scenes: [{ scene_id: "proof", asset_type: "app_capture", capture_ref: "missing", source_start_seconds: 0, duration_seconds: 2, overlay_text: "Open Train", audio_strategy: "silent" }] }), /resolver is not configured/);
});

test("rendered master preserves app interaction footage and audible narration after the hook", async (context) => {
  try { await execFileAsync(ffmpeg, ["-version"]); await execFileAsync(ffprobe, ["-version"]); }
  catch { context.skip("FFmpeg and FFprobe are required for the local video integration test"); return; }
  const directory = await mkdtemp(join(tmpdir(), "gymfeed-video-v2-test-"));
  try {
    const source = join(directory, "synthetic-source.mp4");
    const voice = join(directory, "synthetic-narration.wav");
    await execFileAsync(ffmpeg, ["-hide_banner", "-loglevel", "error", "-y", "-f", "lavfi", "-i", "testsrc2=size=360x640:rate=30:duration=4", "-f", "lavfi", "-i", "sine=frequency=440:duration=4", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-c:a", "aac", source]);
    await execFileAsync(ffmpeg, ["-hide_banner", "-loglevel", "error", "-y", "-f", "lavfi", "-i", "sine=frequency=880:duration=1.8", voice]);
    const clip = await readFile(source);
    const narration = await readFile(voice);
    const plan = {
      production_version: 2, audio_mode: "mixed", scenes: [
        { scene_id: "hook", asset_type: "generated_video", source_start_seconds: 1, duration_seconds: 2, overlay_text: "Know the next move.", audio_strategy: "native", spoken_dialogue: "Where do I start?" },
        { scene_id: "proof", asset_type: "app_capture", capture_ref: "synthetic-test-only", source_start_seconds: 1, duration_seconds: 2, overlay_text: "Open today's Train session.", audio_strategy: "voiceover", voiceover_text: "Your next set is ready." },
      ],
    };
    const video = await renderProductVideo(plan, {
      sceneVideoBuffers: [{ sceneId: "hook", buffer: clip }],
      sceneVoiceoverBuffers: [{ sceneId: "proof", buffer: narration }],
      appCaptureResolver: async () => ({ verified: true, buffer: clip, duration_seconds: 4, recorded_interactions: ["Synthetic fixture, not marketing proof"] }),
    });
    const output = join(directory, "master.mp4");
    await writeFile(output, video);
    const probe = await execFileAsync(ffprobe, ["-v", "error", "-show_entries", "format=duration:stream=codec_type,width,height", "-of", "json", output]);
    const metadata = JSON.parse(probe.stdout);
    assert.ok(Math.abs(Number(metadata.format.duration) - 4) < 0.15);
    assert.ok(metadata.streams.some((stream) => stream.codec_type === "audio"));
    const audio = await execFileAsync(ffmpeg, ["-hide_banner", "-i", output, "-ss", "2.2", "-t", "1", "-vn", "-af", "volumedetect", "-f", "null", "-"], { maxBuffer: 1024 * 1024 });
    const volume = /mean_volume: ([\d.-]+) dB/.exec(audio.stderr);
    assert.ok(volume && Number(volume[1]) > -35, `Product-proof narration went silent: ${audio.stderr}`);
    await assert.rejects(() => renderProductVideo({ ...plan, scenes: [{ ...plan.scenes[0], source_start_seconds: 3 }] }, { sceneVideoBuffers: [{ sceneId: "hook", buffer: clip }] }), /Source does not cover retained cut/);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});
