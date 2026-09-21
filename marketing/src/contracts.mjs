import { z } from "zod";

// OpenAI Structured Outputs does not accept JSON Schema's `format: uri`.
// Keep the field constrained here and verify URL reachability during research review.
const SourceUrl = z.string().min(8);
export const GymFeedFeatureSchema = z.enum([
  "connected_ecosystem",
  "starter_plan",
  "home_feed",
  "fitclips",
  "ai_coach",
  "train",
  "scan_food",
  "scan_equipment",
  "nutrition_diary",
  "body_scan",
  "progress",
  "events",
  "messages",
]);
const ApprovedCtaSchema = z.enum([
  "Get started with GymFeed",
  "Build my 28-day plan",
  "Open Coach",
  "Start today's workout",
  "Scan and log a meal",
  "Find a training event",
  "Share your progress",
  "Unlock GymFeed Pro",
]);

const QuantifiedTrendMetricSchema = z.object({
  name: z.enum([
    "views",
    "reach",
    "likes",
    "reactions",
    "comments",
    "shares",
    "saves",
    "average_watch_time",
    "retention",
    "search_interest",
    "other",
  ]),
  value: z.number().nonnegative(),
  unit: z.enum(["count", "percentage", "seconds", "index"]),
  measurement_window: z.string().min(3),
});

const TrendEvidenceSchema = z.object({
  evidence_id: z.string().min(3).max(40),
  platform: z.enum(["instagram", "tiktok", "youtube", "google_trends", "cross_platform"]),
  topic: z.string().min(3),
  format: z.string().min(3),
  observed_at: z.string().min(4),
  why_now: z.string().min(10),
  audience_fit: z.string().min(10),
  hook_pattern: z.string().min(5),
  visual_pattern: z.string().min(10),
  people_role: z.enum(["none", "primary", "supporting", "unknown"]),
  metrics: z.array(QuantifiedTrendMetricSchema).max(10),
  transferable_principle: z.string().min(10),
  source_urls: z.array(SourceUrl).min(1).max(6),
  evidence_grade: z.enum(["primary", "secondary", "weak"]),
  confidence: z.number().min(0).max(1),
});

export const TrendResearchSchema = z.object({
  research_summary: z.string().min(30),
  trends: z.array(TrendEvidenceSchema).max(10),
  research_gaps: z.array(z.string()).max(10),
});

const CandidateConceptSchema = z.object({
  name: z.string().min(3).max(100),
  concept: z.string().min(20).max(500),
  content_mode: z.enum([
    "human_story",
    "human_demonstration",
    "product_demonstration",
    "food_demonstration",
    "equipment_demonstration",
    "community_story",
    "hybrid",
  ]),
  evidence_ids: z.array(z.string()).max(8),
  hook: z.string().min(5).max(160),
  gymfeed_proof: z.string().min(10).max(240),
  scores: z.object({
    evidence_strength: z.number().int().min(0).max(100),
    audience_fit: z.number().int().min(0).max(100),
    product_fit: z.number().int().min(0).max(100),
    attention_potential: z.number().int().min(0).max(100),
    conversion_potential: z.number().int().min(0).max(100),
    production_feasibility: z.number().int().min(0).max(100),
  }),
  weighted_score: z.number().min(0).max(100),
  selection_note: z.string().min(10),
});

const CreativeTreatmentSchema = z.object({
  visual_mode: z.enum(["human_led", "hybrid", "product_led"]),
  opening_asset: z.enum(["fal_video", "gymfeed_screenshot", "app_capture"]),
  people_role: z.enum(["none", "primary", "supporting"]),
  people_screen_time_percent: z.number().int().min(0).max(100),
  product_screen_time_percent: z.number().int().min(0).max(100),
  hook_pattern: z.string().min(5),
  pacing_pattern: z.string().min(5),
  evidence_ids: z.array(z.string()).max(8),
  why_this_treatment: z.string().min(20),
});

const ReviewBriefSchema = z.object({
  title: z.string().min(5).max(120),
  objective: z.string().min(10).max(300),
  description: z.string().min(20).max(1000),
  rationale: z.string().min(20).max(600),
  production_requirements: z.array(z.string().min(5).max(300)).max(12),
});

