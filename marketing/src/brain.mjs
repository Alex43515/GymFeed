import OpenAI from "openai";
import { zodTextFormat } from "openai/helpers/zod";
import { DailyDecisionSchema, QualityReviewSchema, WeeklyReviewSchema } from "./contracts.mjs";
import { DAILY_BRAIN_PROMPT, QA_PROMPT, WEEKLY_CMO_PROMPT } from "./prompts.mjs";

function compactContext(context) {
  return JSON.stringify(context, (_key, value) => {
    if (typeof value === "string" && value.length > 3000) return `${value.slice(0, 3000)}…`;
    return value;
  });
}

export function responseCost(response, config) {
  const input = response.usage?.input_tokens ?? 0;
  const output = response.usage?.output_tokens ?? 0;
  const searches = response.output?.filter((item) => item.type === "web_search_call").length ?? 0;
  const isWeeklyModel = response.model === config.OPENAI_WEEKLY_MODEL
    || response.model?.startsWith(`${config.OPENAI_WEEKLY_MODEL}-`);
  const inputRate = isWeeklyModel
    ? config.OPENAI_WEEKLY_INPUT_USD_PER_MILLION
    : config.OPENAI_INPUT_USD_PER_MILLION;
  const outputRate = isWeeklyModel
    ? config.OPENAI_WEEKLY_OUTPUT_USD_PER_MILLION
    : config.OPENAI_OUTPUT_USD_PER_MILLION;
  return Number((
    input * inputRate / 1_000_000
    + output * outputRate / 1_000_000
    + searches * config.OPENAI_WEB_SEARCH_USD_PER_CALL
  ).toFixed(6));
}

export class MarketingBrain {
  constructor(config, client) {
    this.config = config;
    this.client = client ?? (config.OPENAI_API_KEY ? new OpenAI({ apiKey: config.OPENAI_API_KEY }) : null);
  }

  ensureConfigured() {
    if (!this.client) throw new Error("OpenAI is not configured");
  }

  async daily(context) {
    this.ensureConfigured();
    const response = await this.client.responses.parse({
      model: this.config.OPENAI_DAILY_MODEL,
      reasoning: { effort: this.config.OPENAI_REASONING_EFFORT },
      tools: [{ type: "web_search" }],
      tool_choice: "auto",
      input: [
        { role: "system", content: DAILY_BRAIN_PROMPT },
        { role: "user", content: `Current date: ${new Date().toISOString()}\nGymFeed context:\n${compactContext(context)}` },
      ],
      text: { format: zodTextFormat(DailyDecisionSchema, "gymfeed_daily_decision") },
    });
    if (!response.output_parsed) throw new Error("OpenAI returned no parsed daily decision");
    return { data: response.output_parsed, costUsd: responseCost(response, this.config), responseId: response.id };
  }

  async qualityReview(content, visualUrls = []) {
    this.ensureConfigured();
    const userContent = [
      { type: "input_text", text: `Content record and plan:\n${compactContext(content)}` },
      ...visualUrls.map((imageUrl) => ({ type: "input_image", image_url: imageUrl, detail: "high" })),
    ];
    const response = await this.client.responses.parse({
      model: this.config.OPENAI_DAILY_MODEL,
      reasoning: { effort: this.config.OPENAI_REASONING_EFFORT },
      input: [
        { role: "system", content: QA_PROMPT },
        { role: "user", content: userContent },
      ],
      text: { format: zodTextFormat(QualityReviewSchema, "gymfeed_quality_review") },
    });
    if (!response.output_parsed) throw new Error("OpenAI returned no parsed quality review");
    return { data: response.output_parsed, costUsd: responseCost(response, this.config), responseId: response.id };
  }

  async weekly(context) {
    this.ensureConfigured();
    const response = await this.client.responses.parse({
      model: this.config.OPENAI_WEEKLY_MODEL,
      reasoning: { effort: this.config.OPENAI_REASONING_EFFORT },
      input: [
        { role: "system", content: WEEKLY_CMO_PROMPT },
        { role: "user", content: compactContext(context) },
      ],
      text: { format: zodTextFormat(WeeklyReviewSchema, "gymfeed_weekly_review") },
    });
    if (!response.output_parsed) throw new Error("OpenAI returned no parsed weekly review");
    return { data: response.output_parsed, costUsd: responseCost(response, this.config), responseId: response.id };
  }
}
