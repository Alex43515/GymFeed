import { loadConfig } from "./config.mjs";
import { MarketingRepository } from "./repository.mjs";
import { MarketingBrain } from "./brain.mjs";
import { MarketingOrchestrator } from "./orchestrator.mjs";
import { FalMediaProvider } from "./providers/fal.mjs";
import { BufferPublisher } from "./providers/buffer.mjs";
import { Ga4Reporter } from "./providers/ga4.mjs";
import { OpenAIVoiceProvider } from "./providers/openai-voice.mjs";
import { ReviewBoard as GoogleSheetsApprovalQueue } from "./providers/review-board.mjs";
import { buildApp } from "./app.mjs";
import { MarketingCampaigns } from "./campaigns.mjs";
import { CmoController } from "./cmo-controller.mjs";
import { CaptureIngestor } from "./capture-ingest.mjs";
import { CaptureStorage } from "./capture-storage.mjs";
import { LibraryInbox } from "./library-inbox.mjs";
import { createOutreachService, registerOutreachRoutes } from "./outreach/index.mjs";
import { registerStudioRoutes } from "./studio-api.mjs";
import { registerStudioAnalytics } from "./studio-analytics.mjs";
import { createStudioEditor } from "./studio-editor.mjs";

const config = loadConfig();
const repository = new MarketingRepository(config);
const campaigns = new MarketingCampaigns({ repository });
const brain = new MarketingBrain(config);
const mediaProvider = new FalMediaProvider({
  apiKey: config.FAL_KEY,
  imageModel: config.FAL_IMAGE_MODEL,
  imageWidth: config.FAL_IMAGE_WIDTH,
  imageHeight: config.FAL_IMAGE_HEIGHT,
  videoModel: config.FAL_VIDEO_MODEL,
  referenceVideoModel: config.FAL_REFERENCE_VIDEO_MODEL,
  videoResolution: config.FAL_VIDEO_RESOLUTION,
});
const publisher = new BufferPublisher({
  apiKey: config.BUFFER_API_KEY,
  baseUrl: config.BUFFER_BASE_URL,
  benchmarkPostIds: config.BUFFER_CREATIVE_BENCHMARK_POST_IDS,
  shareMode: config.BUFFER_SHARE_MODE,
  youtubePrivacy: config.BUFFER_YOUTUBE_PRIVACY,
});
const analyticsReporter = new Ga4Reporter({
  propertyId: config.GA4_PROPERTY_ID,
  credentialsPath: config.GOOGLE_SHEETS_CREDENTIALS ?? process.env.GOOGLE_APPLICATION_CREDENTIALS,
});
const voiceProvider = new OpenAIVoiceProvider({
  apiKey: config.OPENAI_API_KEY,
  model: config.OPENAI_TTS_MODEL,
  voice: config.OPENAI_TTS_VOICE,
  transcribeModel: config.OPENAI_TRANSCRIBE_MODEL,
});
const approvalSheet = new GoogleSheetsApprovalQueue({
  spreadsheetId: config.GOOGLE_SHEETS_APPROVAL_ID,
  sheetName: config.GOOGLE_SHEETS_APPROVAL_TAB,
  credentialsPath: config.GOOGLE_SHEETS_CREDENTIALS ?? process.env.GOOGLE_APPLICATION_CREDENTIALS,
});
const captureStorage = new CaptureStorage(repository.client.storage);
const orchestrator = new MarketingOrchestrator({
  config,
  repository,
  brain,
  mediaProvider,
  publisher,
  analyticsReporter,
  voiceProvider,
  approvalSheet,
  campaigns,
  appCaptureResolver: ref => captureStorage.resolve(ref),
});
const captureIngestor = new CaptureIngestor({ credentialsPath: config.GOOGLE_SHEETS_CREDENTIALS ?? process.env.GOOGLE_APPLICATION_CREDENTIALS });
const libraryInbox = new LibraryInbox({ ingestor: captureIngestor, brain, repository, config });
const cmo = new CmoController({ orchestrator, campaigns, repository, approvalSheet, config, libraryInbox });
const app = buildApp({ config, orchestrator, cmo, captureIngestor, logger: { level: config.LOG_LEVEL } });
registerOutreachRoutes(app, createOutreachService({ config, logger: app.log }));
const editor = createStudioEditor({ config, repository, mediaProvider, publisher });
registerStudioRoutes(app, { config, cmo, repository, orchestrator, captureStorage, editor });
registerStudioAnalytics(app, { repository, publisher, config });

try {
  await app.listen({ port: config.PORT, host: "0.0.0.0" });
} catch (error) {
  app.log.error(error);
  process.exit(1);
}
