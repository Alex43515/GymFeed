import { mkdir, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { resolve } from "node:path";
import { setTimeout as delay } from "node:timers/promises";
import { loadConfig } from "../src/config.mjs";
import { MarketingRepository } from "../src/repository.mjs";
import { MarketingBrain } from "../src/brain.mjs";
import { MarketingOrchestrator } from "../src/orchestrator.mjs";
import { FalMediaProvider } from "../src/providers/fal.mjs";
import { BufferPublisher } from "../src/providers/buffer.mjs";

const scheduleAt = process.argv[2];
if (!scheduleAt || Number.isNaN(new Date(scheduleAt).getTime())) {
  throw new Error("Pass a valid future ISO date-time as the first argument");
}
if (new Date(scheduleAt).getTime() <= Date.now()) throw new Error("The schedule must be in the future");

const config = loadConfig({
  ...process.env,
  GENERATE_ASSETS: "true",
  AUTO_PUBLISH: "true",
  BUFFER_SCHEDULE_AT: scheduleAt,
});
for (const [name, value] of Object.entries({
  FAL_KEY: config.FAL_KEY,
  BUFFER_API_KEY: config.BUFFER_API_KEY,
  BUFFER_INSTAGRAM_CHANNEL_ID: config.BUFFER_INSTAGRAM_CHANNEL_ID,
  BUFFER_TIKTOK_CHANNEL_ID: config.BUFFER_TIKTOK_CHANNEL_ID,
  BUFFER_YOUTUBE_CHANNEL_ID: config.BUFFER_YOUTUBE_CHANNEL_ID,
})) {
  if (!value) throw new Error(`${name} is required for the scheduled test`);
}

const repository = new MarketingRepository(config);
const brain = new MarketingBrain(config);
const mediaProvider = new FalMediaProvider({
  apiKey: config.FAL_KEY,
  imageModel: config.FAL_IMAGE_MODEL,
  imageWidth: config.FAL_IMAGE_WIDTH,
  imageHeight: config.FAL_IMAGE_HEIGHT,
  videoModel: config.FAL_VIDEO_MODEL,
  videoResolution: config.FAL_VIDEO_RESOLUTION,
});
const publisher = new BufferPublisher({
  apiKey: config.BUFFER_API_KEY,
  baseUrl: config.BUFFER_BASE_URL,
  shareMode: config.BUFFER_SHARE_MODE,
  youtubePrivacy: config.BUFFER_YOUTUBE_PRIVACY,
});
const orchestrator = new MarketingOrchestrator({ config, repository, brain, mediaProvider, publisher });

const originalBrand = await repository.brandConfig();
const report = { scheduleAt, startedAt: new Date().toISOString(), content: [] };
try {
  const { error: enableError } = await repository.client.from("marketing_brand_config").update({
    enabled: true,
    manual_approval_required: true,
  }).eq("id", "gymfeed");
  if (enableError) throw new Error(`Temporarily enable marketing: ${enableError.message}`);

  const daily = await orchestrator.runDaily(new Date());
  let content = daily.content;
  if (!content) {
    const result = await repository.client.from("marketing_content").select("*").eq("run_id", daily.run.id).order("created_at");
    if (result.error) throw new Error(`Load daily content: ${result.error.message}`);
    content = result.data;
  }
  if (!content?.length) throw new Error("Daily planning produced no content");

  for (const item of content) {
    const generated = await orchestrator.generateContent(item.id);
    report.content.push({ id: item.id, contentKey: item.content_key, type: item.content_type, generation: generated.content?.status ?? generated.reason });
  }

  const videoItem = content.find((item) => item.content_type === "video");
  if (videoItem) {
    const deadline = Date.now() + 20 * 60 * 1000;
    let latest = await repository.contentById(videoItem.id);
    while (latest.status === "generating" && Date.now() < deadline) {
      await delay(15000);
      const refreshed = await orchestrator.refreshContent(videoItem.id);
      if (!refreshed.pending) break;
      latest = await repository.contentById(videoItem.id);
    }
    latest = await repository.contentById(videoItem.id);
    if (latest.status !== "generated") throw new Error(`Video did not finish successfully; status is ${latest.status}`);
  }

  for (const item of content) {
    const review = await orchestrator.reviewContent(item.id);
    const entry = report.content.find((candidate) => candidate.id === item.id);
    entry.qaPassed = review.passed;
    entry.qaScore = review.content?.qa_score ?? null;
    entry.failureReason = review.content?.failure_reason ?? null;
    entry.assetUrls = review.content?.asset_urls ?? [];
    entry.thumbnailUrl = review.content?.thumbnail_url ?? null;
    if (!review.passed) {
      entry.finalStatus = review.content?.status ?? "qa_failed";
      continue;
    }
    const approved = await orchestrator.approveContent(item.id);
    const published = await orchestrator.publishContent(item.id);
    entry.finalStatus = (await repository.contentById(item.id)).status;
    entry.publications = (published.publications ?? []).map((publication) => ({
      platform: publication.platform,
      status: publication.status,
      providerRequestId: publication.provider_request_id,
      error: publication.error,
    }));
  }
} finally {
  const { error: restoreError } = await repository.client.from("marketing_brand_config").update({
    enabled: originalBrand.enabled,
    manual_approval_required: originalBrand.manual_approval_required,
  }).eq("id", "gymfeed");
  if (restoreError) report.restoreError = restoreError.message;
  report.completedAt = new Date().toISOString();
  try {
    const directory = resolve(tmpdir(), "gymfeed-marketing");
    await mkdir(directory, { recursive: true });
    await writeFile(resolve(directory, "scheduled-test-report.json"), JSON.stringify(report, null, 2));
  } catch (error) {
    report.reportWriteError = error.message;
  }
}

console.log(JSON.stringify(report, null, 2));
