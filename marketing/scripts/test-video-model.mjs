import { writeFile } from "node:fs/promises";
import { loadConfig } from "../src/config.mjs";
import { MarketingRepository } from "../src/repository.mjs";
import { FalMediaProvider } from "../src/providers/fal.mjs";
import { extractVideoContactSheet } from "../src/extract-video-frame.mjs";

const config = loadConfig();
const repository = new MarketingRepository(config);
const provider = new FalMediaProvider({ apiKey: config.FAL_KEY, videoModel: config.FAL_VIDEO_MODEL,
  referenceVideoModel: config.FAL_REFERENCE_VIDEO_MODEL, videoResolution: config.FAL_VIDEO_RESOLUTION });
const reservation = await repository.reserveCost("fal", 0.8, { metadata: { operation: "wan3-integration-pilot" } });
let task;
try {
  task = await provider.createTask({ durationSeconds: 4, generateAudio: true,
    prompt: 'One continuous vertical handheld medium shot of a fictional adult woman aged 28 in plain gym clothing at home. She picks up a plain gym bag, smiles at camera and says clearly in English: "My workout starts with a plan." Natural daylight, realistic anatomy, candid performance, lip-synced native speech and quiet room ambience. No text, no logos, no music, no screens.' });
} catch (error) {
  await repository.releaseCost(reservation);
  throw error;
}
console.log(JSON.stringify({ taskId: task.id, model: task.model }));
for (let i = 0; i < 120; i++) {
  await new Promise((resolve) => setTimeout(resolve, 5000));
  const result = await provider.getTask(task.id, task.model);
  if (result.status === "failed") throw new Error(result.message);
  if (result.status !== "succeeded") continue;
  await repository.settleCost(reservation, 0.8, task.id);
  const response = await fetch(result.output.video_url);
  if (!response.ok) throw new Error(`Pilot download failed: ${response.status}`);
  const buffer = Buffer.from(await response.arrayBuffer());
  await writeFile("/results/wan3-pilot.mp4", buffer);
  await writeFile("/results/wan3-pilot.jpg", await extractVideoContactSheet(buffer, 4, 9));
  console.log(JSON.stringify({ status: "succeeded", bytes: buffer.length, video: "/results/wan3-pilot.mp4" }));
  process.exit(0);
}
throw new Error(`Pilot still pending: ${task.id}; reservation retained for reconciliation`);
