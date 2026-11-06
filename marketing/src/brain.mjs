import OpenAI from "openai";
import { creativeIntelligence, assertFreshHooks, attributionSummary } from "./creative-intelligence.mjs";
import { CMO_OPERATING_SYSTEM, StudioBriefSchema, STUDIO_DEPARTMENTS } from "./studio-strategy.mjs";
import { zodTextFormat } from "openai/helpers/zod";
import { VideoAssetRevisionSchema, VIDEO_ASSET_REVISION_PROMPT, applyVideoRevision } from "./video-revisions.mjs";
import { CreativeDecisionSchema, InstagramPlanSchema, LibraryCaptureDescriptionSchema, QualityReviewSchema, SceneQualityReviewSchema, StoryReviewSchema, TrendResearchSchema, VideoPlanSchema, WeeklyReviewSchema } from "./contracts.mjs";
import { CONTENT_REVISION_PROMPT, DAILY_BRAIN_PROMPT, LIBRARY_CAPTURE_PROMPT, QA_PROMPT, SCENE_QA_PROMPT, STORY_REVIEW_PROMPT, VIDEO_PRODUCTION_DIRECTION, TREND_RESEARCH_PROMPT, WEEKLY_CMO_PROMPT } from "./prompts.mjs";
import { validateVideoStory } from "./video-story.mjs";
import { ContinuityLayoutSchema, CONTINUITY_DIRECTOR_PROMPT } from "./production-continuity.mjs";
import { libraryCatalog, libraryCoverage } from "./asset-library.mjs";
import { loadProductBrief, referenceScreenshotCatalog, verifiedScreenshotManifest } from "./product-brief.mjs";

function compactValue(value, depth = 0, { arrayLimit = 12, stringLimit = 1200, depthLimit = 5 } = {}) {
  if (typeof value === "string") return value.length > stringLimit ? `${value.slice(0, stringLimit)}...` : value;
  if (value === null || typeof value !== "object") return value;
  if (Buffer.isBuffer(value)) return `[binary buffer: ${value.length} bytes]`;
  if (depth >= depthLimit) return Array.isArray(value) ? `[${value.length} items]` : "[object omitted]";
  if (Array.isArray(value)) return value.slice(0, arrayLimit).map((item) => compactValue(item, depth + 1, { arrayLimit, stringLimit, depthLimit }));
  return Object.fromEntries(Object.entries(value)
    .filter(([key]) => !["raw", "input", "output"].includes(key))
    .map(([key, item]) => [key, compactValue(item, depth + 1, { arrayLimit, stringLimit, depthLimit })]));
}

export function compactContext(context, maxChars = 30000) {
  const compacted = JSON.stringify(compactValue(context)) ?? "null";
  if (compacted.length <= maxChars) return compacted;
  return JSON.stringify({ truncated: true, context_excerpt: compacted.slice(0, maxChars - 80) });
}

function eventSummary(events = []) {
  const summary = new Map();
  for (const event of events) {
    const name = event.event_name ?? event.name ?? "unknown";
    const current = summary.get(name) ?? { event_name: name, count: 0, latest_at: null };
    current.count += Number(event.event_count ?? event.count ?? 1);
    const occurredAt = event.occurred_at ?? event.created_at ?? null;
    if (occurredAt && (!current.latest_at || occurredAt > current.latest_at)) current.latest_at = occurredAt;
    summary.set(name, current);
  }
  return [...summary.values()].sort((left, right) => right.count - left.count).slice(0, 30);
}

function contentSnapshot(content) {
  const plan = content.decision?.content ?? content.content ?? {};
  const generatedScenes = (plan.scenes ?? []).filter((scene) => scene.asset_type === "generated_video");
  return {
    id: content.id,
    content_key: content.content_key,
    content_type: content.content_type,
    status: content.status,
    qa_score: content.qa_score,
    created_at: content.created_at,
    scheduled_for: content.scheduled_for,
    published_at: content.published_at,
    title: plan.title ?? plan.name,
    hook: plan.hook,
    objective: plan.objective,
    caption: typeof plan.caption === "string" ? plan.caption.slice(0, 500) : undefined,
    product_feature: plan.product_feature ?? plan.product_features,
    creative_signature: content.content_type === "video" ? {
      format_family: plan.creative_treatment?.format_family ?? plan.narrative?.format,
      setting_family: plan.creative_treatment?.setting_family,
      visual_mode: plan.creative_treatment?.visual_mode,
      hook_pattern: plan.creative_treatment?.hook_pattern,
      cast_count: plan.cast?.length ?? 0,
      opening_environment: generatedScenes[0]?.environment,
      camera_language: plan.creative_treatment?.camera_language ?? generatedScenes.map((scene) => scene.camera).join("; "),
      performance_style: plan.creative_treatment?.performance_style,
    } : {
      format: plan.format ?? content.content_type,
      layout_style: plan.creative_direction?.layout_style,
      visual_world: plan.creative_direction?.visual_world,
      visual_types: (plan.slides ?? []).map((slide) => slide.visual_type),
    },
    campaign: content.decision?.campaign ? compactValue(content.decision.campaign, 0, { arrayLimit: 5, stringLimit: 500, depthLimit: 3 }) : undefined,
    failure_reason: content.failure_reason,
  };
}

export function researchEvidenceForQa(content) {
  const decision = content.decision ?? {};
  const research = decision.research ?? {};
  const selected = (decision.candidate_concepts ?? []).find(
    (candidate) => candidate.name === decision.selected_strategy?.candidate_name,
  );
  const cited = new Set([
    ...(selected?.evidence_ids ?? []),
    ...(decision.content?.creative_treatment?.evidence_ids ?? []),
    ...((JSON.stringify({
      review_brief: decision.content?.review_brief,
      rationale: decision.rationale,
    }).match(/GFTR-[A-Z0-9-]+/g)) ?? []),
  ]);
  const evidence = (research.trends ?? []).filter((trend) => cited.has(trend.evidence_id));
  const found = new Set(evidence.map((trend) => trend.evidence_id));
  return {
    summary: research.summary ?? "",
    cited_evidence_ids: [...cited],
    evidence,
    missing_evidence_ids: [...cited].filter((id) => !found.has(id)),
    limitations: research.gaps ?? [],
  };
}

function costSummary(costs = []) {
  const grouped = new Map();
  for (const cost of costs) {
    const key = `${cost.provider ?? "unknown"}:${cost.status ?? "unknown"}`;
    const current = grouped.get(key) ?? { provider: cost.provider ?? "unknown", status: cost.status ?? "unknown", entries: 0, usd: 0 };
    current.entries += 1;
    current.usd += Number(cost.actual_cost_usd ?? cost.estimated_cost_usd ?? 0);
    grouped.set(key, current);
  }
  return [...grouped.values()].map((item) => ({ ...item, usd: Number(item.usd.toFixed(4)) }));
}

