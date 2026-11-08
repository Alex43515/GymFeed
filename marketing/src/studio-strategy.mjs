import { z } from "zod";
export const STUDIO_SOURCES = [
  { title: "ReStructure — one-person marketing team", url: "https://restructure-europe.vercel.app/en/newsletter/marketing-team/", use: "Department coverage and owner handoff; a reference architecture, not verified performance." },
  { title: "TikTok — creative advertising guide", url: "https://ads.tiktok.com/business/en/guides/what-is-ad-creative-guide", use: "Native creative, opening attention, clear story, captions and testable variation." },
  { title: "Anthropic — building effective agents", url: "https://www.anthropic.com/research/building-effective-agents", use: "Explicit research, creation and evaluation stages with measurable checks." },
  { title: "n8n — error handling", url: "https://docs.n8n.io/flow-logic/error-handling/", use: "Shared error workflow, execution context and visible recovery." },
];
export const CMO_OPERATING_SYSTEM = `GYMFEED CMO OPERATING SYSTEM v4
Start from observed audience friction and first-party business outcomes. Product features are proof, not the default plot.
Read creative_intelligence before ideation. Identify saturated premises, hooks, settings and features. Do not repeat a plot by swapping the feature, room, actress or a few words.
Compare three concept lanes: a recognizable human tension, an original demonstration/experiment, and a culturally relevant observation grounded in dated sources. Respect schema content modes. Each must differ in premise, narrative structure, opening action and payoff.
Separate observed facts, uncertain interpretation and proposed experiment. Cite actual supplied evidence IDs. Missing information is unavailable, never zero. A trend is not proof of GymFeed conversion.
In each candidate selection_note explain novelty against the archive, expected failure mode and why it wins or loses. Feasibility alone cannot make an overused format win.
Plan opening visual, performance, audio and payoff together. Spoken lines must fit unhurried human delivery. Continuity and authentic product proof are part of the concept.
Possible narrative shapes include a decision, an investigation, a social interaction, a useful experiment, a counterargument and a challenge with a visible outcome. These are options, not a mandatory recurring template.
The daily video, carousel and image must be independently useful, not three versions of one script. Balance discovery, consideration and activation across the week.
In existing experiment fields identify a control, one changed variable, metric, denominator and observation window. Preserve uncertainty for tiny samples. QA scores measure execution, not market demand.
Reserve exploration when outcome evidence is weak. Scheduling an idea does not make it a winner.
Respect owner briefs and verified GymFeed capabilities. Never invent testimonials, app screens, sales, sources, customer messages or analytics. Communications remain drafts until delivery is authorized.`;
export const StudioBriefSchema = z.object({ title: z.string(), summary: z.string(),
  items: z.array(z.object({ title: z.string(), body: z.string(), channel: z.string(), objective: z.string(), success_metric: z.string() })).min(1).max(8),
  source_notes: z.array(z.string()), next_actions: z.array(z.string()), limitations: z.array(z.string()) });
export const STUDIO_DEPARTMENTS = {
  research: { title: "Research & strategy", instruction: "Create an audience/research brief with three distinct testable territories. Use supplied sources and performance. Never fabricate current research. Identify questions requiring new web research." },
  creative: { title: "Creative studio", instruction: "Develop three distinct video treatments: opening visual, spoken hook, beats, real product proof, audio, continuity, payoff and risks. Avoid recent plot patterns." },
  community: { title: "Distribution & community", instruction: "Draft channel-native copy and a comment/DM triage playbook, marking human handoffs. Do not invent received comments or send anything." },
  analytics: { title: "Analytics & learning", instruction: "Analyze events, publications and costs. Separate observation, hypothesis and missing data. Propose experiments and measurement windows. Never attribute aggregate signups to an individual post." },
  email: { title: "Email & nurture", instruction: "Draft an opt-in onboarding/reactivation sequence: subjects, bodies, CTA and entry/exit conditions. Delivery requires a connected email provider, consent and owner approval." },
  sales: { title: "Leads & partnerships", instruction: "Draft a GymFeed creator/partner qualification and follow-up plan. Distinguish app subscription conversion from agency sales calls. Never invent contacts, send messages, book calls or create payment links." },
  seo: { title: "Search & website", instruction: "Draft an original search-intent brief and gymfeed.io article or landing-page outline: reader problem, proof, internal links and conversion. Search volumes and rankings are unknown unless supplied." },
};
