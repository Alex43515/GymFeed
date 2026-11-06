import { z } from "zod";

const Platform = z.enum(["instagram", "tiktok"]);

export const CandidateListSchema = z.object({
  candidates: z.array(z.object({
    name: z.string(),
    platform: Platform,
    handle: z.string(),
    profile_url: z.string(),
    other_profiles: z.array(z.object({ platform: Platform, handle: z.string() })),
    email: z.string().nullable(),
    followers_estimate: z.number().int().nullable(),
    market: z.enum(["international", "balkan"]),
    language: z.string(),
    content_summary: z.string(),
    evidence_urls: z.array(z.string()),
  })),
  search_notes: z.string(),
});

export const QualificationSchema = z.object({
  results: z.array(z.object({
    handle: z.string(),
    fit_score: z.number().int().min(0).max(100),
    tier: z.enum(["starter", "partner", "face"]),
    reject_reason: z.string().nullable(),
    why_fit: z.string(),
    first_message: z.string(),
  })),
});

export const ReplyDecisionSchema = z.object({
  reply: z.string(),
  should_send: z.boolean(),
  stage: z.enum(["interested", "questions", "accepted", "declined", "needs_owner", "not_relevant"]),
  accepted: z.boolean(),
  handoff: z.boolean(),
  handoff_reason: z.string().nullable(),
  summary: z.string(),
  next_step_for_owner: z.string().nullable(),
  collected_email: z.string().nullable(),
});