export const VideoPlanSchema = z.object({
  production_version: z.literal(2),
  review_brief: ReviewBriefSchema,
  product_feature: GymFeedFeatureSchema,
  feature_sequence: z.array(GymFeedFeatureSchema).min(1).max(4),
  product_promise: z.string().min(10).max(160),
  proof_points: z.array(z.string().min(5).max(180)).min(1).max(4),
  screenshot_refs: z.array(z.string()).max(5),
  topic: z.string().min(3),
  concept: z.string().min(20),
  hook: z.string().min(5),
  target_audience: z.string().min(5),
  creative_treatment: CreativeTreatmentSchema,
  target_duration_seconds: z.number().min(15).max(30),
  reviewer_instruction_map: z.array(z.object({
    instruction: z.string().min(3),
    scene_ids: z.array(z.string()).min(1),
    implemented_change: z.string().min(10),
  })).max(12),
  character_reference: z.object({
    required: z.boolean(),
    description: z.string().min(5),
    wardrobe: z.string().min(3),
    environment_anchor: z.string().min(3),
    continuity_rules: z.array(z.string().min(3)).min(1).max(8),
  }),
  scenes: z.array(z.object({
    scene_id: z.string().min(2).max(30),
    asset_type: z.enum(["generated_video", "gymfeed_screen", "app_capture"]),
    purpose: z.enum(["hook", "problem", "action", "product_proof", "payoff", "cta"]),
    source_duration_seconds: z.number().min(0).max(300),
    source_start_seconds: z.number().min(0).max(300),
    duration_seconds: z.number().min(1.5).max(10),
    camera: z.string().min(3),
    subject: z.string().min(3),
    action: z.string().min(3),
    environment: z.string().min(3),
    lighting: z.string().min(3),
    visual_style: z.string().min(3),
    continuity_notes: z.string().min(3),
    overlay_text: z.string().max(90),
    screenshot_ref: z.string(),
    capture_ref: z.string(),
    spoken_dialogue: z.string(),
    ambient_audio: z.string(),
    audio_strategy: z.enum(["native", "voiceover", "ambient", "silent"]),
    voiceover_text: z.string().max(300),
  })).min(3).max(8),
  audio_mode: z.enum(["mixed", "native_audio", "ai_voiceover", "music_only", "ambient_plus_captions", "silent"]),
  voiceover_script: z.string(),
  captions_enabled: z.boolean(),
  caption_text: z.array(z.string()).max(12),
  cta: ApprovedCtaSchema,
  landing_url: z.literal("https://gymfeed.io"),
  platform_copy: z.object({
    instagram_caption: z.string(),
    tiktok_caption: z.string(),
    youtube_title: z.string().max(100),
    youtube_description: z.string(),
    hashtags: z.array(z.string()).max(15),
  }),
});

export const InstagramPlanSchema = z.object({
  review_brief: ReviewBriefSchema,
  target_audience: z.string().min(5),
  product_features: z.array(GymFeedFeatureSchema).min(1).max(5),
  proof_points: z.array(z.string().min(5).max(180)).min(1).max(6),
  screenshot_refs: z.array(z.string()).max(7),
  format: z.enum(["image", "carousel"]),
  topic: z.string().min(3),
  concept: z.string().min(20),
  hook: z.string().min(5),
  caption: z.string(),
  cta: ApprovedCtaSchema,
  landing_url: z.literal("https://gymfeed.io"),
  hashtags: z.array(z.string()).max(15),
  slides: z.array(z.object({
    headline: z.string().min(2).max(90),
    body: z.string().max(280),
    visual_prompt: z.string().min(15),
    visual_type: z.enum(["product_screenshot", "human_lifestyle", "food", "equipment", "community", "branded_graphic"]),
    feature: GymFeedFeatureSchema,
    screenshot_ref: z.string(),
  })).min(1).max(7),
});

export const CreativeDecisionSchema = z.object({
  candidate_concepts: z.array(CandidateConceptSchema).length(3),
  selected_strategy: z.object({
    candidate_name: z.string().min(3),
    why_it_won: z.string().min(20),
    primary_success_metric: z.enum([
      "paid_conversion",
      "product_activation",
      "registration",
      "qualified_traffic",
      "shares",
      "saves",
      "watch_time",
      "views",
    ]),
  }),
  decision_rationale: z.string().min(30),
  video: VideoPlanSchema,
  instagram: InstagramPlanSchema,
  experiment: z.object({
    hypothesis: z.string().min(10),
    variable: z.string().min(3),
    success_metric: z.string().min(3),
  }),
  risk_flags: z.array(z.string()).max(10),
});

export const DailyDecisionSchema = TrendResearchSchema.merge(CreativeDecisionSchema);

export const QualityReviewSchema = z.object({
  publish: z.boolean(),
  scores: z.object({
    brand_fit: z.number().int().min(0).max(100),
    visual_quality: z.number().int().min(0).max(100),
    hook_quality: z.number().int().min(0).max(100),
    factual_confidence: z.number().int().min(0).max(100),
    platform_fit: z.number().int().min(0).max(100),
    conversion_potential: z.number().int().min(0).max(100),
  }),
  critical_issues: z.array(z.string()),
  required_fixes: z.array(z.string()),
  summary: z.string().min(10),
});

export const SceneQualityReviewSchema = z.object({
  accept: z.boolean(),
  scores: z.object({
    human_realism: z.number().int().min(0).max(100),
    anatomy_and_hands: z.number().int().min(0).max(100),
    motion_continuity: z.number().int().min(0).max(100),
    identity_continuity: z.number().int().min(0).max(100),
    scene_match: z.number().int().min(0).max(100),
    brand_safety: z.number().int().min(0).max(100),
  }),
  defects: z.array(z.string()),
  required_fixes: z.array(z.string()),
  retry_prompt: z.string(),
  summary: z.string().min(10),
});

export const WeeklyReviewSchema = z.object({
  executive_summary: z.string().min(30),
  findings: z.array(z.object({
    pattern: z.string().min(10),
    supporting_evidence: z.array(z.string()).min(1),
    sample_size: z.number().int().nonnegative(),
    confidence: z.number().min(0).max(1),
    recommended_action: z.string().min(5),
    more_testing_required: z.boolean(),
    status: z.enum(["hypothesis", "validated", "disproven", "retired"]),
  })).max(20),
  next_week_mix: z.object({
    repeat_winners_percent: z.number().min(0).max(80),
    iteration_percent: z.number().min(0).max(80),
    experiment_percent: z.number().min(20).max(100),
  }),
  content_changes: z.array(z.string()),
  research_priorities: z.array(z.string()),
  budget_changes: z.array(z.string()),
});

export function overallQaScore(review) {
  const scores = Object.values(review.scores);
  return Math.round(scores.reduce((total, score) => total + score, 0) / scores.length);
}
