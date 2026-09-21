import { randomUUID } from "node:crypto";
import { loadConfig } from "../src/config.mjs";
import { MarketingRepository } from "../src/repository.mjs";

const VIDEO_KEY = "GF-20260828-V001";
const CAROUSEL_KEY = "GF-20260828-I001";

const config = loadConfig(process.env);
const repository = new MarketingRepository(config);

const videoResult = await repository.client.from("marketing_content").select("*").eq("content_key", VIDEO_KEY).single();
if (videoResult.error) throw new Error(`Load video: ${videoResult.error.message}`);
const video = videoResult.data;
const content = {
  ...video.decision.content,
  topic: "The small decision that gets a workout started",
  concept: "An eight-second candid micro-story outside a gym: a tired adult pauses after work, takes a breath, reaches for a plain gym bag, opens the door, and starts walking toward the entrance. The on-video hook connects that small next step to building a repeatable plan.",
  hook: "Make the next step small.",
  scenes: [{
    duration_seconds: 8,
    camera: "Handheld vertical close-up from the passenger side, with a natural platform-native feel.",
    subject: "A fictional adult in ordinary unbranded workout clothes, seated in a parked car outside a neighborhood gym.",
    action: "They pause with visible after-work fatigue, take one breath, reach for a plain gym bag, open the car door, and start walking toward the gym entrance with a more resolved posture.",
    environment: "A parked car outside an unbranded neighborhood gym at golden hour.",
    lighting: "Natural golden-hour light with realistic shadows.",
    visual_style: "Candid phone footage with slight camera movement and no polished commercial look.",
    spoken_dialogue: "",
    ambient_audio: "Quiet car interior and distant parking-lot ambience.",
  }],
  audio_mode: "ambient_plus_captions",
  voiceover_script: "",
  captions_enabled: true,
  caption_text: ["Make the next step small.", "Build a routine you can repeat."],
  cta: "Build a routine you can repeat in GymFeed.",
  platform_copy: {
    instagram_caption: "When motivation is low, make the next step smaller: grab the bag, walk in, and follow the plan you already made. Build a routine you can repeat in GymFeed.",
    tiktok_caption: "Low-energy day? Make the next step tiny. Grab the bag and follow the plan.",
    youtube_title: "Make the Next Step Small",
    youtube_description: "A realistic routine starts with the next repeatable action. Build and track yours in GymFeed.",
    hashtags: ["#GymRoutine", "#WorkoutPlanning", "#FitnessConsistency", "#GymFeed"],
  },
};

await repository.updateContent(video.id, {
  topic: content.topic,
  concept: content.concept,
  hook: content.hook,
  decision: { ...video.decision, content },
  status: "failed",
  provider_task_id: null,
  asset_urls: [],
  thumbnail_url: null,
  qa: {},
  qa_score: null,
  failure_reason: null,
  approved_at: null,
  scheduled_at: null,
});

const carouselResult = await repository.client.from("marketing_content").select("*").eq("content_key", CAROUSEL_KEY).single();
if (carouselResult.error) throw new Error(`Load carousel: ${carouselResult.error.message}`);
const carouselVersion = randomUUID();
const refreshedSlides = [];
for (const [index, assetUrl] of carouselResult.data.asset_urls.entries()) {
  const url = new URL(assetUrl);
  url.searchParams.set("cachebust", Date.now().toString());
  const response = await fetch(url);
  if (!response.ok) throw new Error(`Refresh carousel slide ${index + 1}: ${response.status}`);
  refreshedSlides.push(await repository.uploadAsset(
    `${CAROUSEL_KEY}/${carouselVersion}/slide-${index + 1}.png`,
    Buffer.from(await response.arrayBuffer()),
    "image/png",
  ));
}
await repository.updateContent(carouselResult.data.id, {
  status: "generated",
  provider_task_id: null,
  asset_urls: refreshedSlides,
  thumbnail_url: null,
  qa: {},
  qa_score: null,
  failure_reason: null,
  approved_at: null,
  scheduled_at: null,
});

console.log(JSON.stringify({ video: "ready_for_regeneration", carousel: "ready_for_qa" }, null, 2));
