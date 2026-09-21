import OpenAI from "openai";
import { zodTextFormat } from "openai/helpers/zod";
import { CreativeDecisionSchema, InstagramPlanSchema, QualityReviewSchema, SceneQualityReviewSchema, TrendResearchSchema, VideoPlanSchema, WeeklyReviewSchema } from "./contracts.mjs";
import { CONTENT_REVISION_PROMPT, DAILY_BRAIN_PROMPT, QA_PROMPT, SCENE_QA_PROMPT, TREND_RESEARCH_PROMPT, WEEKLY_CMO_PROMPT } from "./prompts.mjs";
import { loadProductBrief, referenceScreenshotCatalog, verifiedScreenshotManifest } from "./product-brief.mjs";

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

function topPerformanceThumbnails(context, limit = 6) {
  const platforms = Object.values(context.buffer?.platforms ?? {});
  const posts = platforms.flatMap((platform) => platform.top_posts ?? []);
  const unique = new Map();
  for (const post of posts) {
    let stableThumbnail = false;
    try {
      stableThumbnail = new URL(post.thumbnail_url).hostname === "buffer-media-uploads.s3.amazonaws.com";
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

export function validateCreativeDecision(research, decision, { appCaptures } = {}) {
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
    if (!["gymfeed_screenshot", "app_capture"].includes(treatment.opening_asset) || treatment.people_role !== "none" || treatment.people_screen_time_percent !== 0) {
      throw new Error("Product-led treatment must open on GymFeed UI and contain no generated people");
    }
  } else if (treatment.opening_asset !== "fal_video" || treatment.people_role === "none" || treatment.people_screen_time_percent === 0) {
    throw new Error("Human-led and hybrid treatments must open on a human fal.ai video sequence");
  }
  validateVideoProductionPlan(decision.video, { appCaptures });
  for (const [index, slide] of decision.instagram.slides.entries()) {
    if (slide.visual_type === "product_screenshot" && !slide.screenshot_ref) {
      throw new Error(`Instagram slide ${index + 1} requires a verified screenshot_ref`);
    }
    if (slide.visual_type !== "product_screenshot" && slide.screenshot_ref) {
      throw new Error(`Instagram slide ${index + 1} cannot combine ${slide.visual_type} with screenshot_ref`);
    }
  }
  return decision;
}

export function validateVideoProductionPlan(plan, { appCaptures } = {}) {
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
  if (duration < 15 || duration > 30) throw new Error(`Video scene duration must total 15-30 seconds; received ${duration}s`);
  if (productionV2 && Math.abs(duration - Number(plan.target_duration_seconds)) > 0.01) throw new Error("Scene durations must equal target_duration_seconds exactly");
  plan.target_duration_seconds = duration;
  if (plan.creative_treatment.visual_mode === "product_led" && generatedScenes > 0) {
    throw new Error("Product-led video cannot contain generated human footage");
  }
  if (plan.creative_treatment.visual_mode !== "product_led" && (generatedScenes < 1 || generatedScenes > 4)) {
    throw new Error("Human-led and hybrid videos require 1-4 deliberately connected generated shots");
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
  if (finalScene?.purpose !== "cta" || String(finalScene.overlay_text ?? "").trim().split(/\s+/).length < 5) {
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

  async daily(context, campaignDate = new Date()) {
    this.ensureConfigured();
    const [productBrief, screenshots, referenceScreens] = await Promise.all([
      loadProductBrief(),
      verifiedScreenshotManifest(),
      referenceScreenshotCatalog(),
    ]);
    const planningTimestamp = new Date().toISOString();
    const publicationDate = campaignDate.toISOString().slice(0, 10);
    const performanceThumbnails = topPerformanceThumbnails(context);
    const researchResponse = await this.client.responses.parse({
      model: this.config.OPENAI_DAILY_MODEL,
      reasoning: { effort: this.config.OPENAI_REASONING_EFFORT },
      tools: [{ type: "web_search" }],
      tool_choice: "auto",
      input: [
        { role: "system", content: TREND_RESEARCH_PROMPT },
        {
          role: "user",
          content: [
            { type: "input_text", text: `Planning timestamp: ${planningTimestamp}\nCampaign publication date: ${publicationDate}\n\nAUTHORITATIVE GYMFEED PRODUCT BRIEF:\n${productBrief}\n\nFIRST-PARTY GYMFEED PERFORMANCE CONTEXT:\n${compactContext(context)}\n\nThe attached images, when present, are thumbnails from the highest-ranked historical GymFeed posts in the Buffer context. Use them only to analyze transferable visual structure; do not reuse a person's likeness or copyrighted footage.` },
            ...performanceThumbnails.map((post) => ({
              type: "input_image",
              image_url: post.thumbnail_url,
              detail: "low",
            })),
          ],
        },
      ],
      text: { format: zodTextFormat(TrendResearchSchema, "gymfeed_trend_research") },
    });
    if (!researchResponse.output_parsed) throw new Error("OpenAI returned no parsed trend research");

    const decisionContext = `Planning timestamp: ${planningTimestamp}\nCampaign publication date: ${publicationDate}\n\nAUTHORITATIVE GYMFEED PRODUCT BRIEF:\n${productBrief}\n\nQUANTITATIVE TREND RESEARCH:\n${compactContext(researchResponse.output_parsed)}\n\nVERIFIED CURRENT-BUILD SCREENSHOT MANIFEST:\n${JSON.stringify(screenshots)}\n\nVERIFIED APP CAPTURE MANIFEST (recorded interactions only; an empty list means production assets are missing):\n${JSON.stringify(context.app_captures ?? [])}\n\nARCHIVE VISUAL REFERENCE FILENAMES (design reference only; never use as screenshot_refs or live-product proof):\n${JSON.stringify(referenceScreens)}\n\nFIRST-PARTY PERFORMANCE CONTEXT:\n${compactContext(context)}`;
    const decisionResponses = [];
    let decision = null;
    let validationError = null;
    for (let attempt = 1; attempt <= 2; attempt += 1) {
      const repairContext = attempt === 1 ? "" : `\n\nYOUR PREVIOUS PLAN WAS REJECTED BY DETERMINISTIC VALIDATION.\nReason: ${validationError.message}\n\nReturn a complete replacement plan, not commentary. Correct the exact violation under the production director requirements while preserving the evidence-backed campaign strategy. Keep the story meaningful, the source cuts valid, the audio timeline complete and the app_capture references real. Do not invent a missing asset or revert to the retired six-second talking-head template.\n\nREJECTED PLAN:\n${compactContext(decisionResponses.at(-1)?.output_parsed)}`;
      const response = await this.client.responses.parse({
        model: this.config.OPENAI_DAILY_MODEL,
        reasoning: { effort: this.config.OPENAI_REASONING_EFFORT },
        input: [
          { role: "system", content: DAILY_BRAIN_PROMPT },
          { role: "user", content: `${decisionContext}${repairContext}` },
        ],
        text: { format: zodTextFormat(CreativeDecisionSchema, "gymfeed_creative_decision") },
      });
      decisionResponses.push(response);
      try {
        if (!response.output_parsed) throw new Error("OpenAI returned no parsed creative decision");
        const normalized = {
          ...response.output_parsed,
          video: normalizeVideoPlan(response.output_parsed.video),
        };
        validateCreativeDecision(researchResponse.output_parsed, normalized, { appCaptures: context.app_captures ?? [] });
        decision = normalized;
        break;
      } catch (error) {
        validationError = error;
      }
    }
    if (!decision) throw validationError;
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
    const userContent = [
      { type: "input_text", text: `AUTHORITATIVE GYMFEED PRODUCT BRIEF:\n${productBrief}\n\nVERIFIED CURRENT-BUILD SCREENSHOT MANIFEST:\n${JSON.stringify(screenshots)}\n\nARCHIVE VISUAL REFERENCE FILENAMES (not valid live-product proof):\n${JSON.stringify(referenceScreens)}\n\nCONTENT RECORD AND PLAN:\n${compactContext(content)}` },
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

  async reviseContent(content, instructions, { app_captures = [] } = {}) {
    this.ensureConfigured();
    const [productBrief, screenshots] = await Promise.all([
      loadProductBrief(),
      verifiedScreenshotManifest(),
    ]);
    const isVideo = content.content_type === "video";
    const schema = isVideo ? VideoPlanSchema : InstagramPlanSchema;
    const response = await this.client.responses.parse({
      model: this.config.OPENAI_DAILY_MODEL,
      reasoning: { effort: this.config.OPENAI_REASONING_EFFORT },
      input: [
        { role: "system", content: CONTENT_REVISION_PROMPT },
        {
          role: "user",
          content: `CONTENT TYPE: ${isVideo ? "video" : "instagram"}\n\nREVIEWER INSTRUCTIONS:\n${instructions}\n\nAUTHORITATIVE GYMFEED PRODUCT BRIEF:\n${productBrief}\n\nVERIFIED CURRENT-BUILD SCREENSHOT MANIFEST:\n${JSON.stringify(screenshots)}\n\nVERIFIED APP CAPTURE MANIFEST:\n${JSON.stringify(app_captures)}\n\nREJECTED CONTENT RECORD:\n${compactContext(content)}`,
        },
      ],
      text: { format: zodTextFormat(schema, isVideo ? "gymfeed_video_revision" : "gymfeed_instagram_revision") },
    });
    if (!response.output_parsed) throw new Error("OpenAI returned no parsed content revision");
    const normalized = isVideo ? normalizeVideoPlan(response.output_parsed) : response.output_parsed;
    validateRevisedPlan(normalized, content.content_type, { appCaptures: app_captures });
    if (isVideo && !normalized.reviewer_instruction_map?.length) throw new Error("Video revision must map the reviewer's instructions to concrete changed scenes");
    return { data: normalized, costUsd: responseCost(response, this.config), responseId: response.id };
  }

  async sceneQualityReview(content, scene, visualUrls = []) {
    this.ensureConfigured();
    const response = await this.client.responses.parse({
      model: this.config.OPENAI_DAILY_MODEL,
      reasoning: { effort: this.config.OPENAI_REASONING_EFFORT },
      input: [
        { role: "system", content: SCENE_QA_PROMPT },
        {
          role: "user",
          content: [
            { type: "input_text", text: `CAMPAIGN CONTEXT:\n${compactContext(content)}\n\nSCENE SPECIFICATION:\n${compactContext(scene)}` },
            ...visualUrls.map((imageUrl) => ({ type: "input_image", image_url: imageUrl, detail: "high" })),
          ],
        },
      ],
      text: { format: zodTextFormat(SceneQualityReviewSchema, "gymfeed_scene_quality_review") },
    });
    if (!response.output_parsed) throw new Error("OpenAI returned no parsed scene quality review");
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
