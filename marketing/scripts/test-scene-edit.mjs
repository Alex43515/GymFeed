import { readFile, writeFile } from "node:fs/promises";
import { loadConfig } from "../src/config.mjs";
import { MarketingRepository } from "../src/repository.mjs";
import { FalMediaProvider } from "../src/providers/fal.mjs";
import { inspectVideo, extractVideoContactSheet } from "../src/extract-video-frame.mjs";

const config = loadConfig();
const repository = new MarketingRepository(config);
const provider = new FalMediaProvider({ apiKey: config.FAL_KEY });
const source = await readFile("/results/wan3-pilot.mp4");
const info = await inspectVideo(source);
if (info.duration_seconds < 2 || info.duration_seconds > 10) throw new Error("Pilot outside editor input limits");
const sourceUrl = await repository.uploadAsset(`model-pilots/${Date.now()}/edit-source.mp4`, source, "video/mp4");
const estimate = Math.ceil(info.duration_seconds) * config.FAL_EDIT_USD_PER_SECOND;
const reservation = await repository.reserveCost("fal", estimate, { metadata: { operation: "scene-edit-integration-pilot" } });
let task;
try {
  task = await provider.editTask({ model: config.FAL_EDIT_MODEL, videoUrl: sourceUrl,
    prompt: "Change only the curtains in the background to dark charcoal gray. Preserve the woman, her face, clothing, gym bag, movements, camera, timing and original audio exactly. No captions, no logos, no new objects." });
} catch (error) { await repository.releaseCost(reservation); throw error; }
console.log(JSON.stringify({ taskId: task.id, model: task.model, reservedUsd: estimate }));
for (let i = 0; i < 120; i++) {
  await new Promise((resolve) => setTimeout(resolve, 5000));
  const result = await provider.getTask(task.id, task.model);
if (result.status === "failed") {
    if (result.error?.status === 422) await repository.releaseCost(reservation);
    throw new Error(result.message);
  }
  if (result.status !== "succeeded") continue;
  const response = await fetch(result.output.video_url);
  if (!response.ok) throw new Error(`Editing pilot download failed: ${response.status}`);
  const buffer = Buffer.from(await response.arrayBuffer());
  const edited = await inspectVideo(buffer);
  await repository.settleCost(reservation, edited.duration_seconds * config.FAL_EDIT_USD_PER_SECOND, task.id);
  await writeFile("/results/wan-edited-pilot.mp4", buffer);
  await writeFile("/results/wan-edited-pilot.jpg", await extractVideoContactSheet(buffer, edited.duration_seconds, 9));
  if (info.has_audio && !edited.has_audio) throw new Error("Edited pilot lost original audio");
  console.log(JSON.stringify({ status: "succeeded", source: info, edited }));
  process.exit(0);
}
throw new Error(`Editing pilot still pending: ${task.id}; reservation retained for reconciliation`);
