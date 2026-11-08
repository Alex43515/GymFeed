import test from "node:test";
import assert from "node:assert/strict";
import { buildAiDecisionContext, compactContext, researchEvidenceForQa, responseCost, validateCreativeDecision } from "../src/brain.mjs";

test("response cost distinguishes uncached, cached, cache-write, output, and search usage", () => {
  const response = {
    model: "gpt-6-luna",
    usage: {
      input_tokens: 1_000_000,
      input_tokens_details: { cache_write_tokens: 800_000, cached_tokens: 100_000 },
      output_tokens: 100_000,
    },
    output: [{ type: "web_search_call" }, { type: "message" }, { type: "web_search_call" }],
  };
  const config = {
    OPENAI_WEEKLY_MODEL: "gpt-6-sol",
    OPENAI_FALLBACK_MODEL: "gpt-6-sol",
    OPENAI_INPUT_USD_PER_MILLION: 0.1,
    OPENAI_CACHED_INPUT_USD_PER_MILLION: 0.01,
    OPENAI_CACHE_WRITE_USD_PER_MILLION: 0.125,
    OPENAI_OUTPUT_USD_PER_MILLION: 0.5,
    OPENAI_WEEKLY_INPUT_USD_PER_MILLION: 2,
    OPENAI_WEEKLY_CACHED_INPUT_USD_PER_MILLION: 0.2,
    OPENAI_WEEKLY_CACHE_WRITE_USD_PER_MILLION: 2.5,
    OPENAI_WEEKLY_OUTPUT_USD_PER_MILLION: 10,
    OPENAI_LONG_CONTEXT_THRESHOLD_TOKENS: 2_000_000,
    OPENAI_WEB_SEARCH_USD_PER_CALL: 0.01,
  };
  assert.equal(responseCost(response, config), 0.181);
});

test("response cost uses Sol rates for the weekly model", () => {
  const response = {
    model: "gpt-6-sol",
    usage: { input_tokens: 1_000_000, output_tokens: 100_000 },
    output: [],
  };
  const config = {
    OPENAI_WEEKLY_MODEL: "gpt-6-sol",
    OPENAI_FALLBACK_MODEL: "gpt-6-sol",
    OPENAI_INPUT_USD_PER_MILLION: 0.1,
    OPENAI_OUTPUT_USD_PER_MILLION: 0.5,
    OPENAI_WEEKLY_INPUT_USD_PER_MILLION: 2,
    OPENAI_WEEKLY_OUTPUT_USD_PER_MILLION: 10,
    OPENAI_LONG_CONTEXT_THRESHOLD_TOKENS: 2_000_000,
    OPENAI_WEB_SEARCH_USD_PER_CALL: 0.01,
  };
  assert.equal(responseCost(response, config), 3);
});

test("response cost applies long-context multipliers", () => {
  const response = {
    model: "gpt-6-luna",
    usage: {
      input_tokens: 300_000,
      input_tokens_details: { cache_write_tokens: 300_000, cached_tokens: 0 },
      output_tokens: 100_000,
    },
    output: [],
  };
  const config = {
    OPENAI_WEEKLY_MODEL: "gpt-6-sol",
    OPENAI_FALLBACK_MODEL: "gpt-6-sol",
    OPENAI_INPUT_USD_PER_MILLION: 0.1,
    OPENAI_CACHED_INPUT_USD_PER_MILLION: 0.01,
    OPENAI_CACHE_WRITE_USD_PER_MILLION: 0.125,
    OPENAI_OUTPUT_USD_PER_MILLION: 0.5,
    OPENAI_LONG_CONTEXT_THRESHOLD_TOKENS: 272_000,
    OPENAI_LONG_CONTEXT_INPUT_MULTIPLIER: 2,
    OPENAI_LONG_CONTEXT_OUTPUT_MULTIPLIER: 1.5,
    OPENAI_WEB_SEARCH_USD_PER_CALL: 0.01,
  };
  assert.equal(responseCost(response, config), 0.15);
});

test("AI decision context summarizes raw events and bounds historical records", () => {
  const context = buildAiDecisionContext({
    events_30d: Array.from({ length: 100 }, (_, index) => ({ event_name: index % 2 ? "signup" : "install", occurred_at: `2026-09-${String((index % 9) + 10).padStart(2, "0")}` })),
    events_7d: [{ event_name: "signup" }, { event_name: "signup" }],
    content: Array.from({ length: 50 }, (_, index) => ({ id: `content-${index}`, status: "planned", decision: { content: { title: `Idea ${index}` } } })),
    publications: Array.from({ length: 50 }, (_, index) => ({ id: `publication-${index}` })),
    learnings: Array.from({ length: 50 }, (_, index) => ({ id: `learning-${index}` })),
    costs: [{ provider: "openai", status: "settled", actual_cost_usd: 1.25 }],
  });
  assert.equal(context.events_30d.find((item) => item.event_name === "signup").count, 50);
  assert.equal(context.events_7d.find((item) => item.event_name === "signup").count, 2);
  assert.equal(context.recent_content.length, 21);
  assert.equal(context.creative_memory.length, 50);
  assert.equal(context.creative_intelligence.sample_size, 50);
  assert.equal(context.recent_publications.length, 16);
  assert.equal(context.learnings.length, 10);
  assert.deepEqual(context.costs, [{ provider: "openai", status: "settled", entries: 1, usd: 1.25 }]);
});

