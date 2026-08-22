import { z } from "zod";

const SourceUrl = z.string().url();

export const DailyDecisionSchema = z.object({
  research_summary: z.string().min(30),
  trends: z.array(z.object({
    topic: z.string().min(3),
    why_now: z.string().min(10),
    audience_fit: z.string().min(10),
    source_urls: z.array(SourceUrl).min(1).max(6),
    confidence: z.number().min(0).max(1),
  })).min(1).max(8),
  decision_rationale: z.string().min(30),
  video: z.object({
    topic: z.string().min(3),
    concept: z.string().min(20),
    hook: z.string().min(5),
    target_audience: z.string().min(5),
    scenes: z.array(z.object({
      duration_seconds: z.number().int().min(4).max(15),
      camera: z.string().min(3),
      subject: z.string().min(3),
      action: z.string().min(3),
      environment: z.string().min(3),
      lighting: z.string().min(3),
      visual_style: z.string().min(3),
      spoken_dialogue: z.string(),
      ambient_audio: z.string(),
    })).length(1),
    audio_mode: z.enum(["native_audio", "ai_voiceover", "music_only", "ambient_plus_captions", "silent"]),
    voiceover_script: z.string(),
    captions_enabled: z.boolean(),
    caption_text: z.array(z.string()).max(12),
    cta: z.string(),
    platform_copy: z.object({
      instagram_caption: z.string(),
      tiktok_caption: z.string(),
      youtube_title: z.string().max(100),
      youtube_description: z.string(),
      hashtags: z.array(z.string()).max(15),
    }),
  }),
  instagram: z.object({
    format: z.enum(["image", "carousel"]),
    topic: z.string().min(3),
    concept: z.string().min(20),
    hook: z.string().min(5),
    caption: z.string(),
    cta: z.string(),
    hashtags: z.array(z.string()).max(15),
    slides: z.array(z.object({
      headline: z.string().min(2).max(90),
      body: z.string().max(280),
      visual_prompt: z.string().min(15),
    })).min(1).max(7),
  }),
  experiment: z.object({
    hypothesis: z.string().min(10),
    variable: z.string().min(3),
    success_metric: z.string().min(3),
  }),
  risk_flags: z.array(z.string()).max(10),
});

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

export function minimumQaScore(review) {
  return Math.min(...Object.values(review.scores));
}
