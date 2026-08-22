import { loadConfig } from "./config.mjs";
import { MarketingRepository } from "./repository.mjs";
import { MarketingBrain } from "./brain.mjs";
import { MarketingOrchestrator } from "./orchestrator.mjs";
import { GeminiImageProvider } from "./providers/gemini.mjs";
import { BytePlusVideoProvider } from "./providers/byteplus.mjs";
import { BlotatoPublisher } from "./providers/blotato.mjs";
import { buildApp } from "./app.mjs";

const config = loadConfig();
const repository = new MarketingRepository(config);
const brain = new MarketingBrain(config);
const gemini = new GeminiImageProvider({
  apiKey: config.GEMINI_API_KEY,
  model: config.GEMINI_IMAGE_MODEL,
  imageSize: config.GEMINI_IMAGE_SIZE,
});
const byteplus = new BytePlusVideoProvider({
  apiKey: config.BYTEPLUS_API_KEY,
  baseUrl: config.BYTEPLUS_BASE_URL,
  model: config.BYTEPLUS_SEEDANCE_MODEL,
  resolution: config.BYTEPLUS_VIDEO_RESOLUTION,
  watermark: config.BYTEPLUS_WATERMARK,
});
const blotato = new BlotatoPublisher({ apiKey: config.BLOTATO_API_KEY, baseUrl: config.BLOTATO_BASE_URL });
const orchestrator = new MarketingOrchestrator({ config, repository, brain, gemini, byteplus, blotato });
const app = buildApp({ config, orchestrator, logger: { level: config.LOG_LEVEL } });

try {
  await app.listen({ port: config.PORT, host: "0.0.0.0" });
} catch (error) {
  app.log.error(error);
  process.exit(1);
}
