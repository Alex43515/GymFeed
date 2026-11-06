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
  INSTAGRAM_BUSINESS_ACCOUNT_ID: optionalNonEmpty,
  INSTAGRAM_INSIGHTS_TOKEN: optionalNonEmpty,
  INSTAGRAM_GRAPH_VERSION: optionalNonEmpty,
  TIKTOK_BUSINESS_APP_ID: optionalNonEmpty,
  TIKTOK_BUSINESS_APP_SECRET: optionalNonEmpty,
  TIKTOK_BUSINESS_OPEN_ID: optionalNonEmpty,
  TIKTOK_BUSINESS_REFRESH_TOKEN: optionalNonEmpty,
  YOUTUBE_ANALYTICS_CLIENT_ID: optionalNonEmpty,
  YOUTUBE_ANALYTICS_CLIENT_SECRET: optionalNonEmpty,
  YOUTUBE_ANALYTICS_REFRESH_TOKEN: optionalNonEmpty,

  GOOGLE_SHEETS_APPROVAL_ID: optionalNonEmpty,
  GOOGLE_SHEETS_APPROVAL_TAB: z.string().trim().min(1).default("Content Review"),
  GOOGLE_SHEETS_CREDENTIALS: optionalNonEmpty,
  GOOGLE_DRIVE_ASSET_UPLOAD_URL: optionalNonEmpty,

  OPENAI_API_KEY: optionalNonEmpty,
  OPENAI_RESEARCH_MODEL: z.string().default("gpt-6-luna"),
  OPENAI_DAILY_MODEL: z.string().default("gpt-6-luna"),
  OPENAI_CREATIVE_MODEL: z.string().default("gpt-6-astra"),
  OPENAI_FALLBACK_MODEL: z.string().default("gpt-6-astra"),
  OPENAI_QA_MODEL: z.string().default("gpt-6-luna"),
  OPENAI_WEEKLY_MODEL: z.string().default("gpt-6-sol"),
  OPENAI_RESEARCH_REASONING_EFFORT: z.enum(["none", "low", "medium", "high", "xhigh", "max"]).default("low"),
  OPENAI_REASONING_EFFORT: z.enum(["none", "low", "medium", "high", "xhigh", "max"]).default("medium"),
  OPENAI_QA_REASONING_EFFORT: z.enum(["none", "low", "medium", "high", "xhigh", "max"]).default("low"),
  OPENAI_WEEKLY_REASONING_EFFORT: z.enum(["none", "low", "medium", "high", "xhigh", "max"]).default("medium"),
  OPENAI_RESEARCH_MAX_OUTPUT_TOKENS: z.coerce.number().int().min(1000).max(128000).default(6000),
  OPENAI_CREATIVE_MAX_OUTPUT_TOKENS: z.coerce.number().int().min(1000).max(128000).default(12000),
  OPENAI_QA_MAX_OUTPUT_TOKENS: z.coerce.number().int().min(1000).max(128000).default(6000),
  OPENAI_WEEKLY_MAX_OUTPUT_TOKENS: z.coerce.number().int().min(1000).max(128000).default(10000),
  OPENAI_ESTIMATED_DAILY_COST_USD: z.coerce.number().nonnegative().default(0.25),
  OPENAI_ESTIMATED_QA_COST_USD: z.coerce.number().nonnegative().default(0.05),
  OPENAI_ESTIMATED_WEEKLY_COST_USD: z.coerce.number().nonnegative().default(1),
  OPENAI_INPUT_USD_PER_MILLION: z.coerce.number().nonnegative().default(0.1),
  OPENAI_CACHED_INPUT_USD_PER_MILLION: z.coerce.number().nonnegative().default(0.01),
  OPENAI_CACHE_WRITE_USD_PER_MILLION: z.coerce.number().nonnegative().default(0.125),
  OPENAI_OUTPUT_USD_PER_MILLION: z.coerce.number().nonnegative().default(0.5),
  OPENAI_WEEKLY_INPUT_USD_PER_MILLION: z.coerce.number().nonnegative().default(2),
  OPENAI_WEEKLY_CACHED_INPUT_USD_PER_MILLION: z.coerce.number().nonnegative().default(0.2),
  OPENAI_WEEKLY_CACHE_WRITE_USD_PER_MILLION: z.coerce.number().nonnegative().default(2.5),
  OPENAI_WEEKLY_OUTPUT_USD_PER_MILLION: z.coerce.number().nonnegative().default(10),
  OPENAI_LONG_CONTEXT_THRESHOLD_TOKENS: z.coerce.number().int().positive().default(272000),
  OPENAI_LONG_CONTEXT_INPUT_MULTIPLIER: z.coerce.number().positive().default(2),
  OPENAI_LONG_CONTEXT_OUTPUT_MULTIPLIER: z.coerce.number().positive().default(1.5),
  OPENAI_WEB_SEARCH_USD_PER_CALL: z.coerce.number().nonnegative().default(0.01),
  OPENAI_TTS_MODEL: z.string().default("gpt-4o-mini-tts"),
  OPENAI_TTS_VOICE: z.string().default("coral"),
  OPENAI_ESTIMATED_TTS_COST_USD: z.coerce.number().nonnegative().default(0.05),
  OPENAI_TRANSCRIBE_MODEL: z.string().default("gpt-4o-mini-transcribe"),
  OPENAI_ESTIMATED_TRANSCRIPTION_COST_USD: z.coerce.number().nonnegative().default(0.01),

  FAL_KEY: optionalNonEmpty,
  FAL_IMAGE_MODEL: z.string().default("google/nano-banana-2.1"),
  FAL_IMAGE_WIDTH: z.coerce.number().int().min(512).max(2048).default(1024),
  FAL_IMAGE_HEIGHT: z.coerce.number().int().min(512).max(2048).default(1280),
  FAL_ESTIMATED_IMAGE_COST_USD: z.coerce.number().nonnegative().default(0.08),
  FAL_VIDEO_MODEL: z.string().default("alibaba/wan-3.0/text-to-video"),
  FAL_REFERENCE_VIDEO_MODEL: z.string().default("alibaba/wan-3.0/reference-to-video"),
  FAL_VIDEO_RESOLUTION: z.enum(["480p", "720p", "1080p"]).default("1080p"),
  FAL_VIDEO_USD_PER_SECOND: z.coerce.number().nonnegative().default(0.20),
  MARKETING_REVIEW_MODE: z.enum(["human", "ai"]).default("human"),
  MARKETING_CONTINUITY_MODE: z.enum(["locked", "legacy"]).default("locked"),
  MARKETING_CREATOR_VOICES: z.string().default("coral,nova,shimmer").transform(value=>value.split(",").map(item=>item.trim()).filter(Boolean)),
  FAL_LIPSYNC_MODEL: z.literal("fal-ai/sync-lipsync/v2").default("fal-ai/sync-lipsync/v2"),
  FAL_LIPSYNC_USD_PER_SECOND: z.coerce.number().nonnegative().default(.05),
  FAL_MAX_VIDEO_ATTEMPT_USD: z.coerce.number().positive().default(25),
  FAL_SCENE_MAX_ATTEMPTS: z.coerce.number().int().min(1).max(5).default(2),
  FAL_SCENE_QA_THRESHOLD: z.coerce.number().int().min(70).max(100).default(88),
  FAL_SCENE_EDIT_ENABLED: z.enum(["true", "false"]).default("true").transform((value) => value === "true"),
  FAL_EDIT_MODEL: z.literal("fal-ai/wan/v2.7/edit-video").default("fal-ai/wan/v2.7/edit-video"),
  FAL_EDIT_USD_PER_SECOND: z.coerce.number().nonnegative().default(0.15),

  BUFFER_API_KEY: optionalNonEmpty,
  BUFFER_BASE_URL: z.string().url().default("https://api.buffer.com"),
  BUFFER_CREATIVE_BENCHMARK_POST_IDS: z.string().default("").transform((value) => value.split(",").map((item) => item.trim()).filter(Boolean)),
  BUFFER_SHARE_MODE: z.enum(["addToQueue", "shareNext", "shareNow"]).default("addToQueue"),
  BUFFER_SCHEDULE_AT: optionalNonEmpty,
  BUFFER_INSTAGRAM_CHANNEL_ID: optionalNonEmpty,
  BUFFER_TIKTOK_CHANNEL_ID: optionalNonEmpty,
  BUFFER_YOUTUBE_CHANNEL_ID: optionalNonEmpty,
  BUFFER_YOUTUBE_PRIVACY: z.enum(["private", "unlisted", "public"]).default("public"),
  PHOTO_MUSIC_MODE: z.enum(["off", "notification"]).default("off"),
  GYMFEED_LANDING_URL: z.string().url().default("https://gymfeed.io"),
});

export function loadConfig(env = process.env) {
  return EnvSchema.parse(env);
}

export function requireProviderKey(value, provider) {
  if (!value) throw new Error(`${provider} is not configured`);
  return value;
}
