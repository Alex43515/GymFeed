import { mkdir, writeFile } from "node:fs/promises";
import { resolve } from "node:path";
import { FalMediaProvider } from "../src/providers/fal.mjs";

const provider = new FalMediaProvider({
  apiKey: process.env.FAL_KEY,
  imageModel: process.env.FAL_IMAGE_MODEL ?? "fal-ai/flux/schnell",
  imageWidth: Number(process.env.FAL_IMAGE_WIDTH ?? 1024),
  imageHeight: Number(process.env.FAL_IMAGE_HEIGHT ?? 1280),
  videoModel: process.env.FAL_VIDEO_MODEL ?? "bytedance/seedance-2.0/fast/text-to-video",
  videoResolution: process.env.FAL_VIDEO_RESOLUTION ?? "720p",
});

const image = await provider.generateBackground(
  "Premium editorial fitness photography for GymFeed: a fictional adult athlete performing a controlled dumbbell Romanian deadlift in a modern charcoal gym, correct neutral spine and safe form, electric blue rim lighting with subtle violet accents, energetic but realistic, high contrast, polished mobile social campaign aesthetic, generous dark negative space in the upper third",
);
const directory = resolve("artifacts");
await mkdir(directory, { recursive: true });
const output = resolve(directory, "fal-preview.png");
await writeFile(output, image.buffer);
console.log(JSON.stringify({ output, mimeType: image.mimeType, requestId: image.raw?.requestId ?? null }));