export function buildAiDecisionContext(context, { weekly = false } = {}) {
  const masters = (context.content ?? []).filter(item => !item.master_content_id);
  const recentContent = masters.slice(0, weekly ? 30 : 21).map(contentSnapshot);
  const creativeArchive = masters.slice(0, weekly ? 90 : 60).map(contentSnapshot);
  return {
    buffer: compactValue(context.buffer, 0, { arrayLimit: weekly ? 12 : 6, stringLimit: 600, depthLimit: 6 }),
    ga4: compactValue(context.ga4, 0, { arrayLimit: weekly ? 20 : 10, stringLimit: 600, depthLimit: 5 }),
    events_30d: eventSummary(context.events_30d),
    events_7d: eventSummary(context.events_7d),
    costs: costSummary(context.costs),
    attribution_30d: attributionSummary(context.events_30d),
    recent_publications: (context.publications ?? []).slice(0, weekly ? 40 : 16).map((item) => compactValue(item, 0, { arrayLimit: 6, stringLimit: 500, depthLimit: 4 })),
    brand: compactValue(context.brand, 0, { arrayLimit: 8, stringLimit: 700, depthLimit: 4 }),
    learnings: (context.learnings ?? []).slice(0, weekly ? 20 : 10).map((item) => compactValue(item, 0, { arrayLimit: 6, stringLimit: 700, depthLimit: 4 })),
    recent_content: recentContent,
    creative_memory: creativeArchive.map((item) => ({
      id: item.id,
      content_type: item.content_type,
      status: item.status,
      hook: item.hook,
      product_feature: item.product_feature,
      creative_signature: item.creative_signature,
      qa_score: item.qa_score,
      failure_reason: item.failure_reason,
    })),
    creative_intelligence: creativeIntelligence(context.content, context.publications, context.events_30d),
    campaign: compactValue(context.campaign, 0, { arrayLimit: 12, stringLimit: 700, depthLimit: 5 }),
  };
}

function captureSnapshot(capture) {
  return {
    id: capture.id,
    capture_ref: capture.capture_ref,
    filename: capture.filename,
    verified: capture.verified,
    duration_seconds: capture.duration_seconds,
    recorded_interactions: (capture.recorded_interactions ?? []).slice(0, 12),
  };
}

function modelMatches(actual, configured) {
  return Boolean(actual && configured && (actual === configured || actual.startsWith(`${configured}-`)));
}

function supportsExplicitCaching(model = "") {
  return /^gpt-(?:6|[7-9])(?:[.-]|$)/.test(model) || /^gpt-5\.(?:[6-9]|\d{2,})(?:[.-]|$)/.test(model);
}

function cacheConfiguration(model) {
  return supportsExplicitCaching(model) ? { prompt_cache_options: { mode: "explicit", ttl: "30m" } } : {};
}

function systemInstructions(prompt, stableReference = "", cache = false) {
  const block = {
    type: "input_text",
    text: stableReference ? `${prompt}\n\nAUTHORITATIVE GYMFEED PRODUCT BRIEF:\n${stableReference}` : prompt,
  };
  if (cache) block.prompt_cache_breakpoint = { mode: "explicit" };
  return { role: "system", content: [block] };
}

function attachBilledUsage(error, responses, config) {
  const completed = responses.filter(Boolean);
  if (!completed.length) return error;
  error.openaiCostUsd = Number(completed.reduce((sum, response) => sum + responseCost(response, config), 0).toFixed(6));
  error.openaiResponseId = completed.map((response) => response.id).filter(Boolean).join(",") || null;
  return error;
}

export function responseCost(response, config) {
  if (modelMatches(response.model, "gpt-6-astra")) {
    config = { ...config, OPENAI_WEEKLY_MODEL: "gpt-6-astra", OPENAI_WEEKLY_INPUT_USD_PER_MILLION: 10,
      OPENAI_WEEKLY_CACHED_INPUT_USD_PER_MILLION: 1, OPENAI_WEEKLY_CACHE_WRITE_USD_PER_MILLION: 12.5,
      OPENAI_WEEKLY_OUTPUT_USD_PER_MILLION: 50 };
  }
  const input = response.usage?.input_tokens ?? 0;
  const output = response.usage?.output_tokens ?? 0;
  const details = response.usage?.input_tokens_details ?? {};
  const cacheWrite = Math.min(input, details.cache_write_tokens ?? 0);
  const cached = Math.min(input - cacheWrite, details.cached_tokens ?? 0);
  const uncached = Math.max(0, input - cacheWrite - cached);
  const searches = response.output?.filter((item) => item.type === "web_search_call").length ?? 0;
  const isWeeklyModel = modelMatches(response.model, config.OPENAI_WEEKLY_MODEL)
    || modelMatches(response.model, config.OPENAI_FALLBACK_MODEL);
  const inputRate = isWeeklyModel
    ? config.OPENAI_WEEKLY_INPUT_USD_PER_MILLION
    : config.OPENAI_INPUT_USD_PER_MILLION;
  const cachedRate = isWeeklyModel
    ? config.OPENAI_WEEKLY_CACHED_INPUT_USD_PER_MILLION ?? inputRate
    : config.OPENAI_CACHED_INPUT_USD_PER_MILLION ?? inputRate;
  const cacheWriteRate = isWeeklyModel
    ? config.OPENAI_WEEKLY_CACHE_WRITE_USD_PER_MILLION ?? inputRate
    : config.OPENAI_CACHE_WRITE_USD_PER_MILLION ?? inputRate;
  const outputRate = isWeeklyModel
    ? config.OPENAI_WEEKLY_OUTPUT_USD_PER_MILLION
    : config.OPENAI_OUTPUT_USD_PER_MILLION;
  const longContext = input > (config.OPENAI_LONG_CONTEXT_THRESHOLD_TOKENS ?? 272000);
  const inputMultiplier = longContext ? (config.OPENAI_LONG_CONTEXT_INPUT_MULTIPLIER ?? 2) : 1;
  const outputMultiplier = longContext ? (config.OPENAI_LONG_CONTEXT_OUTPUT_MULTIPLIER ?? 1.5) : 1;
  return Number((
    uncached * inputRate * inputMultiplier / 1_000_000
    + cached * cachedRate * inputMultiplier / 1_000_000
    + cacheWrite * cacheWriteRate * inputMultiplier / 1_000_000
    + output * outputRate * outputMultiplier / 1_000_000
    + searches * config.OPENAI_WEB_SEARCH_USD_PER_CALL
  ).toFixed(6));
}

function topPerformanceThumbnails(context, limit = 6) {
  const platforms = Object.values(context.buffer?.platforms ?? {});
  const posts = [...(context.buffer?.benchmark_posts ?? []), ...platforms.flatMap((platform) => platform.top_posts ?? [])];
  const unique = new Map();
  for (const post of posts) {
    let stableThumbnail = false;
    try {
      stableThumbnail = ["buffer-media-uploads.s3.amazonaws.com", "buffer-updates-media-backfill-bucket.s3.amazonaws.com", "i.ytimg.com"]
        .includes(new URL(post.thumbnail_url).hostname);
    } catch (_) {
      stableThumbnail = false;
    }
    if (!stableThumbnail || unique.has(post.thumbnail_url)) continue;
    unique.set(post.thumbnail_url, post);
  }
  return [...unique.values()]
    .sort((left, right) => (right.performance_score ?? 0) - (left.performance_score ?? 0))
    .slice(0, limit);
}

