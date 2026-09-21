import { loadConfig } from "./config.mjs";
import { MarketingRepository } from "./repository.mjs";
import { MarketingBrain } from "./brain.mjs";
import { MarketingOrchestrator } from "./orchestrator.mjs";
import { FalMediaProvider } from "./providers/fal.mjs";
import { BufferPublisher } from "./providers/buffer.mjs";
import { Ga4Reporter } from "./providers/ga4.mjs";
import { OpenAIVoiceProvider } from "./providers/openai-voice.mjs";
import { GoogleSheetsApprovalQueue } from "./providers/google-sheets.mjs";
import { buildApp } from "./app.mjs";
import { MarketingCampaigns } from "./campaigns.mjs";
import { CmoController } from "./cmo-controller.mjs";

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
});
const cmo = new CmoController({ orchestrator, campaigns, repository, approvalSheet, config });
const app = buildApp({ config, orchestrator, cmo, logger: { level: config.LOG_LEVEL } });

try {
  await app.listen({ port: config.PORT, host: "0.0.0.0" });
} catch (error) {
  app.log.error(error);
  process.exit(1);
}
