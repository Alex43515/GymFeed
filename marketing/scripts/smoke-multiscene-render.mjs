import { execFile } from "node:child_process";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import { extractVideoContactSheet, inspectVideo } from "../src/extract-video-frame.mjs";
import { renderProductVideo } from "../src/render-product-video.mjs";

const execFileAsync = promisify(execFile);
const directory = await mkdtemp(join(tmpdir(), "gymfeed-multiscene-smoke-"));
try {
  const source = join(directory, "source.mp4");
  await execFileAsync(process.env.FFMPEG_PATH || "ffmpeg", [
    "-hide_banner", "-loglevel", "error", "-y",
    "-f", "lavfi", "-i", "color=c=0x161616:s=360x640:d=4:r=30",
    "-c:v", "libx264", "-pix_fmt", "yuv420p", source,
  ]);
  const clip = await readFile(source);
  const scenes = ["hook", "action", "payoff"].map((sceneId, index) => ({
    scene_id: sceneId,
    asset_type: "generated_video",
    purpose: index === 0 ? "hook" : index === 1 ? "action" : "payoff",
    duration_seconds: 4,
    overlay_text: ["Your plan.", "Your progress.", "One GymFeed."][index],
  }));
  const plan = {
    hook: "Your fitness life, connected.",
    product_promise: "Plan, train, and track in GymFeed.",
    proof_points: ["Plan workouts", "Track progress", "Stay connected"],
    feature_sequence: ["train", "progress", "connected_ecosystem"],
    product_feature: "connected_ecosystem",
    target_duration_seconds: 12,
    scenes,
    caption_text: [],
    cta: "Get started with GymFeed",
    audio_mode: "silent",
  };
  const rendered = await renderProductVideo(plan, {
    sceneVideoBuffers: scenes.map((scene) => ({ sceneId: scene.scene_id, buffer: clip })),
  });
  const technical = await inspectVideo(rendered);
  const contactSheet = await extractVideoContactSheet(rendered, 12, 16);
  if (technical.width !== 1080 || technical.height !== 1920) throw new Error(`Unexpected dimensions ${technical.width}x${technical.height}`);
  if (technical.duration_seconds < 11.5 || technical.duration_seconds > 12.5) throw new Error(`Unexpected duration ${technical.duration_seconds}`);
  if (contactSheet.length < 10_000) throw new Error("Contact sheet was not rendered");
  console.log(JSON.stringify({ ok: true, video_bytes: rendered.length, contact_sheet_bytes: contactSheet.length, technical }));
} finally {
  await rm(directory, { recursive: true, force: true });
}