export function normalizeRequestedCaptureRequirements(plan) {
  const requestedRefs = [...new Set((plan.scenes ?? [])
    .map((scene) => scene.capture_ref)
    .filter((ref) => typeof ref === "string" && ref.startsWith("requested:")))];
  if (!requestedRefs.length) return plan;

  const brief = plan.review_brief ?? {};
  const requirements = Array.isArray(brief.production_requirements)
    ? [...brief.production_requirements]
    : [];
  const missing = requestedRefs.filter((ref) => !requirements.some((item) => item.includes(ref)));
  if (!missing.length) return plan;

  const captureRequirement = `Required app recordings before generation: ${missing.join(", ")}.`;
  const productionRequirements = requirements.length < 12
    ? [...requirements, captureRequirement]
    : requirements.map((item, index) => index === requirements.length - 1
      ? `${item} ${captureRequirement}`.slice(0, 300)
      : item);
  return {
    ...plan,
    review_brief: {
      ...brief,
      production_requirements: productionRequirements,
    },
  };
}

export function normalizeFinalCtaScene(plan) {
  const finalIndex = (plan.scenes?.length ?? 0) - 1;
  if (finalIndex < 0) return plan;
  const finalScene = plan.scenes[finalIndex];
  const cta = String(plan.cta ?? "").trim();
  const overlay = String(finalScene.overlay_text ?? "").trim();
  const words = overlay.split(/\s+/).filter(Boolean);
  const needsPurpose = finalScene.purpose !== "cta";
  const needsCopy = cta && !overlay.toLowerCase().includes(cta.toLowerCase());
  if (!needsPurpose && !needsCopy && words.length >= 5) return plan;

  const nextOverlay = needsCopy
    ? `${overlay ? `${overlay} ` : ""}${cta}`.trim().slice(0, 90)
    : overlay;
  const scenes = plan.scenes.map((scene, index) => index === finalIndex
    ? { ...scene, purpose: "cta", overlay_text: nextOverlay }
    : scene);
  return { ...plan, scenes };
}

export function normalizeVideoPlan(plan) {
  return normalizeFinalCtaScene(normalizeRequestedCaptureRequirements(plan));
}

function normalizedWords(value) {
  const ignored = new Set(["the", "a", "an", "and", "or", "to", "of", "in", "on", "with", "for", "gymfeed"]);
  return new Set(String(value ?? "").toLowerCase().match(/[a-z0-9]+/g)?.filter((word) => word.length > 2 && !ignored.has(word)) ?? []);
}

function similarity(left, right) {
  const a = normalizedWords(left), b = normalizedWords(right);
  if (!a.size || !b.size) return 0;
  const overlap = [...a].filter((word) => b.has(word)).length;
  return overlap / new Set([...a, ...b]).size;
}

function validateCreativeVariety(decision, creativeMemory = []) {
  assertFreshHooks(decision, creativeMemory);
  const recentVideo = creativeMemory.find((item) => item.content_type === "video")?.creative_signature;
  const treatment = decision.video.creative_treatment;
  if (recentVideo) {
    const repeatedAxes = [
      recentVideo.format_family === treatment.format_family,
      recentVideo.setting_family === treatment.setting_family,
      recentVideo.visual_mode === treatment.visual_mode,
      similarity(recentVideo.camera_language, treatment.camera_language) >= 0.65,
      similarity(recentVideo.performance_style, treatment.performance_style) >= 0.65,
    ].filter(Boolean).length;
    if (repeatedAxes >= 3) {
      throw new Error("Selected video repeats too many creative axes from the most recent video; change format, setting, camera language or performance style materially");
    }
  }
  if (decision.instagram.format !== "carousel" || decision.instagram.slides.length < 4) {
    throw new Error("The daily Instagram carousel must be a distinct 4-7 slide carousel");
  }
  if (decision.post.format !== "image" || decision.post.slides.length !== 1) {
    throw new Error("The daily single-image post must use format image and exactly one slide");
  }
  if (decision.instagram.creative_direction.layout_style === decision.post.creative_direction.layout_style) {
    throw new Error("Carousel and single-image post must use different layout styles");
  }
  if (similarity(decision.instagram.hook, decision.post.hook) >= 0.55
    || similarity(decision.instagram.slides[0]?.headline, decision.post.slides[0]?.headline) >= 0.55) {
    throw new Error("Carousel and single-image post repeat the same hook; give each asset a different creative job");
  }
  for (const type of ["carousel", "image"]) {
    const plan = type === "carousel" ? decision.instagram : decision.post;
    const recent = creativeMemory.find((item) => item.content_type === type)?.creative_signature;
    if (recent?.layout_style && recent.layout_style === plan.creative_direction.layout_style
      && similarity(recent.visual_world, plan.creative_direction.visual_world) >= 0.5) {
      throw new Error(`The ${type} repeats the most recent ${type} layout and visual world; choose a materially different direction`);
    }
  }
}

// Library first: a daily plan may ask the owner for at most one new recording,
// and only with a concrete shot and a reason the existing library cannot serve.
export function validateCaptureRequests(plan, appCaptures) {
  if (!appCaptures) return;
  const library = new Set(appCaptures.map((capture) => capture.id));
  const missing = [...new Set((plan.scenes ?? [])
    .filter((scene) => scene.asset_type === "app_capture" && String(scene.capture_ref ?? "").startsWith("requested:") && !library.has(scene.capture_ref))
    .map((scene) => scene.capture_ref))];
  if (missing.length > 1) {
    throw new Error(`Daily plan requests ${missing.length} new recordings (${missing.join(", ")}); reuse the asset library and request at most one new recording`);
  }
  const requests = new Map((plan.capture_requests ?? []).map((request) => [request.capture_ref, request]));
  for (const ref of missing) {
    const request = requests.get(ref);
    if (!request || String(request.why_library_insufficient ?? "").trim().length < 20 || String(request.shot_instructions ?? "").trim().length < 20) {
      throw new Error(`New recording ${ref} needs a capture_requests entry with shot_instructions and why_library_insufficient`);
    }
  }
}

