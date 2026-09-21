import { loadConfig } from "../src/config.mjs";
import { MarketingRepository } from "../src/repository.mjs";
import { MarketingBrain } from "../src/brain.mjs";
import { MarketingOrchestrator } from "../src/orchestrator.mjs";
import { FalMediaProvider } from "../src/providers/fal.mjs";
import { BufferPublisher } from "../src/providers/buffer.mjs";

const [contentId, scheduleAt] = process.argv.slice(2);
if (!contentId) throw new Error("Pass a content ID");
if (!scheduleAt || Number.isNaN(new Date(scheduleAt).getTime()) || new Date(scheduleAt) <= new Date()) {
  throw new Error("Pass a valid future ISO schedule time");
}

const config = loadConfig({ ...process.env, AUTO_PUBLISH: "true", BUFFER_SCHEDULE_AT: scheduleAt });
const repository = new MarketingRepository(config);
const originalBrand = await repository.brandConfig();
const orchestrator = new MarketingOrchestrator({
  config,
  repository,
  brain: new MarketingBrain(config),
  mediaProvider: new FalMediaProvider({
    apiKey: config.FAL_KEY,
    imageModel: config.FAL_IMAGE_MODEL,
    imageWidth: config.FAL_IMAGE_WIDTH,
    imageHeight: config.FAL_IMAGE_HEIGHT,
    videoModel: config.FAL_VIDEO_MODEL,
    videoResolution: config.FAL_VIDEO_RESOLUTION,
  }),
  publisher: new BufferPublisher({
    apiKey: config.BUFFER_API_KEY,
    baseUrl: config.BUFFER_BASE_URL,
    shareMode: config.BUFFER_SHARE_MODE,
    youtubePrivacy: config.BUFFER_YOUTUBE_PRIVACY,
  }),
});

try {
  const enable = await repository.client.from("marketing_brand_config").update({ enabled: true }).eq("id", "gymfeed");
  if (enable.error) throw new Error(`Temporarily enable marketing: ${enable.error.message}`);
  const result = await orchestrator.publishContent(contentId);
  console.log(JSON.stringify({
    contentId,
    publications: (result.publications ?? []).map((publication) => ({
      platform: publication.platform,
      status: publication.status,
      providerRequestId: publication.provider_request_id,
      scheduledAt: publication.scheduled_at,
      error: publication.error,
    })),
  }, null, 2));
} finally {
  const restore = await repository.client.from("marketing_brand_config").update({ enabled: originalBrand.enabled }).eq("id", "gymfeed");
  if (restore.error) throw new Error(`Restore marketing switch: ${restore.error.message}`);
}
