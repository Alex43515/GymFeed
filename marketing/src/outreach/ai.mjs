import OpenAI from "openai";
import { zodTextFormat } from "openai/helpers/zod";
import { CandidateListSchema, QualificationSchema, ReplyDecisionSchema } from "./contracts.mjs";
import { DISCOVERY_PROMPT, QUALIFICATION_PROMPT, REPLY_AGENT_PROMPT } from "./prompts.mjs";

const QUALIFY_BATCH = 10;

export class OutreachAI {
  constructor({ apiKey, model, discoveryModel, reasoningEffort = "low", discoveryReasoningEffort = "medium", client } = {}) {
    this.client = client ?? (apiKey ? new OpenAI({ apiKey }) : null);
    this.model = model;
    this.discoveryModel = discoveryModel ?? model;
    this.reasoningEffort = reasoningEffort;
    this.discoveryReasoningEffort = discoveryReasoningEffort;
  }

  ensureClient() {
    if (!this.client) throw new Error("OpenAI is not configured (set OPENAI_API_KEY)");
  }

  async parse({ model, system, user, schema, name, tools, maxOutputTokens = 6000, reasoningEffort = this.reasoningEffort }) {
    this.ensureClient();
    const response = await this.client.responses.parse({
      model,
      reasoning: { effort: reasoningEffort },
      ...(tools ? { tools, tool_choice: "auto" } : {}),
      input: [
        { role: "system", content: [{ type: "input_text", text: system }] },
        { role: "user", content: [{ type: "input_text", text: user }] },
      ],
      text: { format: zodTextFormat(schema, name) },
      max_output_tokens: maxOutputTokens,
    });
    if (!response.output_parsed) throw new Error(`OpenAI returned no parsed ${name}`);
    return response.output_parsed;
  }

  async discover({ count, exclude, minFollowers, maxFollowers, angle }) {
    return this.parse({
      model: this.discoveryModel,
      system: DISCOVERY_PROMPT,
      tools: [{ type: "web_search" }],
      name: "creator_candidates",
      schema: CandidateListSchema,
      maxOutputTokens: 16000,
      reasoningEffort: this.discoveryReasoningEffort,
      user: [
        `Today: ${new Date().toISOString().slice(0, 10)}`,
        `SEARCH ANGLE FOR THIS PASS: ${angle}`,
        `Find up to ${count} creators with roughly ${minFollowers}-${maxFollowers} followers. Run several searches.`,
        `EXCLUDE (already in our list or found earlier): ${exclude.slice(0, 400).join(", ") || "none"}`,
      ].join("\n"),
    });
  }

  async qualify(creators) {
    const results = [];
    for (let index = 0; index < creators.length; index += QUALIFY_BATCH) {
      const batch = creators.slice(index, index + QUALIFY_BATCH);
      const parsed = await this.parse({
        model: this.model,
        system: QUALIFICATION_PROMPT,
        name: "creator_qualification",
        schema: QualificationSchema,
        maxOutputTokens: 8000,
        user: `CREATORS:\n${JSON.stringify(batch, null, 2)}`,
      });
      results.push(...parsed.results);
    }
    return results;
  }

  async reply({ creator, conversation }) {
    return this.parse({
      model: this.model,
      system: REPLY_AGENT_PROMPT,
      name: "creator_reply",
      schema: ReplyDecisionSchema,
      maxOutputTokens: 3000,
      user: [
        `CREATOR (from our outreach sheet):\n${JSON.stringify(creator, null, 2)}`,
        `CONVERSATION (oldest first; "gymfeed" is us):\n${conversation.map((message) => `${message.from}: ${message.text}`).join("\n")}`,
        "Write the next GymFeed reply.",
      ].join("\n\n"),
    });
  }
}