export function validateCreativeDecision(research, decision, { appCaptures, allowProductLedVideo = false, creativeMemory = [] } = {}) {
  const evidenceIds = new Set(research.trends.map((trend) => trend.evidence_id));
  const modes = new Set(decision.candidate_concepts.map((candidate) => candidate.content_mode));
  if (![...modes].some((mode) => mode === "human_story" || mode === "human_demonstration" || mode === "hybrid")) {
    throw new Error("Creative decision must compare at least one human-led or hybrid candidate");
  }
  if (!modes.has("product_demonstration")) {
    throw new Error("Creative decision must compare at least one product-demonstration candidate");
  }
  for (const candidate of decision.candidate_concepts) {
    const missingEvidence = candidate.evidence_ids.filter((id) => !evidenceIds.has(id));
    if (missingEvidence.length) throw new Error(`Candidate ${candidate.name} cites unknown evidence: ${missingEvidence.join(", ")}`);
    const scores = candidate.scores;
    if (!candidate.evidence_ids.length && Number(scores.evidence_strength) !== 0) throw new Error(`Candidate ${candidate.name} has no evidence and must use evidence_strength 0`);
    const expected = scores.evidence_strength * 0.20
      + scores.audience_fit * 0.15
      + scores.product_fit * 0.20
      + scores.attention_potential * 0.20
      + scores.conversion_potential * 0.20
      + scores.production_feasibility * 0.05;
    if (Math.abs(expected - candidate.weighted_score) > 0.11) {
      throw new Error(`Candidate ${candidate.name} has an invalid weighted score`);
    }
  }
  const selected = decision.candidate_concepts.find((candidate) => candidate.name === decision.selected_strategy.candidate_name);
  if (!selected) throw new Error("Selected strategy does not match a candidate name");
  const bestScore = Math.max(...decision.candidate_concepts.map((candidate) => candidate.weighted_score));
  if (selected.weighted_score < bestScore - 5) throw new Error("Selected strategy is not a top-tier candidate");

  const treatment = decision.video.creative_treatment;
  const missingTreatmentEvidence = treatment.evidence_ids.filter((id) => !evidenceIds.has(id));
  if (missingTreatmentEvidence.length) throw new Error(`Creative treatment cites unknown evidence: ${missingTreatmentEvidence.join(", ")}`);
  if (treatment.people_screen_time_percent + treatment.product_screen_time_percent !== 100) {
    throw new Error("Creative treatment people and product screen-time percentages must total 100");
  }
  if (treatment.visual_mode === "product_led") {
    if (!allowProductLedVideo) {
      throw new Error("Daily video cannot be a screen-only product tutorial unless the human reviewer explicitly requested that format");
    }
    if (!["gymfeed_screenshot", "app_capture"].includes(treatment.opening_asset) || treatment.people_role !== "none" || treatment.people_screen_time_percent !== 0) {
      throw new Error("Product-led treatment must open on GymFeed UI and contain no generated people");
    }
  } else if (treatment.opening_asset !== "fal_video" || treatment.people_role === "none" || treatment.people_screen_time_percent === 0) {
    throw new Error("Human-led and hybrid treatments must open on a human fal.ai video sequence");
  }
  validateVideoProductionPlan(decision.video, { appCaptures });
  validateCaptureRequests(decision.video, appCaptures);
  validateCreativeVariety(decision, creativeMemory);
  for (const [assetName, asset] of [["Carousel", decision.instagram], ["Post", decision.post]]) {
    for (const [index, slide] of asset.slides.entries()) {
      if (slide.visual_type === "product_screenshot" && !slide.screenshot_ref) {
        throw new Error(`${assetName} slide ${index + 1} requires a verified screenshot_ref`);
      }
      if (slide.visual_type !== "product_screenshot" && slide.screenshot_ref) {
        throw new Error(`${assetName} slide ${index + 1} cannot combine ${slide.visual_type} with screenshot_ref`);
      }
    }
  }
  return decision;
}

export function validateVideoProductionPlan(plan, { appCaptures } = {}) {
  validateVideoStory(plan);
  const productionV2 = Number(plan.production_version) >= 2;
  const sceneIds = new Set();
  let duration = 0;
  let generatedScenes = 0;
  let appCaptureScenes = 0;
  let speakingSeconds = 0;
  const knownCaptures = appCaptures ? new Set(appCaptures.map((capture) => capture.capture_ref ?? capture.id ?? capture.filename)) : null;
  for (const [index, scene] of plan.scenes.entries()) {
    if (sceneIds.has(scene.scene_id)) throw new Error(`Video scene_id must be unique: ${scene.scene_id}`);
    sceneIds.add(scene.scene_id);
    const retained = Number(scene.duration_seconds);
    const start = Number(scene.source_start_seconds ?? 0);
    if (!Number.isFinite(retained) || retained < 1.5 || retained > 10) throw new Error(`Scene ${scene.scene_id} must retain 1.5-10 seconds`);
    if (!Number.isFinite(start) || start < 0) throw new Error(`Scene ${scene.scene_id} has an invalid source_start_seconds`);
    duration += retained;
    if (scene.asset_type === "generated_video") {
      generatedScenes += 1;
      if (scene.screenshot_ref) throw new Error(`Generated video scene ${index + 1} cannot use screenshot_ref`);
      if (scene.capture_ref) throw new Error(`Generated video scene ${index + 1} cannot use capture_ref`);
      const sourceDuration = Number(scene.source_duration_seconds ?? retained);
      if (!Number.isFinite(sourceDuration) || sourceDuration < 3 || sourceDuration > 10 || start + retained > sourceDuration + 0.01) {
        throw new Error(`Generated scene ${scene.scene_id} requires a 3-10 second source covering the exact retained cut`);
      }
    } else if (scene.asset_type === "app_capture") {
      appCaptureScenes += 1;
      if (!scene.capture_ref || scene.screenshot_ref) throw new Error(`App capture scene ${scene.scene_id} requires capture_ref and an empty screenshot_ref`);
      if (knownCaptures && !knownCaptures.has(scene.capture_ref) && !scene.capture_ref.startsWith("requested:")) throw new Error(`Unavailable verified app capture: ${scene.capture_ref}; identify a missing asset with requested: instead of inventing a verified reference`);
      if (scene.capture_ref.startsWith("requested:") && !plan.review_brief?.production_requirements?.some((item) => item.includes(scene.capture_ref))) throw new Error(`Missing capture ${scene.capture_ref} must be listed explicitly in review_brief.production_requirements`);
      if (!Number.isFinite(Number(scene.source_duration_seconds)) || start + retained > Number(scene.source_duration_seconds) + 0.01) {
        throw new Error(`App capture ${scene.scene_id} does not cover its retained cut`);
      }
    } else if (scene.asset_type !== "gymfeed_screen") {
      throw new Error(`Unsupported video asset_type: ${scene.asset_type}`);
    } else if (!scene.screenshot_ref) {
      throw new Error(`GymFeed screen scene ${index + 1} requires screenshot_ref`);
    }
    if (scene.asset_type === "gymfeed_screen" && (Number(scene.source_duration_seconds ?? 0) !== 0 || start !== 0 || scene.capture_ref)) {
      throw new Error("GymFeed screen scenes must use source_duration_seconds 0, source_start_seconds 0 and no capture_ref");
    }
    if (!productionV2) continue;
    if (!scene.overlay_text?.trim()) throw new Error(`Scene ${scene.scene_id} needs its visible story beat in overlay_text`);
    if (!["native", "voiceover", "ambient", "silent"].includes(scene.audio_strategy)) throw new Error(`Scene ${scene.scene_id} requires an explicit audio_strategy`);
    if (scene.audio_strategy === "native") {
      if (scene.asset_type !== "generated_video" || !scene.spoken_dialogue?.trim()) throw new Error(`Native scene ${scene.scene_id} requires generated footage and exact spoken_dialogue`);
      if (scene.voiceover_text?.trim()) throw new Error(`Native scene ${scene.scene_id} cannot overlap another spoken voice`);
      speakingSeconds += retained;
    } else if (scene.spoken_dialogue?.trim()) {
      throw new Error(`Scene ${scene.scene_id} supplies dialogue but does not use native audio`);
    }
    if (scene.audio_strategy === "voiceover") {
      if (!scene.voiceover_text?.trim()) throw new Error(`Voiceover scene ${scene.scene_id} requires voiceover_text`);
      speakingSeconds += retained;
    } else if (scene.voiceover_text?.trim()) {
      throw new Error(`Scene ${scene.scene_id} supplies narration but does not use voiceover audio`);
    }
    if (["app_capture", "gymfeed_screen"].includes(scene.asset_type) && ["action", "product_proof"].includes(scene.purpose) && scene.audio_strategy !== "voiceover") {
      throw new Error(`Product proof scene ${scene.scene_id} requires narration explaining the visible action`);
    }
    const words = String(scene.audio_strategy === "native" ? scene.spoken_dialogue : scene.voiceover_text ?? "").trim().split(/\s+/).filter(Boolean).length;
    if (words > Math.floor(retained * 3)) throw new Error(`Speech in ${scene.scene_id} is too long for its retained cut`);
  }
  if (duration < 8 || duration > 180) throw new Error(`Video scene duration must total 8-180 seconds; received ${duration}s`);
  if (productionV2 && Math.abs(duration - Number(plan.target_duration_seconds)) > 0.01) throw new Error("Scene durations must equal target_duration_seconds exactly");
  plan.target_duration_seconds = duration;
  if (plan.creative_treatment.visual_mode === "product_led" && generatedScenes > 0) {
    throw new Error("Product-led video cannot contain generated human footage");
  }
  if (plan.creative_treatment.visual_mode !== "product_led" && generatedScenes < 1) {
    throw new Error("Human-led and hybrid videos require at least one generated shot");
  }
  if (generatedScenes > 0 && !plan.character_reference.required) {
    throw new Error("Generated human scenes require one locked character reference");
  }
  if (productionV2) {
    if (!appCaptureScenes || !plan.scenes.some((scene) => scene.asset_type === "app_capture" && ["action", "product_proof"].includes(scene.purpose))) throw new Error("Production video needs verified app_capture footage of the actual GymFeed action; screenshots alone cannot prove interaction");
    if (plan.audio_mode !== "mixed" || plan.captions_enabled !== true) throw new Error("Production video requires mixed scene audio and enabled captions");
    if (speakingSeconds < duration * 0.5) throw new Error("The audio timeline must explain the story through at least half of the edit");
    if (!["hook", "problem"].includes(plan.scenes[0]?.purpose)) throw new Error("The opening scene must introduce the hook or problem");
    for (const mapping of plan.reviewer_instruction_map ?? []) {
      if (!mapping.scene_ids?.length || mapping.scene_ids.some((id) => !sceneIds.has(id)) || !mapping.implemented_change?.trim()) throw new Error("Reviewer instruction mapping must identify existing changed scenes and the concrete correction");
    }
  }
  const finalScene = plan.scenes.at(-1);
  const finalOverlay = String(finalScene?.overlay_text ?? "").trim();
  const finalPayoff = [finalScene?.action, finalScene?.spoken_dialogue, finalScene?.voiceover_text, finalOverlay]
    .filter(Boolean).join(" ").trim();
  if (finalScene?.purpose !== "cta" || !finalOverlay || finalPayoff.split(/\s+/).filter(Boolean).length < 5) {
    throw new Error("The final video scene requires a meaningful payoff or punchline plus CTA");
  }
  return plan;
}