test("compacted AI context retains first-party Buffer performance", () => {
  const compacted = compactContext(buildAiDecisionContext({
    buffer: {
      status: "ok",
      posts_analyzed: 100,
      benchmark_posts: [{ id: "buffer-post-1", platform: "tiktok", metrics: { views: 91 } }],
    },
  }));

  assert.match(compacted, /"buffer"/);
  assert.match(compacted, /buffer-post-1/);
  assert.match(compacted, /"views":91/);
});

test("long planning history cannot push live performance out of the model context", () => {
  const context = buildAiDecisionContext({
    buffer: { status: "ok", benchmark_posts: [{ id: "current-benchmark", metrics: { views: 170 } }] },
    ga4: { status: "ok", sessions: 123 },
    learnings: Array.from({ length: 20 }, () => ({ pattern: "x".repeat(2000), recommended_action: "y".repeat(2000) })),
    content: Array.from({ length: 30 }, (_, index) => ({ id: `c${index}`, failure_reason: "z".repeat(2000) })),
  });
  const compacted = compactContext(context, 24000);
  assert.match(compacted, /current-benchmark/);
  assert.match(compacted, /views/);
  assert.match(compacted, /170/);
  assert.match(compacted, /sessions/);
  assert.match(compacted, /123/);
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
      format: "carousel",
      hook: "Four signs your plan is guessing",
      creative_direction: { layout_style: "checklist", visual_world: "clean charcoal checklist cards with green ticks" },
      slides: [
        { visual_type: "human_lifestyle", screenshot_ref: "", headline: "Four signs your plan is guessing" },
        { visual_type: "product_screenshot", screenshot_ref: "curated/screen.png" },
        { visual_type: "branded_graphic", screenshot_ref: "" },
        { visual_type: "branded_graphic", screenshot_ref: "" },
      ],
    },
    post: {
      format: "image",
      hook: "Your rest day deserves a reason",
      creative_direction: { layout_style: "bold_typography", visual_world: "oversized white type on deep black" },
      slides: [{ visual_type: "branded_graphic", screenshot_ref: "", headline: "Your rest day deserves a reason" }],
    },
  };

  assert.equal(validateCreativeDecision(research, decision), decision);
  assert.throws(
    () => validateCreativeDecision(research, { ...decision, post: { ...decision.post, slides: [...decision.post.slides, decision.post.slides[0]] } }),
    /exactly one slide/,
  );
  assert.throws(
    () => validateCreativeDecision(research, { ...decision, post: { ...decision.post, creative_direction: decision.instagram.creative_direction } }),
    /different layout styles/,
  );
  assert.throws(
    () => validateCreativeDecision(research, { ...decision, post: { ...decision.post, hook: decision.instagram.hook,
      slides: [{ ...decision.post.slides[0], headline: decision.instagram.slides[0].headline }] } }),
    /same hook/,
  );
  const signature = {
    format_family: "creator_ugc", setting_family: "gym_floor", visual_mode: "human_led",
    camera_language: "handheld selfie camera in a moody gym", performance_style: "candid reaction with a confession",
  };
  const repeated = { ...decision, video: { ...decision.video, creative_treatment: { ...decision.video.creative_treatment, ...signature } } };
  assert.throws(
    () => validateCreativeDecision(research, repeated, { creativeMemory: [{ content_type: "video", creative_signature: signature }] }),
    /repeats too many creative axes/,
  );
  const fresh = { ...repeated, video: { ...repeated.video, creative_treatment: { ...repeated.video.creative_treatment,
    format_family: "observational_story", setting_family: "kitchen", camera_language: "locked-off wide over the counter at dawn" } } };
  assert.equal(validateCreativeDecision(research, fresh, { creativeMemory: [{ content_type: "video", creative_signature: signature }] }), fresh);
  assert.throws(
    () => validateCreativeDecision(research, decision, { creativeMemory: [{ content_type: "image",
      creative_signature: { layout_style: "bold_typography", visual_world: "oversized white type on deep black" } }] }),
    /repeats the most recent image/,
  );
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

test("final QA receives the saved evidence cited by the approved asset", () => {
  const evidence = researchEvidenceForQa({
    decision: {
      content: { review_brief: { rationale: "GFTR-20260924-05 supports the concise treatment." } },
      research: {
        summary: "Bounded research",
        trends: [
          { evidence_id: "GFTR-20260924-04", metrics: [{ name: "views", value: 10 }] },
          { evidence_id: "GFTR-20260924-05", metrics: [{ name: "retention", value: 9.253 }], source_urls: ["https://example.test/evidence"] },
        ],
        gaps: ["No conversion attribution"],
      },
    },
  });
  assert.deepEqual(evidence.cited_evidence_ids, ["GFTR-20260924-05"]);
  assert.equal(evidence.evidence[0].evidence_id, "GFTR-20260924-05");
  assert.deepEqual(evidence.missing_evidence_ids, []);
  assert.deepEqual(evidence.limitations, ["No conversion attribution"]);
});
