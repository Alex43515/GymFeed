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

  OPENAI_API_KEY: optionalNonEmpty,
  OPENAI_DAILY_MODEL: z.string().default("gpt-5.6-terra"),
  OPENAI_WEEKLY_MODEL: z.string().default("gpt-5.6-sol"),
  OPENAI_REASONING_EFFORT: z.enum(["none", "low", "medium", "high", "xhigh", "max"]).default("medium"),
  OPENAI_ESTIMATED_DAILY_COST_USD: z.coerce.number().nonnegative().default(0.5),
  OPENAI_ESTIMATED_WEEKLY_COST_USD: z.coerce.number().nonnegative().default(2),
  OPENAI_INPUT_USD_PER_MILLION: z.coerce.number().nonnegative().default(2.5),
  OPENAI_OUTPUT_USD_PER_MILLION: z.coerce.number().nonnegative().default(15),
  OPENAI_WEEKLY_INPUT_USD_PER_MILLION: z.coerce.number().nonnegative().default(5),
  OPENAI_WEEKLY_OUTPUT_USD_PER_MILLION: z.coerce.number().nonnegative().default(30),
  OPENAI_WEB_SEARCH_USD_PER_CALL: z.coerce.number().nonnegative().default(0.01),

  GEMINI_API_KEY: optionalNonEmpty,
  GEMINI_IMAGE_MODEL: z.string().default("gemini-3.1-flash-lite-image"),
  GEMINI_IMAGE_SIZE: z.enum(["1K", "2K", "4K"]).default("1K"),
  GEMINI_ESTIMATED_IMAGE_COST_USD: z.coerce.number().nonnegative().default(0.0336),

  BYTEPLUS_API_KEY: optionalNonEmpty,
  BYTEPLUS_BASE_URL: z.string().url().default("https://ark.ap-southeast.bytepluses.com/api/v3"),
  BYTEPLUS_SEEDANCE_MODEL: z.string().default("dreamina-seedance-2-0-260128"),
  BYTEPLUS_VIDEO_RESOLUTION: z.enum(["480p", "720p", "1080p", "2k", "4k"]).default("720p"),
  BYTEPLUS_WATERMARK: z.enum(["true", "false"]).default("true").transform((value) => value === "true"),
  BYTEPLUS_ESTIMATED_VIDEO_COST_USD: z.coerce.number().nonnegative().default(3),

  BLOTATO_API_KEY: optionalNonEmpty,
  BLOTATO_BASE_URL: z.string().url().default("https://backend.blotato.com/v2"),
  BLOTATO_INSTAGRAM_ACCOUNT_ID: optionalNonEmpty,
  BLOTATO_TIKTOK_ACCOUNT_ID: optionalNonEmpty,
  BLOTATO_YOUTUBE_ACCOUNT_ID: optionalNonEmpty,
  GYMFEED_LANDING_URL: z.string().url().default("https://gymfeed.com"),
});

export function loadConfig(env = process.env) {
  return EnvSchema.parse(env);
}

export function requireProviderKey(value, provider) {
  if (!value) throw new Error(`${provider} is not configured`);
  return value;
}