export function validateRevisedPlan(plan, contentType, { appCaptures } = {}) {
  if (contentType === "video") {
    const treatment = plan.creative_treatment;
    if (treatment.people_screen_time_percent + treatment.product_screen_time_percent !== 100) {
      throw new Error("Revised video people and product screen-time percentages must total 100");
    }
    if (treatment.visual_mode === "product_led") {
      if (!["gymfeed_screenshot", "app_capture"].includes(treatment.opening_asset) || treatment.people_role !== "none" || treatment.people_screen_time_percent !== 0) {
        throw new Error("Revised product-led video must open on GymFeed UI and contain no generated people");
      }
    } else if (treatment.opening_asset !== "fal_video" || treatment.people_role === "none" || treatment.people_screen_time_percent === 0) {
      throw new Error("Revised human-led and hybrid video must open on a human fal.ai sequence");
    }
    return validateVideoProductionPlan(plan, { appCaptures });
  }
  if (contentType === "image" && (plan.format !== "image" || plan.slides.length !== 1)) {
    throw new Error("Revised single-image post must keep format image and exactly one slide");
  }
  if (contentType === "carousel" && (plan.format !== "carousel" || plan.slides.length < 4)) {
    throw new Error("Revised carousel must keep format carousel and 4-7 slides");
  }
  for (const [index, slide] of plan.slides.entries()) {
    if (slide.visual_type === "product_screenshot" && !slide.screenshot_ref) {
      throw new Error(`Revised Instagram slide ${index + 1} requires a verified screenshot_ref`);
    }
    if (slide.visual_type !== "product_screenshot" && slide.screenshot_ref) {
      throw new Error(`Revised Instagram slide ${index + 1} cannot combine ${slide.visual_type} with screenshot_ref`);
    }
  }
  return plan;
}

export class MarketingBrain {
  constructor(config, client) {
    this.config = config;
    this.client = client ?? (config.OPENAI_API_KEY ? new OpenAI({ apiKey: config.OPENAI_API_KEY }) : null);
  }

  ensureConfigured() {
    if (!this.client) throw new Error("OpenAI is not configured");
  }

  async draftVideo(brief, { model = this.config.OPENAI_CREATIVE_MODEL, appCaptures = [] } = {}) {
    this.ensureConfigured();
    const productBrief = await loadProductBrief();
    const screenshots = await verifiedScreenshotManifest();
    const response = await this.client.responses.parse({
      model, reasoning: { effort: this.config.OPENAI_REASONING_EFFORT ?? "medium" },
      input: [systemInstructions(VIDEO_PRODUCTION_DIRECTION, productBrief), { role: "user", content:
        `Create ONE original video plan only. No campaign, no carousel, no web research. Treat this as a creative experiment, not validated performance. reviewer_instruction_map and evidence_ids must be empty.\nBRIEF:\n${brief}\nVERIFIED SCREENSHOTS:\n${compactContext(screenshots, 10000)}\nVERIFIED CAPTURES:\n${compactContext(appCaptures.map(captureSnapshot), 12000)}` }],
      text: { format: zodTextFormat(VideoPlanSchema, "gymfeed_video_pilot") },
      max_output_tokens: this.config.OPENAI_CREATIVE_MAX_OUTPUT_TOKENS ?? 12000,
      ...cacheConfiguration(model),
    });
    try {
      if (!response.output_parsed) throw new Error("OpenAI returned no parsed pilot script");
      const plan = normalizeVideoPlan(response.output_parsed);
      validateRevisedPlan(plan, "video", { appCaptures });
      return { data: plan, model: response.model, usage: response.usage, costUsd: responseCost(response, this.config), responseId: response.id };
    } catch (error) { throw attachBilledUsage(error, [response], this.config); }
  }

  async storyQualityReview(plan) {
    this.ensureConfigured();
    validateVideoProductionPlan(plan);
    const model = this.config.OPENAI_QA_MODEL ?? this.config.OPENAI_DAILY_MODEL;
    const response = await this.client.responses.parse({
      model, reasoning: { effort: this.config.OPENAI_QA_REASONING_EFFORT ?? "low" },
      input: [systemInstructions(STORY_REVIEW_PROMPT, await loadProductBrief()),
        { role: "user", content: JSON.stringify({ deterministic_checks: {
          valid: true, retained_total_seconds: plan.scenes.reduce((sum, scene) => sum + scene.duration_seconds, 0),
          target_duration_seconds: plan.target_duration_seconds,
          cuts_within_declared_sources: true, dialogue_speakers_valid: true,
          stage: "script_only; capture visual verification and privacy treatment occur before final release",
        }, plan }) }],
      text: { format: zodTextFormat(StoryReviewSchema, "gymfeed_story_review") },
      max_output_tokens: 2000, ...cacheConfiguration(model),
    });
    if (!response.output_parsed) throw attachBilledUsage(new Error("OpenAI returned no story review"), [response], this.config);
    return { data: response.output_parsed, costUsd: responseCost(response, this.config), responseId: response.id };
  }

