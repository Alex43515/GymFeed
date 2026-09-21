import test from "node:test";
import assert from "node:assert/strict";
import { responseCost, validateCreativeDecision } from "../src/brain.mjs";

test("response cost includes model tokens and web searches", () => {
  const response = {
    usage: { input_tokens: 1_000_000, output_tokens: 100_000 },
    output: [{ type: "web_search_call" }, { type: "message" }, { type: "web_search_call" }],
  };
  const config = {
    OPENAI_WEEKLY_MODEL: "gpt-5.6-sol",
    OPENAI_INPUT_USD_PER_MILLION: 2,
    OPENAI_OUTPUT_USD_PER_MILLION: 12,
    OPENAI_WEEKLY_INPUT_USD_PER_MILLION: 5,
    OPENAI_WEEKLY_OUTPUT_USD_PER_MILLION: 30,
    OPENAI_WEB_SEARCH_USD_PER_CALL: 0.01,
  };
  assert.equal(responseCost(response, config), 3.22);
});

test("response cost uses Sol rates for the weekly model", () => {
  const response = {
    model: "gpt-5.6-sol",
    usage: { input_tokens: 1_000_000, output_tokens: 100_000 },
    output: [],
  };
  const config = {
    OPENAI_WEEKLY_MODEL: "gpt-5.6-sol",
    OPENAI_INPUT_USD_PER_MILLION: 2.5,
    OPENAI_OUTPUT_USD_PER_MILLION: 15,
    OPENAI_WEEKLY_INPUT_USD_PER_MILLION: 5,
    OPENAI_WEEKLY_OUTPUT_USD_PER_MILLION: 30,
    OPENAI_WEB_SEARCH_USD_PER_CALL: 0.01,
  };
  assert.equal(responseCost(response, config), 8);
});

test("creative decision validation enforces evidence lineage, score math, and the chosen visual mode", () => {
  const research = { trends: [{ evidence_id: "T1" }, { evidence_id: "T2" }, { evidence_id: "T3" }] };
  const scores = {
    evidence_strength: 80,
    audience_fit: 80,
    product_fit: 80,
    attention_potential: 80,
    conversion_potential: 80,
    production_feasibility: 80,
  };
  const candidate = (name, contentMode, weightedScore, scoreValue = weightedScore) => ({
    name,
    content_mode: contentMode,
    evidence_ids: ["T1"],
    scores: Object.fromEntries(Object.keys(scores).map((key) => [key, scoreValue])),
    weighted_score: weightedScore,
  });
  const decision = {
    candidate_concepts: [
      candidate("Human", "human_story", 80),
      candidate("Product", "product_demonstration", 80),
      candidate("Hybrid", "hybrid", 80),
    ],
    selected_strategy: { candidate_name: "Human" },
    video: {
      creative_treatment: {
        visual_mode: "human_led",
        opening_asset: "fal_video",
        people_role: "primary",
        people_screen_time_percent: 33,
        product_screen_time_percent: 67,
        evidence_ids: ["T1"],
      },
      target_duration_seconds: 18,
      character_reference: {
        required: true,
        description: "fictional adult trainee",
        wardrobe: "plain black gym kit",
        environment_anchor: "unbranded gym",
        continuity_rules: ["same adult and wardrobe"],
      },
      scenes: [
        {
          scene_id: "hero",
          asset_type: "generated_video",
          purpose: "hook",
          source_duration_seconds: 10,
          duration_seconds: 6,
          subject: "fictional adult creator facing the viewer",
          action: "speaks directly to camera with a small uncertain pause",
          spoken_dialogue: "Ever arrive ready to train but forget the actual plan?",
          screenshot_ref: "",
        },
        { scene_id: "proof", asset_type: "gymfeed_screen", purpose: "product_proof", source_duration_seconds: 0, duration_seconds: 6, screenshot_ref: "curated/screen.png" },
        { scene_id: "cta", asset_type: "gymfeed_screen", purpose: "cta", source_duration_seconds: 0, duration_seconds: 6, overlay_text: "Know the next move. Open GymFeed.", screenshot_ref: "curated/screen.png" },
      ],
      audio_mode: "native_audio",
      captions_enabled: true,
    },
    instagram: {
      slides: [
        { visual_type: "human_lifestyle", screenshot_ref: "" },
        { visual_type: "product_screenshot", screenshot_ref: "curated/screen.png" },
      ],
    },
  };

  assert.equal(validateCreativeDecision(research, decision), decision);
  const topTierDecision = {
    ...decision,
    candidate_concepts: [
      candidate("Human", "human_story", 76),
      candidate("Product", "product_demonstration", 80),
      candidate("Hybrid", "hybrid", 80),
    ],
  };
  assert.equal(validateCreativeDecision(research, topTierDecision), topTierDecision);
  assert.throws(
    () => validateCreativeDecision(research, {
      ...decision,
      candidate_concepts: [
        candidate("Human", "human_story", 70),
        candidate("Product", "product_demonstration", 80),
        candidate("Hybrid", "hybrid", 80),
      ],
    }),
    /top-tier candidate/,
  );
  assert.throws(
    () => validateCreativeDecision(research, {
      ...decision,
      video: { creative_treatment: { ...decision.video.creative_treatment, evidence_ids: ["UNKNOWN"] } },
    }),
    /unknown evidence/,
  );
});
