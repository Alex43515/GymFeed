import { z } from "zod";

const boolFromString = z
  .enum(["true", "false"])
  .default("false")
  .transform((value) => value === "true");

const optionalNonEmpty = z.preprocess(
  (value) => typeof value === "string" && value.trim() === "" ? undefined : value,
  z.string().trim().min(1).optional(),
);

const OutreachEnvSchema = z.object({
  OUTREACH_ENABLED: boolFromString,
  // false = the bot writes its suggested reply into the sheet; true = it sends the reply on Instagram.
  OUTREACH_AUTO_REPLY: boolFromString,
  OUTREACH_SHEET_ID: optionalNonEmpty,
  OUTREACH_SHEET_TAB: z.string().trim().min(1).default("Influencer Outreach"),
  OUTREACH_WEEKLY_TARGET: z.coerce.number().int().min(1).max(150).default(40),
  OUTREACH_MIN_FOLLOWERS: z.coerce.number().int().nonnegative().default(5000),
  OUTREACH_MAX_FOLLOWERS: z.coerce.number().int().positive().default(250000),
  OUTREACH_MIN_FIT_SCORE: z.coerce.number().int().min(0).max(100).default(60),
  OUTREACH_MODEL: z.string().default("gpt-6-luna"),
  OUTREACH_DISCOVERY_MODEL: z.string().default("gpt-6-luna"),
  OUTREACH_REASONING_EFFORT: z.enum(["none", "low", "medium", "high"]).default("low"),
  OUTREACH_DISCOVERY_REASONING_EFFORT: z.enum(["none", "low", "medium", "high"]).default("medium"),
  OUTREACH_OWNER_NAME: z.string().trim().min(1).default("Founder"),
  OUTREACH_HANDOFF_WEBHOOK_URL: optionalNonEmpty,
  OUTREACH_ACCOUNT_USERNAME: z.string().trim().min(1).default("gymfeed.official"),

  INSTAGRAM_GRAPH_VERSION: z.string().trim().min(1).default("v23.0"),
  // Facebook-login token + IG professional account id: used only for Business Discovery enrichment.
  INSTAGRAM_BUSINESS_ACCOUNT_ID: optionalNonEmpty,
  INSTAGRAM_GRAPH_ACCESS_TOKEN: optionalNonEmpty,
  // Instagram-login token with instagram_business_manage_messages: used to read and answer DMs.
  INSTAGRAM_MESSAGING_ACCESS_TOKEN: optionalNonEmpty,
  INSTAGRAM_APP_SECRET: optionalNonEmpty,
  INSTAGRAM_WEBHOOK_VERIFY_TOKEN: optionalNonEmpty,
});

export function loadOutreachConfig(env = process.env) {
  return OutreachEnvSchema.parse(env);
}