  async daily(context, campaignDate = new Date()) {
    this.ensureConfigured();
    const [productBrief, screenshots, referenceScreens] = await Promise.all([
      loadProductBrief(),
      verifiedScreenshotManifest(),
      referenceScreenshotCatalog(),
    ]);
    const planningTimestamp = new Date().toISOString();
    const publicationDate = campaignDate.toISOString().slice(0, 10);
    const aiContext = buildAiDecisionContext(context);
    const performanceThumbnails = topPerformanceThumbnails(context, 3);
    const researchModel = this.config.OPENAI_RESEARCH_MODEL ?? this.config.OPENAI_DAILY_MODEL;
    const researchResponse = await this.client.responses.parse({
      model: researchModel,
      reasoning: { effort: this.config.OPENAI_RESEARCH_REASONING_EFFORT ?? "low" },
      tools: [{ type: "web_search" }],
      tool_choice: "auto",
      input: [
        systemInstructions(TREND_RESEARCH_PROMPT, productBrief),
        {
          role: "user",
          content: [
            { type: "input_text", text: `Planning timestamp: ${planningTimestamp}\nCampaign publication date: ${publicationDate}\n\nBOUNDED FIRST-PARTY GYMFEED PERFORMANCE CONTEXT:\n${compactContext(aiContext, 24000)}\n\nThe attached images, when present, are thumbnails from the highest-ranked historical GymFeed posts in the Buffer context. Use them only to analyze transferable visual structure; do not reuse a person's likeness or copyrighted footage.` },
            ...performanceThumbnails.map((post) => ({
              type: "input_image",
              image_url: post.thumbnail_url,
              detail: "low",
            })),
          ],
        },
      ],
      text: { format: zodTextFormat(TrendResearchSchema, "gymfeed_trend_research") },
      max_output_tokens: this.config.OPENAI_RESEARCH_MAX_OUTPUT_TOKENS ?? 6000,
      ...cacheConfiguration(researchModel),
    });
    if (!researchResponse.output_parsed) throw attachBilledUsage(new Error("OpenAI returned no parsed trend research"), [researchResponse], this.config);

    const decisionContext = `Planning timestamp: ${planningTimestamp}\nCampaign publication date: ${publicationDate}\n\nQUANTITATIVE TREND RESEARCH:\n${compactContext(researchResponse.output_parsed, 12000)}\n\nRECENT CREATIVE MEMORY — DO NOT REPEAT THESE FORMAT/SETTING/CAMERA/LAYOUT COMBINATIONS:\n${compactContext(aiContext.creative_memory, 16000)}\n\nVERIFIED CURRENT-BUILD SCREENSHOT MANIFEST:\n${compactContext(screenshots, 10000)}\n\nASSET LIBRARY — VERIFIED APP RECORDINGS (reuse first; times_used/last_used show recent repetition):\n${compactContext(libraryCatalog(context.app_captures ?? [], context.content ?? []), 14000)}\n\nLIBRARY COVERAGE BY FEATURE (recordings and verified screenshots; zero recordings marks a gap worth one new request):\n${compactContext(libraryCoverage(context.app_captures ?? [], screenshots), 3000)}\n\nARCHIVE VISUAL REFERENCE FILENAMES (design reference only; never use as screenshot_refs or live-product proof):\n${compactContext(referenceScreens, 5000)}\n\nBOUNDED FIRST-PARTY PERFORMANCE CONTEXT:\n${compactContext(aiContext, 30000)}`;
    const decisionResponses = [];
    let decision = null;
    let validationError = null;
    for (let attempt = 1; attempt <= 2; attempt += 1) {
      const model = attempt === 1
        ? this.config.OPENAI_CREATIVE_MODEL ?? this.config.OPENAI_DAILY_MODEL
        : this.config.OPENAI_FALLBACK_MODEL ?? this.config.OPENAI_DAILY_MODEL;
      const repairContext = attempt === 1 ? "" : `\n\nYOUR PREVIOUS PLAN WAS REJECTED BY DETERMINISTIC VALIDATION.\nReason: ${validationError.message}\n\nReturn a complete replacement plan, not commentary. Correct the exact violation under the production director requirements while preserving the evidence-backed campaign strategy. Keep the story meaningful, the source cuts valid, the audio timeline complete and the app_capture references real. Do not invent a missing asset or revert to the retired six-second talking-head template.\n\nREJECTED PLAN:\n${compactContext(decisionResponses.at(-1)?.output_parsed, 12000)}`;
      let response;
      try {
        response = await this.client.responses.parse({
          model,
          reasoning: { effort: this.config.OPENAI_REASONING_EFFORT },
          input: [
            systemInstructions(`${DAILY_BRAIN_PROMPT}${this.config.MARKETING_REVIEW_MODE === "human" ? "\nOWNER REVIEW POLICY: AI QA is disabled. The owner reviews the completed video, carousel or image and decides Approve or Reject. Do not invent a minimum AI QA score, automatic QA repairs or paid retakes as production requirements. An additional generation is authorized only by a new human revision decision. Keep verifiable asset requirements and factual product claims." : ""}`, productBrief),
            { role: "user", content: `CREATIVE INTELLIGENCE — SATURATION, PRIOR PREMISES AND MEASUREMENT LIMITS:\n${compactContext(aiContext.creative_intelligence, 11000)}\n\n${decisionContext}${repairContext}` },
          ],
          text: { format: zodTextFormat(CreativeDecisionSchema, "gymfeed_creative_decision") },
          max_output_tokens: this.config.OPENAI_CREATIVE_MAX_OUTPUT_TOKENS ?? 12000,
          ...cacheConfiguration(model),
        });
      } catch (error) {
        throw attachBilledUsage(error, [researchResponse, ...decisionResponses], this.config);
      }
      decisionResponses.push(response);
      try {
        if (!response.output_parsed) throw new Error("OpenAI returned no parsed creative decision");
        const normalized = {
          ...response.output_parsed,
          video: normalizeVideoPlan(response.output_parsed.video),
        };
        validateCreativeDecision(researchResponse.output_parsed, normalized, {
          appCaptures: context.app_captures ?? [],
          allowProductLedVideo: context.allow_product_led_video === true,
          creativeMemory: aiContext.creative_memory ?? [],
        });
        decision = normalized;
        break;
      } catch (error) {
        validationError = error;
      }
    }
    if (!decision) throw attachBilledUsage(validationError, [researchResponse, ...decisionResponses], this.config);
    return {
      data: { ...researchResponse.output_parsed, ...decision },
      costUsd: Number((responseCost(researchResponse, this.config) + decisionResponses.reduce((sum, response) => sum + responseCost(response, this.config), 0)).toFixed(6)),
      responseId: [researchResponse.id, ...decisionResponses.map((response) => response.id)].join(","),
    };
  }

