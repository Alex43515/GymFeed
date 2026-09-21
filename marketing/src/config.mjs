import { z } from "zod";

const boolFromString = z
  .enum(["true", "false"])
  .default("false")
  .transform((value) => value === "true");

const optionalNonEmpty = z.preprocess(
  (value) => typeof value === "string" && value.trim() === "" ? undefined : value,
  z.string().trim().min(1).optional(),
);

const EnvSchema = z.object({
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  LOG_LEVEL: z.enum(["fatal", "error", "warn", "info", "debug", "trace", "silent"]).default("info"),
  MARKETING_INTERNAL_TOKEN: z.string().min(32),
  MARKETING_APPROVAL_TOKEN: z.string().min(32),
  AUTO_PUBLISH: boolFromString,
  GENERATE_ASSETS: z.enum(["true", "false"]).default("false").transform((value) => value === "true"),

  SUPABASE_URL: z.string().url(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(20),
  SUPABASE_MARKETING_BUCKET: z.string().default("marketing-assets"),

  GA4_PROPERTY_ID: optionalNonEmpty,

  GOOGLE_SHEETS_APPROVAL_ID: optionalNonEmpty,
  GOOGLE_SHEETS_APPROVAL_TAB: z.string().trim().min(1).default("Content Review"),
  GOOGLE_SHEETS_CREDENTIALS: optionalNonEmpty,

  OPENAI_API_KEY: optionalNonEmpty,
  OPENAI_DAILY_MODEL: z.string().default("gpt-5.6-terra"),
  OPENAI_WEEKLY_MODEL: z.string().default("gpt-5.6-sol"),
  OPENAI_REASONING_EFFORT: z.enum(["none", "low", "medium", "high", "xhigh", "max"]).default("medium"),
  OPENAI_ESTIMATED_DAILY_COST_USD: z.coerce.number().nonnegative().default(0.5),
  OPENAI_ESTIMATED_QA_COST_USD: z.coerce.number().nonnegative().default(0.15),
  OPENAI_ESTIMATED_WEEKLY_COST_USD: z.coerce.number().nonnegative().default(2),
  OPENAI_INPUT_USD_PER_MILLION: z.coerce.number().nonnegative().default(2),
  OPENAI_OUTPUT_USD_PER_MILLION: z.coerce.number().nonnegative().default(12),
  OPENAI_WEEKLY_INPUT_USD_PER_MILLION: z.coerce.number().nonnegative().default(4),
  OPENAI_WEEKLY_OUTPUT_USD_PER_MILLION: z.coerce.number().nonnegative().default(20),
  OPENAI_WEB_SEARCH_USD_PER_CALL: z.coerce.number().nonnegative().default(0.01),
  OPENAI_TTS_MODEL: z.string().default("gpt-4o-mini-tts"),
  OPENAI_TTS_VOICE: z.string().default("coral"),
  OPENAI_ESTIMATED_TTS_COST_USD: z.coerce.number().nonnegative().default(0.05),
  OPENAI_TRANSCRIBE_MODEL: z.string().default("gpt-4o-mini-transcribe"),
  OPENAI_ESTIMATED_TRANSCRIPTION_COST_USD: z.coerce.number().nonnegative().default(0.01),

  FAL_KEY: optionalNonEmpty,
  FAL_IMAGE_MODEL: z.string().default("fal-ai/nano-banana-2"),
  FAL_IMAGE_WIDTH: z.coerce.number().int().min(512).max(2048).default(1024),
  FAL_IMAGE_HEIGHT: z.coerce.number().int().min(512).max(2048).default(1280),
  FAL_ESTIMATED_IMAGE_COST_USD: z.coerce.number().nonnegative().default(0.08),
  FAL_VIDEO_MODEL: z.string().default("google/gemini-omni-flash/v1.1/text-to-video"),
  FAL_REFERENCE_VIDEO_MODEL: z.string().default("google/gemini-omni-flash/v1.1/reference-to-video"),
  FAL_VIDEO_RESOLUTION: z.enum(["480p", "720p"]).default("720p"),
  FAL_VIDEO_USD_PER_SECOND: z.coerce.number().nonnegative().default(0.10),
  FAL_SCENE_MAX_ATTEMPTS: z.coerce.number().int().min(1).max(5).default(2),
  FAL_SCENE_QA_THRESHOLD: z.coerce.number().int().min(70).max(100).default(88),

  BUFFER_API_KEY: optionalNonEmpty,
  BUFFER_BASE_URL: z.string().url().default("https://api.buffer.com"),
  BUFFER_SHARE_MODE: z.enum(["addToQueue", "shareNext", "shareNow"]).default("addToQueue"),
  BUFFER_SCHEDULE_AT: optionalNonEmpty,
  BUFFER_INSTAGRAM_CHANNEL_ID: optionalNonEmpty,
  BUFFER_TIKTOK_CHANNEL_ID: optionalNonEmpty,
  BUFFER_YOUTUBE_CHANNEL_ID: optionalNonEmpty,
  BUFFER_YOUTUBE_PRIVACY: z.enum(["private", "unlisted", "public"]).default("private"),
  GYMFEED_LANDING_URL: z.string().url().default("https://gymfeed.io"),
});

export function loadConfig(env = process.env) {
  return EnvSchema.parse(env);
}

export function requireProviderKey(value, provider) {
  if (!value) throw new Error(`${provider} is not configured`);
  return value;
}
