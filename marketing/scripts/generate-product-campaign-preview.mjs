import { mkdir, writeFile } from "node:fs/promises";
import { resolve } from "node:path";
import { renderProductSlide } from "../src/render-product-slide.mjs";
import { renderProductVideo } from "../src/render-product-video.mjs";
import { referenceScreenshotUrl } from "../src/product-brief.mjs";

const outputDirectory = resolve(process.argv[2] ?? "/tmp/gymfeed-product-campaign");
await mkdir(outputDirectory, { recursive: true });

const cta = "Open Coach";
const slides = [
  {
    feature: "scan_equipment",
    headline: "Not sure what that machine does?",
    body: "Open Coach. Take a photo. GymFeed helps identify the likely machine.",
    screenshotRef: "gymfeed-equipment-scan-input-reference.png",
  },
  {
    feature: "scan_equipment",
    headline: "Photo to likely machine.",
    body: "Review the AI-assisted identification before following any guidance.",
    screenshotRef: "gymfeed-equipment-scan-result-reference.png",
  },
  {
    feature: "scan_equipment",
    headline: "See muscles and safe-use steps.",
    body: "Use the result as guidance. Follow the machine and your gym when uncertain.",
    screenshotRef: "gymfeed-equipment-scan-result-reference.png",
  },
  {
    feature: "train",
    headline: "Plan the work in Train.",
    body: "Keep dated routines, sets, reps and kg in the same fitness journey.",
    screenshotRef: "gymfeed-train-schedule-reference.png",
  },
  {
    feature: "progress",
    headline: "Track the change.",
    body: "Connect workouts, meals, progress and community in one GymFeed.",
    screenshotRef: "gymfeed-progress-reference.png",
  },
];

for (let index = 0; index < slides.length; index += 1) {
  const slide = slides[index];
  const screenshotUrl = slide.screenshotRef ? await referenceScreenshotUrl(slide.screenshotRef) : null;
  const image = await renderProductSlide({
    ...slide,
    cta,
    index,
    total: slides.length,
    screenshotUrl,
  });
  await writeFile(resolve(outputDirectory, `carousel-${index + 1}.png`), image);
}

const videoPlan = {
  product_feature: "scan_equipment",
  feature_sequence: ["scan_equipment", "scan_equipment", "train", "progress"],
  hook: "This machine has confused everyone at least once.",
  product_promise: "Take a photo in GymFeed for AI-assisted equipment guidance.",
  proof_points: [
    "See the likely machine, target muscles and safe-use steps.",
    "Keep the next workout and your progress in the same connected app.",
  ],
  caption_text: [
    "This machine has confused everyone at least once.",
    "Photo to likely machine to safer setup guidance.",
    "Plan the work in Train.",
    "Open Coach in GymFeed.",
  ],
  screenshot_refs: [
    "gymfeed-equipment-scan-input-reference.png",
    "gymfeed-equipment-scan-result-reference.png",
    "gymfeed-train-schedule-reference.png",
    "gymfeed-progress-reference.png",
  ],
  cta,
};
const video = await renderProductVideo(videoPlan, { screenshotResolver: referenceScreenshotUrl });
await writeFile(resolve(outputDirectory, "gymfeed-product-video.mp4"), video);
await writeFile(resolve(outputDirectory, "campaign.json"), JSON.stringify({
  campaign: "Decode the machine, then do the work",
  status: "review_only_archive_ui_reference",
  landingUrl: "https://gymfeed.io",
  socialCopy: {
    instagram: "Not sure which machine you're looking at? GymFeed's AI-assisted equipment scan can suggest the likely machine, target muscles and safe-use steps. Treat the result as guidance, and follow the manufacturer and your gym when identification is uncertain. Open Coach at gymfeed.io. #GymFeed #GymTraining #FitnessApp",
    tiktok: "That machine you keep walking past? Take a photo in GymFeed for AI-assisted equipment guidance, then keep the workout and your progress connected. Results are guidance—follow the machine and gym instructions when uncertain. #GymFeed #GymTok",
    youtubeShorts: "Photograph a gym machine in GymFeed to see the likely equipment type, target muscles and safe-use steps. Then keep training and progress in one connected fitness app. Open Coach at gymfeed.io.",
  },
  carousel: slides,
  video: videoPlan,
}, null, 2));

console.log(JSON.stringify({ outputDirectory, files: [...slides.map((_slide, index) => `carousel-${index + 1}.png`), "gymfeed-product-video.mp4", "campaign.json"] }, null, 2));