  async qualityReview(content, visualUrls = []) {
    this.ensureConfigured();
    const [productBrief, screenshots, referenceScreens] = await Promise.all([
      loadProductBrief(),
      verifiedScreenshotManifest(),
      referenceScreenshotCatalog(),
    ]);
    const model = this.config.OPENAI_QA_MODEL ?? this.config.OPENAI_DAILY_MODEL;
    const userContent = [
      { type: "input_text", text: `VERIFIED CURRENT-BUILD SCREENSHOT MANIFEST:\n${compactContext(screenshots, 10000)}\n\nARCHIVE VISUAL REFERENCE FILENAMES (not valid live-product proof):\n${compactContext(referenceScreens, 5000)}\n\nCONTENT RECORD AND PLAN:\n${compactContext(contentSnapshot(content), 10000)}\n\nAPPROVED CONTENT PLAN:\n${compactContext(content.decision?.content ?? {}, 18000)}\n\nFINAL AUDIO VERIFICATION:\n${compactContext({ final: content.decision?.generation?.final_technical, scenes: (content.decision?.generation?.scenes ?? []).map((scene) => ({ scene_id: scene.scene_id, technical: scene.technical })), caption_gaps: content.decision?.generation?.preview_caption_gaps }, 12000)}\n\nSAVED RESEARCH EVIDENCE PACKAGE:\n${compactContext(researchEvidenceForQa(content), 24000)}` },
      ...visualUrls.map((imageUrl) => ({ type: "input_image", image_url: imageUrl, detail: "high" })),
    ];
    const response = await this.client.responses.parse({
      model,
      reasoning: { effort: this.config.OPENAI_QA_REASONING_EFFORT ?? "low" },
      input: [
        systemInstructions(QA_PROMPT, productBrief, supportsExplicitCaching(model)),
        { role: "user", content: userContent },
      ],
      text: { format: zodTextFormat(QualityReviewSchema, "gymfeed_quality_review") },
      max_output_tokens: this.config.OPENAI_QA_MAX_OUTPUT_TOKENS ?? 6000,
      ...cacheConfiguration(model),
    });
    if (!response.output_parsed) throw attachBilledUsage(new Error("OpenAI returned no parsed quality review"), [response], this.config);
    return { data: response.output_parsed, costUsd: responseCost(response, this.config), responseId: response.id };
  }

  async describeLibraryCapture({ filename, durationSeconds, frames, contactSheet }) {
    this.ensureConfigured();
    const model = this.config.OPENAI_QA_MODEL ?? this.config.OPENAI_DAILY_MODEL;
    const response = await this.client.responses.parse({
      model,
      reasoning: { effort: this.config.OPENAI_QA_REASONING_EFFORT },
      input: [
        systemInstructions(LIBRARY_CAPTURE_PROMPT),
        { role: "user", content: [
          { type: "input_text", text: `FILE: ${filename}
DURATION: ${durationSeconds.toFixed(2)} seconds
${frames} frames in row-major order, evenly sampled approximately every ${(durationSeconds / frames).toFixed(2)} seconds.` },
          { type: "input_image", image_url: `data:image/jpeg;base64,${contactSheet.toString("base64")}`, detail: "high" },
        ] },
      ],
      text: { format: zodTextFormat(LibraryCaptureDescriptionSchema, "gymfeed_library_capture") },
      max_output_tokens: this.config.OPENAI_QA_MAX_OUTPUT_TOKENS ?? 6000,
    });
    if (!response.output_parsed) throw attachBilledUsage(new Error("OpenAI returned no parsed library description"), [response], this.config);
    return { data: response.output_parsed, costUsd: responseCost(response, this.config), responseId: response.id };
  }

  async reviseContent(content, instructions, { app_captures = [], captureVisuals = [] } = {}) {
    this.ensureConfigured();
    const [productBrief, screenshots] = await Promise.all([
      loadProductBrief(),
      verifiedScreenshotManifest(),
    ]);
    const isVideo = content.content_type === "video";
    const schema = isVideo ? VideoPlanSchema : InstagramPlanSchema;
    const revisionContext = `CONTENT TYPE: ${isVideo ? "video" : "instagram"}\n\nREVIEWER INSTRUCTIONS:\n${instructions}\n\nVERIFIED CURRENT-BUILD SCREENSHOT MANIFEST:\n${compactContext(screenshots, 10000)}\n\nVERIFIED APP CAPTURE MANIFEST:\n${compactContext(app_captures.map(captureSnapshot), 10000)}\n\nREJECTED CONTENT SUMMARY:\n${compactContext(contentSnapshot(content), 8000)}\n\nREJECTED CONTENT PLAN:\n${compactContext(content.decision?.content ?? {}, 18000)}`;
    const responses = [];
    let validationError = null;
    for (let attempt = 1; attempt <= 2; attempt += 1) {
      const model = attempt === 1
        ? this.config.OPENAI_CREATIVE_MODEL ?? this.config.OPENAI_DAILY_MODEL
        : this.config.OPENAI_FALLBACK_MODEL ?? this.config.OPENAI_DAILY_MODEL;
      const repair = attempt === 1 ? "" : `\n\nThe first revision failed deterministic validation: ${validationError.message}. Return a corrected complete replacement.`;
      let response;
      try {
        response = await this.client.responses.parse({
          model,
          reasoning: { effort: this.config.OPENAI_REASONING_EFFORT },
          input: [
            systemInstructions(`${CONTENT_REVISION_PROMPT}${this.config.MARKETING_REVIEW_MODE === "human" ? "\nOWNER REVIEW POLICY: Apply the human's requested revision and return it for human review. No AI QA score gate or automatic retake loop. Do not copy the entire revision screenplay into individual shot instructions." : ""}`, productBrief),
            { role: "user", content: [
              { type: "input_text", text: `${revisionContext}${repair}\nUse the source contact sheets to locate the actual action and result. Never infer timestamp positions from a filename or requested description. Keep unrelated screens out of retained ranges. Choose interior ranges with edit handles; keep capture-to-result order. Preserve people and dialogue unless the reviewer explicitly requests their removal.` },
              ...captureVisuals.flatMap((capture) => [
                { type: "input_text", text: `SOURCE ${capture.ref}: ${capture.duration} seconds; ${capture.frames} frames in row-major order, evenly sampled approximately every ${capture.duration / capture.frames} seconds. These are source frames, not the final edit.` },
                { type: "input_image", image_url: capture.image, detail: "high" },
              ]),
            ] },
          ],
          text: { format: zodTextFormat(schema, isVideo ? "gymfeed_video_revision" : "gymfeed_instagram_revision") },
          max_output_tokens: this.config.OPENAI_CREATIVE_MAX_OUTPUT_TOKENS ?? 12000,
          ...cacheConfiguration(model),
        });
      } catch (error) {
        throw attachBilledUsage(error, responses, this.config);
      }
      responses.push(response);
      try {
        if (!response.output_parsed) throw new Error("OpenAI returned no parsed content revision");
        const normalized = isVideo ? normalizeVideoPlan(response.output_parsed) : response.output_parsed;
        validateRevisedPlan(normalized, content.content_type, { appCaptures: app_captures });
        if (isVideo && !normalized.reviewer_instruction_map?.length) throw new Error("Video revision must map the reviewer's instructions to concrete changed scenes");
        return {
          data: normalized,
          costUsd: Number(responses.reduce((sum, item) => sum + responseCost(item, this.config), 0).toFixed(6)),
          responseId: responses.map((item) => item.id).join(","),
        };
      } catch (error) {
        validationError = error;
      }
    }
    throw attachBilledUsage(validationError, responses, this.config);
  }

  async reviseVideoAsset(content, instructions) {
    this.ensureConfigured();
    const model = this.config.OPENAI_CREATIVE_MODEL ?? this.config.OPENAI_DAILY_MODEL;
    const response = await this.client.responses.parse({
      model, reasoning: { effort: this.config.OPENAI_REASONING_EFFORT },
      input: [systemInstructions(VIDEO_ASSET_REVISION_PROMPT), { role: "user", content: JSON.stringify({
        owner_instructions: instructions,
        plan: content.decision.content,
        available_media: (content.decision.generation?.scenes ?? []).map((scene) => ({
          scene_id: scene.scene_id, saved: Boolean(scene.asset_url), duration: scene.technical?.duration_seconds,
          transcript: scene.technical?.source_transcript ?? scene.technical?.transcript,
        })),
      }) }],
      text: { format: zodTextFormat(VideoAssetRevisionSchema, "gymfeed_selective_video_revision") },
      max_output_tokens: this.config.OPENAI_CREATIVE_MAX_OUTPUT_TOKENS ?? 12000,
      ...cacheConfiguration(model),
    });
    try {
      if (!response.output_parsed) throw new Error("OpenAI returned no selective revision plan");
      const patch = VideoAssetRevisionSchema.parse(response.output_parsed);
      const revised = applyVideoRevision(content, patch, instructions);
      return { data: revised.plan, revisionScope: revised.scope, costUsd: responseCost(response, this.config), responseId: response.id };
    } catch (error) { throw attachBilledUsage(error, [response], this.config); }
  }

  async compileContinuity(plan, previous = null) {
    this.ensureConfigured();
    const response=await this.client.responses.parse({model:this.config.OPENAI_CREATIVE_MODEL??this.config.OPENAI_DAILY_MODEL,
      input:[systemInstructions(CONTINUITY_DIRECTOR_PROMPT),{role:"user",content:JSON.stringify({cast:plan.cast,reference:plan.character_reference,
        scenes:plan.scenes.map(({scene_id,environment,lighting,character_ids,speaker_id,action})=>({scene_id,environment,lighting,character_ids,speaker_id,action})),previous})}],
      text:{format:zodTextFormat(ContinuityLayoutSchema,"gymfeed_production_continuity")},max_output_tokens:4000});
    try{if(!response.output_parsed)throw Error("No production continuity layout returned");
      return {data:ContinuityLayoutSchema.parse(response.output_parsed),costUsd:responseCost(response,this.config),responseId:response.id};
    }catch(error){throw attachBilledUsage(error,[response],this.config);}
  }

  async sceneQualityReview(content, scene, visualUrls = []) {
    this.ensureConfigured();
    const model = this.config.OPENAI_QA_MODEL ?? this.config.OPENAI_DAILY_MODEL;
    const response = await this.client.responses.parse({
      model,
      reasoning: { effort: this.config.OPENAI_QA_REASONING_EFFORT ?? "low" },
      input: [
        systemInstructions(SCENE_QA_PROMPT, "", supportsExplicitCaching(model)),
        {
          role: "user",
          content: [
            { type: "input_text", text: `CONTENT SUMMARY:\n${compactContext(contentSnapshot(content), 8000)}\n\nAPPROVED VISUAL CONTINUITY:\n${compactContext({ creative_treatment: content.decision?.content?.creative_treatment, character_reference: content.decision?.content?.character_reference, cast: content.decision?.content?.cast }, 8000)}\n\nSCENE SPECIFICATION:\n${compactContext(scene, 10000)}\n\nRETAINED AUDIO AND TECHNICAL EVIDENCE:\n${JSON.stringify(content.decision?.generation?.scenes?.find((item) => item.scene_id === scene.scene_id)?.technical ?? {})}\nThe FIRST image is the scene contact sheet. Subsequent images are cast identity references in character_ids order, not additional video frames. Compare actor identities to them. Transcription verifies words, not voice identity or lip synchronization; do not claim these are measured from stills.` },
            ...visualUrls.map((imageUrl) => ({ type: "input_image", image_url: imageUrl, detail: "high" })),
          ],
        },
      ],
      text: { format: zodTextFormat(SceneQualityReviewSchema, "gymfeed_scene_quality_review") },
      max_output_tokens: this.config.OPENAI_QA_MAX_OUTPUT_TOKENS ?? 6000,
      ...cacheConfiguration(model),
    });
    if (!response.output_parsed) throw attachBilledUsage(new Error("OpenAI returned no parsed scene quality review"), [response], this.config);
    return { data: response.output_parsed, costUsd: responseCost(response, this.config), responseId: response.id };
  }

  async weekly(context) {
    this.ensureConfigured();
    const model = this.config.OPENAI_WEEKLY_MODEL;
    const response = await this.client.responses.parse({
      model,
      reasoning: { effort: this.config.OPENAI_WEEKLY_REASONING_EFFORT ?? this.config.OPENAI_REASONING_EFFORT },
      input: [
        systemInstructions(`${WEEKLY_CMO_PROMPT}\n${CMO_OPERATING_SYSTEM}`, await loadProductBrief()),
        { role: "user", content: `CREATIVE INTELLIGENCE:\n${compactContext(creativeIntelligence(context.content, context.publications, context.events_30d), 11000)}\n\nPERFORMANCE CONTEXT:\n${compactContext(buildAiDecisionContext(context, { weekly: true }), 40000)}` },
      ],
      text: { format: zodTextFormat(WeeklyReviewSchema, "gymfeed_weekly_review") },
      max_output_tokens: this.config.OPENAI_WEEKLY_MAX_OUTPUT_TOKENS ?? 10000,
      ...cacheConfiguration(model),
    });
    if (!response.output_parsed) throw attachBilledUsage(new Error("OpenAI returned no parsed weekly review"), [response], this.config);
    return { data: response.output_parsed, costUsd: responseCost(response, this.config), responseId: response.id };
  }

  async studioBrief(context, { department, instructions = "" }) {
    this.ensureConfigured();
    const definition = STUDIO_DEPARTMENTS[department];
    if (!definition) throw new Error("Unknown marketing department");
    const response = await this.client.responses.parse({
      model: this.config.OPENAI_CREATIVE_MODEL ?? this.config.OPENAI_DAILY_MODEL,
      reasoning: { effort: this.config.OPENAI_REASONING_EFFORT },
      input: [systemInstructions(`${CMO_OPERATING_SYSTEM}\nDEPARTMENT: ${definition.title}\n${definition.instruction}\nReturn the structured brief only.`, await loadProductBrief()),
        { role: "user", content: `Owner brief: ${instructions}\n\nCREATIVE INTELLIGENCE:\n${compactContext(creativeIntelligence(context.content, context.publications, context.events_30d), 11000)}\n\n${compactContext(buildAiDecisionContext(context, { weekly: true }), 36000)}` }],
      text: { format: zodTextFormat(StudioBriefSchema, "gymfeed_studio_brief") }, max_output_tokens: 6000,
    });
    if (!response.output_parsed) throw attachBilledUsage(new Error("No parsed department brief"), [response], this.config);
    return { data: response.output_parsed, costUsd: responseCost(response, this.config), responseId: response.id };
  }
}
