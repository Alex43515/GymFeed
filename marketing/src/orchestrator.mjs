import { randomUUID } from "node:crypto";
import { overallQaScore } from "./contracts.mjs";
import { renderCarouselSlide } from "./render-carousel.mjs";
import { extractVideoAudio, extractVideoContactSheet, inspectVideo } from "./extract-video-frame.mjs";
import { renderProductSlide } from "./render-product-slide.mjs";
import { plannedVideoDuration, renderProductVideo } from "./render-product-video.mjs";
import { verifiedScreenshotUrl } from "./product-brief.mjs";
import { appCaptureCatalog, preflightAppCaptures, resolveAppCapture } from "./app-captures.mjs";
import { campaignSchedule } from "./campaign-schedule.mjs";

function utcDateKey(now = new Date()) {
  return now.toISOString().slice(0, 10);
}

function wait(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

function isoWeekKey(now = new Date()) {
  const date = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  date.setUTCDate(date.getUTCDate() + 4 - (date.getUTCDay() || 7));
  const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
  const week = Math.ceil((((date - yearStart) / 864e5) + 1) / 7);
  return `${date.getUTCFullYear()}-W${String(week).padStart(2, "0")}`;
}

export function referenceImagePrompt(content) {
  const plan = content.decision.content;
  const shot = plan.scenes?.find((scene) => scene.asset_type === "generated_video");
  const reference = plan.character_reference ?? {};
  return [
    "GYMFEED CAST, SET AND PROP CONTINUITY REFERENCE",
    "Photorealistic vertical 9:16 reference for an acted product story, not a poster. Show the starting state of the approved action.",
    `Fictional adult: ${reference.description ?? shot?.subject ?? "adult trainee"}`,
    `Wardrobe: ${reference.wardrobe ?? "plain unbranded training clothes"}`,
    `Location and background: ${reference.environment_anchor ?? shot?.environment}`,
    `Starting action and physical props: ${shot?.action}`,
    `Camera: ${shot?.camera}`,
    `Lighting: ${shot?.lighting}`,
    `Continuity: ${(reference.continuity_rules ?? []).join("; ")}`,
    "Props required by the action must exist from the start. A phone may show its unbranded back/edge only; the screen faces the actor.",
    "Natural adult anatomy, skin texture and safe physical action. No celebrity likeness or invented customer testimonial.",
    "No readable text, logos, watermark or fabricated GymFeed interface. Exact product footage and branding are composited later.",
  ].join("\n");
}

export function videoScenePrompt(content, scene, retryInstructions = null) {
  const plan = content.decision.content;
  const reference = plan.character_reference ?? {};
  const start = Number(scene.source_start_seconds ?? 0);
  const end = start + scene.duration_seconds;
  return [
    `GYMFEED DIRECTOR SHOT ${scene.scene_id} — ${scene.purpose}`,
    `One continuous ${scene.source_duration_seconds ?? scene.duration_seconds}s vertical 9:16 take at 24 fps. Final edit retains ${start.toFixed(1)}–${end.toFixed(1)}s; complete the intended action and any dialogue inside that interval with a clean ending.`,
    `Story: ${plan.concept}`,
    `Approved treatment: ${plan.creative_treatment?.visual_mode ?? "hybrid"}; ${plan.creative_treatment?.why_this_treatment ?? "execute the approved story"}`,
    `Audience hook: ${plan.hook}`,
    `Hook pattern: ${plan.creative_treatment?.hook_pattern ?? "problem, action, product proof, payoff"}`,
    `Subject: ${scene.subject}`,
    `VISIBLE ACTION (execute, do not replace with posing): ${scene.action}`,
    `Environment: ${scene.environment}`,
    `Camera and movement: ${scene.camera}`,
    `Lighting: ${scene.lighting}`,
    `Look: ${scene.visual_style}`,
    "<IMAGE_REF_0>, when supplied, is the cast/set/prop reference; preserve identity, clothes, room geometry and lighting. It is not a guaranteed first frame for reference-to-video.",
    `Cast: ${reference.description ?? scene.subject}. Wardrobe: ${reference.wardrobe ?? "unbranded"}.`,
    `Continuity: ${scene.continuity_notes}; ${(reference.continuity_rules ?? []).join("; ")}`,
    "Establish every handled prop before contact; preserve its shape, position and grip through the action. No appearing weights, teleporting objects, impossible joints or duplicated limbs. Phone screen faces actor unless a separately planned tracked composite exists.",
    scene.spoken_dialogue ? `EXACT dialogue, spoken once with natural lip sync: "${scene.spoken_dialogue}". No extra words. Finish before the retained cut ends.` : "No spoken dialogue. Tell the beat through the specified physical action and expression.",
    `Sound: ${scene.ambient_audio || "subtle natural room tone"}. Clean speech when specified; no music or captions baked into the source.`,
    "Do not generate GymFeed UI or branding. The editor inserts real app captures, exact logo, Poppins captions and CTA. Do not invent the app's functionality.",
    "Continuity errors, a missing story action or an unrelated static talking head are blocking defects; a beautiful frame is not a substitute.",
    content.decision?.review_instructions ? `Approved reviewer direction: ${content.decision.review_instructions}` : null,
    retryInstructions ? `Correct these shot defects while preserving all approved elements: ${retryInstructions}` : null,
  ].filter(Boolean).join("\n");
}

function withHashtags(text, hashtags = []) {
  const tags = hashtags.map((tag) => tag.startsWith("#") ? tag : `#${tag}`).join(" ");
  return [text, tags].filter(Boolean).join("\n\n");
}

function sceneScore(review) {
  const scores = Object.values(review.scores);
  return Math.round(scores.reduce((sum, value) => sum + value, 0) / scores.length);
}


function safeBackgroundPrompt(slide, reviewerInstructions = null) {
  const riskyObjects = /phone|screen|calendar|planner|notebook|paper|sign|clock|log|checklist|shoe|text|label|writing/i;
  const constraint = riskyObjects.test(slide.visual_prompt)
    ? "Represent any written, screen, calendar, or interface idea through physical action and composition; do not render that object or any readable/pseudo text."
    : "Do not add text, logos, watermarks, or fake interface elements.";
  return `${slide.visual_prompt}\nVisual role: ${slide.visual_type ?? "branded_graphic"}.\n${reviewerInstructions ? `Mandatory reviewer correction: ${reviewerInstructions}\n` : ""}${constraint}`;
}

function trackingUrl(base, platform, contentKey) {
  const url = new URL(base);
  url.searchParams.set("utm_source", platform);
  url.searchParams.set("utm_medium", "organic_social");
  url.searchParams.set("utm_campaign", "always_on_content");
  url.searchParams.set("utm_content", contentKey);
  return url.toString();
}

async function fetchAsset(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`download generated asset failed (${response.status})`);
  return {
    buffer: Buffer.from(await response.arrayBuffer()),
    contentType: response.headers.get("content-type")?.split(";")[0] ?? "application/octet-stream",
  };
}

export class MarketingOrchestrator {
  constructor({ config, repository, brain, mediaProvider, publisher, analyticsReporter, voiceProvider, approvalSheet, campaigns, appCaptureResolver = resolveAppCapture }) {
    this.config = config;
    this.repository = repository;
    this.brain = brain;
    this.mediaProvider = mediaProvider;
    this.publisher = publisher;
    this.analyticsReporter = analyticsReporter;
    this.voiceProvider = voiceProvider;
    this.approvalSheet = approvalSheet;
    this.campaigns = campaigns;
    this.appCaptureResolver = appCaptureResolver;
  }

  async sceneAudio(content) {
    const buffers = [];
    for (const scene of content.decision.content.scenes ?? []) {
      if (scene.audio_strategy !== "voiceover" || !scene.voiceover_text?.trim()) continue;
      const buffer = await this.createVoiceover({ ...content, decision: { ...content.decision, content: {
        ...content.decision.content, audio_mode: "ai_voiceover", voiceover_script: scene.voiceover_text,
      } } });
      buffers.push({ sceneId: scene.scene_id, buffer });
    }
    return buffers;
  }

  async finalTechnical(content, buffer) {
    const technical = await inspectVideo(buffer);
    const plan = content.decision.content;
    if (plan.production_version !== 2) return technical;
    const expected = (plan.scenes ?? []).map((scene) => scene.audio_strategy === "voiceover" ? scene.voiceover_text : scene.audio_strategy === "native" ? scene.spoken_dialogue : "").filter(Boolean).join(" ");
    const durationOk = Math.abs(technical.duration_seconds - plannedVideoDuration(plan)) <= 0.3;
    if (!expected) return { ...technical, retained_audio_checked: true, final_dialogue_match: true, duration_matches_plan: durationOk };
    if (!technical.has_audio || !this.voiceProvider?.transcribe) return { ...technical, retained_audio_checked: false, final_dialogue_match: false, duration_matches_plan: durationOk };
    const reservation = await this.repository.reserveCost("openai", this.config.OPENAI_ESTIMATED_TRANSCRIPTION_COST_USD ?? 0.01, { contentId: content.id, runId: content.run_id, metadata: { operation: "final-edit-audio-verification" } });
    try {
      const audio = await extractVideoAudio(buffer);
      const transcript = await this.voiceProvider.transcribe({ buffer: audio });
      await this.repository.settleCost(reservation, this.config.OPENAI_ESTIMATED_TRANSCRIPTION_COST_USD ?? 0.01, transcript.requestId);
      const normalize = (value) => String(value).toLowerCase().replace(/[^\p{L}\p{N}]+/gu, " ").trim();
      return { ...technical, final_transcript: transcript.text, expected_dialogue: expected, retained_audio_checked: true, final_dialogue_match: normalize(transcript.text) === normalize(expected), duration_matches_plan: durationOk };
    } catch (error) { await this.repository.releaseCost(reservation).catch(() => {}); throw error; }
  }

  async createVoiceover(content) {
    const plan = content.decision.content;
    if (plan.audio_mode !== "ai_voiceover" || !plan.voiceover_script?.trim()) return null;
    if (!this.voiceProvider) throw new Error("The content requests AI voiceover, but no voice provider is configured");
    const reservationId = await this.repository.reserveCost("openai", this.config.OPENAI_ESTIMATED_TTS_COST_USD, {
      contentId: content.id,
      runId: content.run_id,
      metadata: { operation: "voiceover", model: this.config.OPENAI_TTS_MODEL },
    });
    try {
      const generated = await this.voiceProvider.generate({ text: plan.voiceover_script });
      await this.repository.settleCost(reservationId, this.config.OPENAI_ESTIMATED_TTS_COST_USD, generated.requestId);
      return generated.buffer;
    } catch (error) {
      await this.repository.releaseCost(reservationId);
      throw error;
    }
  }

  async decisionContext() {
    const context = await this.repository.loadContext();
    const [ga4, buffer] = await Promise.all([
      this.analyticsReporter
        ? this.analyticsReporter.summary()
        : Promise.resolve({ status: "not_configured" }),
      this.publisher?.performanceSummary
        ? this.publisher.performanceSummary().catch((error) => ({ status: "error", message: error.message }))
        : Promise.resolve({ status: "not_configured" }),
    ]);
    return {
      ...context,
      ga4,
      buffer,
      app_captures: await appCaptureCatalog(),
    };
  }

  async runDaily(now = new Date(), { revision = 1, campaignId = null } = {}) {
    if (!Number.isInteger(revision) || revision < 1 || revision > 999) throw new Error("Daily revision must be an integer from 1 to 999");
    const dailyKey = revision === 1
      ? `daily:${utcDateKey(now)}`
      : `daily:${utcDateKey(now)}:r${String(revision).padStart(3, "0")}`;
    const idempotencyKey = campaignId ? `campaign:${campaignId}:${dailyKey}` : dailyKey;
    const { run, reused } = await this.repository.startRun("daily-cmo", idempotencyKey, { now: now.toISOString(), revision });
    if (reused) return { reused: true, run };

    let reservationId;
    try {
      const brand = await this.repository.brandConfig();
      if (!brand.enabled) {
        return { reused: false, run: await this.repository.finishRun(run.id, "skipped", { reason: "marketing disabled" }) };
      }
      reservationId = await this.repository.reserveCost("openai", this.config.OPENAI_ESTIMATED_DAILY_COST_USD, { runId: run.id, metadata: { operation: "daily-cmo" } });
      const context = await this.decisionContext();
      if (campaignId) context.campaign = await this.campaigns.status(campaignId);
      const result = await this.brain.daily(context, now);
      const content = await this.repository.saveDailyDecision(run.id, result.data, now, revision, campaignId);
      await this.repository.settleCost(reservationId, result.costUsd, result.responseId);
      const completed = await this.repository.finishRun(run.id, "succeeded", {
        decision: result.data,
        content_ids: content.map((item) => item.id),
      }, result.costUsd);
      return { reused: false, run: completed, content };
    } catch (error) {
      if (reservationId) {
        try { await this.repository.releaseCost(reservationId); } catch (_) { /* preserve root error */ }
      }
      await this.repository.finishRun(run.id, "failed", {}, null, error.message);
      throw error;
    }
  }

  async runWeekly(now = new Date()) {
    const { run, reused } = await this.repository.startRun("weekly-cmo", `weekly:${isoWeekKey(now)}`, { now: now.toISOString() });
    if (reused) return { reused: true, run };
    let reservationId;
    try {
      const brand = await this.repository.brandConfig();
      if (!brand.enabled) {
        return { reused: false, run: await this.repository.finishRun(run.id, "skipped", { reason: "marketing disabled" }) };
      }
      reservationId = await this.repository.reserveCost("openai", this.config.OPENAI_ESTIMATED_WEEKLY_COST_USD, { runId: run.id, metadata: { operation: "weekly-cmo" } });
      const result = await this.brain.weekly(await this.decisionContext());
      const learnings = await this.repository.saveWeeklyReview(run.id, result.data);
      await this.repository.settleCost(reservationId, result.costUsd, result.responseId);
      const completed = await this.repository.finishRun(run.id, "succeeded", { review: result.data, learning_ids: learnings.map((item) => item.id) }, result.costUsd);
      return { reused: false, run: completed, learnings };
    } catch (error) {
      if (reservationId) {
        try { await this.repository.releaseCost(reservationId); } catch (_) { /* preserve root error */ }
      }
      await this.repository.finishRun(run.id, "failed", {}, null, error.message);
      throw error;
    }
  }

  async generateContent(id) {
    const content = await this.repository.contentById(id);
    if (content.status !== "planned" && content.status !== "failed") {
      return { skipped: true, reason: `status is ${content.status}`, content };
    }
    if (!this.config.GENERATE_ASSETS) return { skipped: true, reason: "asset generation disabled", content };
    if (this.campaigns) await this.campaigns.assertGenerationAllowed(id);
    if (content.content_type === "video") await preflightAppCaptures(content.decision.content, this.appCaptureResolver);
    if (content.content_type === "video" && content.status === "failed") {
      const resumed = await this.resumeFailedVideoScene(content);
      if (resumed) return resumed;
    }
    return content.content_type === "video" ? this.generateVideo(content) : this.generateInstagramAsset(content);
  }

  async resumeFailedVideoScene(content) {
    const generation = { ...(content.decision?.generation ?? {}) };
    const sceneRecords = [...(generation.scenes ?? [])];
    const maximumAttempts = this.config.FAL_SCENE_MAX_ATTEMPTS ?? 2;
    const retryableIndexes = sceneRecords
      .map((scene, index) => ({ scene, index }))
      .filter(({ scene }) => scene.asset_type === "generated_video"
        && scene.status === "qa_failed"
        && Number(scene.attempt ?? 0) < maximumAttempts);
    if (!retryableIndexes.length) return null;

    const sceneSpecs = new Map((content.decision.content.scenes ?? []).map((scene) => [scene.scene_id, scene]));
    for (const { scene: record, index } of retryableIndexes) {
      const sceneSpec = sceneSpecs.get(record.scene_id);
      if (!sceneSpec) throw new Error(`Cannot resume missing scene specification: ${record.scene_id}`);
      const retry = await this.queueVideoScene(
        content,
        sceneSpec,
        generation.reference_image_url,
        Number(record.attempt ?? 0) + 1,
        record.qa?.retry_prompt || record.qa?.required_fixes?.join("; ") || "Correct the previous continuity defects.",
      );
      sceneRecords[index] = {
        ...retry,
        history: [...(record.history ?? []), {
          attempt: record.attempt,
          asset_url: record.asset_url,
          contact_sheet_url: record.contact_sheet_url,
          qa_score: record.qa_score,
          qa: record.qa,
        }],
      };
    }

    generation.scenes = sceneRecords;
    const pendingTask = sceneRecords.find((scene) => scene.status === "queued");
    const updated = await this.repository.updateContent(content.id, {
      status: "generating",
      provider: "fal-gemini-omni-reference+gymfeed-edit",
      provider_task_id: pendingTask?.task_id ?? null,
      failure_reason: null,
      decision: { ...content.decision, generation },
    });
    return { skipped: false, pending: true, resumed: true, content: updated, tasks: retryableIndexes.length };
  }

  async generateInstagramAsset(content) {
    if (this.campaigns) await this.campaigns.assertGenerationAllowed(content.id);
    const slides = content.decision.content.slides;
    try {
      await this.repository.updateContent(content.id, { status: "generating", provider: "gymfeed-product-template", failure_reason: null });
      const urls = [];
      const generationId = randomUUID();
      for (let index = 0; index < slides.length; index += 1) {
        const slide = slides[index];
        if (slide.visual_type === "product_screenshot" && !slide.screenshot_ref) {
          throw new Error(`Slide ${index + 1} requests a product screenshot without a verified screenshot_ref`);
        }
        const screenshotUrl = slide.screenshot_ref ? await verifiedScreenshotUrl(slide.screenshot_ref) : null;
        let backgroundBuffer = null;
        if (!screenshotUrl) {
          const reservationId = await this.repository.reserveCost("fal", this.config.FAL_ESTIMATED_IMAGE_COST_USD, {
            contentId: content.id,
            runId: content.run_id,
            metadata: { operation: "carousel-background", slide: index + 1 },
          });
          try {
            const generated = await this.mediaProvider.generateBackground(safeBackgroundPrompt(slide, content.decision?.review_instructions));
            backgroundBuffer = generated.buffer;
            await this.repository.settleCost(reservationId, this.config.FAL_ESTIMATED_IMAGE_COST_USD, generated.raw?.requestId ?? null);
          } catch (error) {
            await this.repository.releaseCost(reservationId);
            throw error;
          }
        }
        const rendered = await renderProductSlide({
          headline: slide.headline,
          body: slide.body,
          feature: slide.feature ?? content.decision.content.product_features?.[0] ?? "connected_ecosystem",
          cta: content.decision.content.cta,
          index,
          total: slides.length,
          screenshotUrl,
          backgroundBuffer,
        });
        urls.push(await this.repository.uploadAsset(`${content.content_key}/${generationId}/slide-${index + 1}.png`, rendered, "image/png"));
      }
      const updated = await this.repository.updateContent(content.id, { status: "generated", asset_urls: urls });
      return { skipped: false, content: updated };
    } catch (error) {
      await this.repository.updateContent(content.id, { status: "failed", failure_reason: error.message });
      throw error;
    }
  }

  async runDailyBatch(startDate = new Date(), { days = 3, revision = 1 } = {}) {
    if (!Number.isInteger(days) || days < 1 || days > 7) throw new Error("Batch days must be an integer from 1 to 7");
    if (Number.isNaN(startDate.getTime())) throw new Error("Batch start date must be a valid date");
    const startKey = startDate.toISOString().slice(0, 10);
    const campaigns = [];
    const contentIds = [];
    for (let offset = 0; offset < days; offset += 1) {
      const campaignDate = new Date(`${startKey}T12:00:00.000Z`);
      campaignDate.setUTCDate(campaignDate.getUTCDate() + offset);
      const result = await this.runDaily(campaignDate, { revision });
      const ids = result.content?.map((content) => content.id) ?? result.run?.output?.content_ids ?? [];
      if (!ids.length) throw new Error(`Daily CMO returned no content IDs for ${utcDateKey(campaignDate)}`);
      campaigns.push({
        campaign_date: utcDateKey(campaignDate),
        run_id: result.run?.id ?? null,
        reused: Boolean(result.reused),
        content_ids: ids,
      });
      contentIds.push(...ids);
    }
    return { start_date: startKey, days, revision, campaigns, content_ids: contentIds };
  }

  async queueVideoScene(content, scene, referenceImageUrl, attempt = 1, retryInstructions = null) {
    const sourceDuration = scene.source_duration_seconds ?? scene.duration_seconds;
    const estimatedCost = Number((sourceDuration * this.config.FAL_VIDEO_USD_PER_SECOND).toFixed(6));
    const reservationId = await this.repository.reserveCost("fal", estimatedCost, {
      contentId: content.id,
      runId: content.run_id,
      metadata: {
        operation: "campaign-video-scene",
        scene_id: scene.scene_id,
        attempt,
        duration_seconds: sourceDuration,
        edit_duration_seconds: scene.duration_seconds,
      },
    });
    try {
      const task = await this.mediaProvider.createTask({
        prompt: videoScenePrompt(content, scene, retryInstructions),
        durationSeconds: sourceDuration,
        generateAudio: ["native_audio", "ambient_plus_captions", "mixed"].includes(content.decision.content.audio_mode),
        referenceImageUrls: referenceImageUrl ? [referenceImageUrl] : [],
      });
      return {
        scene_id: scene.scene_id,
        asset_type: "generated_video",
        status: "queued",
        attempt,
        task_id: task.id,
        model: task.model,
        reservation_id: reservationId,
        estimated_cost_usd: estimatedCost,
        asset_url: null,
        contact_sheet_url: null,
        technical: null,
        qa: null,
        history: [],
      };
    } catch (error) {
      try { await this.repository.releaseCost(reservationId); } catch (_) { /* preserve provider error */ }
      throw error;
    }
  }

  async generateVideo(content) {
    if (this.campaigns) await this.campaigns.assertGenerationAllowed(content.id);
    const plan = content.decision.content;
    await preflightAppCaptures(plan, this.appCaptureResolver);
    const plannedScenes = plan.scenes ?? [];
    const generatedSceneSpecs = plannedScenes.filter((scene) => (scene.asset_type ?? "generated_video") === "generated_video");
    try {
      if (!generatedSceneSpecs.length) {
        await this.repository.updateContent(content.id, {
          status: "generating",
          provider: "gymfeed-product-motion",
          provider_task_id: null,
          failure_reason: null,
        });
        const voiceoverBuffer = await this.createVoiceover(content);
        const renderedVideo = await renderProductVideo(plan, { voiceoverBuffer, sceneVoiceoverBuffers: await this.sceneAudio(content), appCaptureResolver: this.appCaptureResolver });
        const version = randomUUID();
        const storedVideo = await this.repository.uploadAsset(`${content.content_key}/${version}/video.mp4`, renderedVideo, "video/mp4");
        const duration = plannedVideoDuration(plan);
        const frame = await extractVideoContactSheet(renderedVideo, duration, 16);
        const thumbnailUrl = await this.repository.uploadAsset(`${content.content_key}/${version}/contact-sheet-16.jpg`, frame, "image/jpeg");
        const technical = await this.finalTechnical(content, renderedVideo);
        const updated = await this.repository.updateContent(content.id, {
          status: "generated",
          asset_urls: [storedVideo],
          thumbnail_url: thumbnailUrl,
          decision: {
            ...content.decision,
            generation: { mode: "product_led", scenes: [], final_technical: technical },
          },
        });
        return { skipped: false, pending: false, content: updated };
      }

      const generationId = randomUUID();
      let referenceImageUrl = null;
      if (plan.character_reference?.required) {
        const referenceReservationId = await this.repository.reserveCost("fal", this.config.FAL_ESTIMATED_IMAGE_COST_USD, {
          contentId: content.id,
          runId: content.run_id,
          metadata: { operation: "campaign-character-reference" },
        });
        let reference;
        try {
          reference = await this.mediaProvider.generateReferenceImage(referenceImagePrompt(content));
          await this.repository.settleCost(referenceReservationId, this.config.FAL_ESTIMATED_IMAGE_COST_USD, reference.raw?.requestId ?? null);
        } catch (error) {
          try { await this.repository.releaseCost(referenceReservationId); } catch (_) { /* preserve provider error */ }
          throw error;
        }
        referenceImageUrl = await this.repository.uploadAsset(
          `${content.content_key}/${generationId}/character-reference.png`,
          reference.buffer,
          reference.mimeType ?? "image/png",
        );
      }
      const sceneRecords = [];
      for (const scene of plannedScenes) {
        if ((scene.asset_type ?? "generated_video") === "generated_video") {
          sceneRecords.push(await this.queueVideoScene(content, scene, referenceImageUrl));
        } else {
          sceneRecords.push({
            scene_id: scene.scene_id,
            asset_type: scene.asset_type,
            status: "ready",
            attempt: 0,
            screenshot_ref: scene.screenshot_ref,
            capture_ref: scene.capture_ref,
          });
        }
      }
      const firstPending = sceneRecords.find((scene) => scene.task_id);
      const updated = await this.repository.updateContent(content.id, {
        status: "generating",
        provider: "fal-gemini-omni-reference+gymfeed-edit",
        provider_task_id: firstPending?.task_id ?? null,
        failure_reason: null,
        decision: {
          ...content.decision,
          generation: {
            mode: "multi_scene_reference",
            generation_id: generationId,
            reference_image_url: referenceImageUrl,
            scenes: sceneRecords,
          },
        },
      });
      return { skipped: false, pending: true, content: updated, tasks: sceneRecords.filter((scene) => scene.task_id) };
    } catch (error) {
      await this.repository.updateContent(content.id, { status: "failed", failure_reason: error.message });
      throw error;
    }
  }

  async refreshContent(id) {
    let content = await this.repository.contentById(id);
    if (content.content_type !== "video" || content.status !== "generating") {
      return { skipped: true, reason: "content has no active video generation", content };
    }
    if (this.campaigns) await this.campaigns.assertGenerationAllowed(id);
    const plan = content.decision.content;
    const generation = { ...(content.decision.generation ?? {}) };
    let sceneRecords = [...(generation.scenes ?? [])];
    if (!sceneRecords.length && content.provider_task_id) {
      const legacyScene = plan.scenes[0];
      sceneRecords = [{
        scene_id: legacyScene.scene_id ?? "legacy-opening",
        asset_type: "generated_video",
        status: "queued",
        attempt: 1,
        task_id: content.provider_task_id,
        model: this.config.FAL_VIDEO_MODEL,
        reservation_id: generation.fal_reservation_id ?? null,
        estimated_cost_usd: generation.estimated_cost_usd
          ?? Number((legacyScene.duration_seconds * this.config.FAL_VIDEO_USD_PER_SECOND).toFixed(6)),
        history: [],
      }];
    }
    if (!sceneRecords.length) return { skipped: true, reason: "video generation has no scene tasks", content };

    const sceneSpecs = new Map((plan.scenes ?? []).map((scene, index) => [scene.scene_id ?? (index === 0 ? "legacy-opening" : `scene-${index + 1}`), scene]));
    const taskResults = [];
    for (let index = 0; index < sceneRecords.length; index += 1) {
      const record = sceneRecords[index];
      if (record.asset_type !== "generated_video" || !["queued", "running"].includes(record.status)) continue;
      const task = await this.mediaProvider.getTask(record.task_id, record.model);
      taskResults.push({ scene_id: record.scene_id, task });
      const status = String(task.status ?? "").toLowerCase();
      if (["queued", "running", "processing", "pending"].includes(status)) {
        sceneRecords[index] = { ...record, status: status === "queued" ? "queued" : "running" };
        continue;
      }
      if (status !== "succeeded") {
        const reason = task.error?.message ?? task.message ?? `fal.ai task ${status || "failed"}`;
        if (record.reservation_id) {
          try { await this.repository.releaseCost(record.reservation_id); } catch (_) { /* preserve provider failure */ }
        }
        sceneRecords[index] = { ...record, status: "failed", failure_reason: reason };
        continue;
      }
      const videoUrl = task.content?.video_url ?? task.output?.video_url;
      if (!videoUrl) throw new Error(`fal.ai scene ${record.scene_id} succeeded without a video URL`);
      const video = await fetchAsset(videoUrl);
      const sceneSpec = sceneSpecs.get(record.scene_id) ?? plan.scenes[0];
      const version = `${generation.generation_id ?? content.provider_task_id}/${record.scene_id}/attempt-${record.attempt}`;
      const assetUrl = await this.repository.uploadAsset(`${content.content_key}/${version}/raw.mp4`, video.buffer, video.contentType);
      const contactSheet = await extractVideoContactSheet(video.buffer, sceneSpec.source_duration_seconds ?? sceneSpec.duration_seconds, 9);
      const contactSheetUrl = await this.repository.uploadAsset(`${content.content_key}/${version}/contact-sheet-9.jpg`, contactSheet, "image/jpeg");
      let technical = await inspectVideo(video.buffer);
      if (sceneSpec.spoken_dialogue?.trim()) {
        if (!technical.has_audio) {
          technical = { ...technical, expected_dialogue: sceneSpec.spoken_dialogue, transcript: "", dialogue_match: false };
        } else if (this.voiceProvider?.transcribe) {
          const transcriptionReservationId = await this.repository.reserveCost(
            "openai",
            this.config.OPENAI_ESTIMATED_TRANSCRIPTION_COST_USD ?? 0.01,
            {
              contentId: content.id,
              runId: content.run_id,
              metadata: { operation: "creator-dialogue-transcription", scene_id: record.scene_id, attempt: record.attempt },
            },
          );
          try {
            const audio = await extractVideoAudio(video.buffer, { startSeconds: sceneSpec.source_start_seconds ?? 0, durationSeconds: sceneSpec.duration_seconds });
            const transcription = await this.voiceProvider.transcribe({ audioBuffer: audio, buffer: audio });
            const normalize = (value) => String(value ?? "").toLowerCase().replace(/[^a-z0-9\s]/g, " ").replace(/\s+/g, " ").trim();
            technical = {
              ...technical,
              expected_dialogue: sceneSpec.spoken_dialogue,
              transcript: transcription.text,
              dialogue_match: normalize(transcription.text) === normalize(sceneSpec.spoken_dialogue),
            };
            await this.repository.settleCost(
              transcriptionReservationId,
              this.config.OPENAI_ESTIMATED_TRANSCRIPTION_COST_USD ?? 0.01,
              transcription.requestId,
            );
          } catch (error) {
            try { await this.repository.releaseCost(transcriptionReservationId); } catch (_) { /* preserve transcription failure */ }
            throw error;
          }
        }
      }
      if (record.reservation_id) {
        await this.repository.settleCost(record.reservation_id, record.estimated_cost_usd, record.task_id);
      }
      sceneRecords[index] = { ...record, status: "generated", asset_url: assetUrl, contact_sheet_url: contactSheetUrl, technical, failure_reason: null };
    }

    generation.scenes = sceneRecords;
    content = await this.repository.updateContent(content.id, {
      decision: { ...content.decision, generation },
      provider_task_id: sceneRecords.find((scene) => ["queued", "running"].includes(scene.status))?.task_id ?? null,
    });
    if (sceneRecords.some((scene) => ["queued", "running"].includes(scene.status))) {
      return { skipped: false, pending: true, content, tasks: taskResults };
    }
    const providerFailure = sceneRecords.find((scene) => scene.status === "failed");
    if (providerFailure) {
      const failed = await this.repository.updateContent(content.id, {
        status: "failed",
        provider_task_id: null,
        failure_reason: `${providerFailure.scene_id}: ${providerFailure.failure_reason}`,
      });
      return { skipped: false, pending: false, content: failed, tasks: taskResults };
    }

    let queuedRetry = false;
    for (let index = 0; index < sceneRecords.length; index += 1) {
      const record = sceneRecords[index];
      if (record.asset_type !== "generated_video" || record.status !== "generated") continue;
      const sceneSpec = sceneSpecs.get(record.scene_id) ?? plan.scenes[0];
      const reservationId = await this.repository.reserveCost("openai", this.config.OPENAI_ESTIMATED_QA_COST_USD ?? 0.15, {
        contentId: content.id,
        runId: content.run_id,
        metadata: { operation: "scene-qa", scene_id: record.scene_id, attempt: record.attempt },
      });
      let result;
      try {
        result = await this.brain.sceneQualityReview(content, sceneSpec, [record.contact_sheet_url]);
        await this.repository.settleCost(reservationId, result.costUsd, result.responseId);
      } catch (error) {
        try { await this.repository.releaseCost(reservationId); } catch (_) { /* preserve root error */ }
        throw error;
      }
      const score = sceneScore(result.data);
      const accepted = result.data.accept
        && score >= (this.config.FAL_SCENE_QA_THRESHOLD ?? 88)
        && Number(result.data.scores.scene_match ?? 0) >= 85
        && Number(result.data.scores.motion_continuity ?? 0) >= 85
        && (!sceneSpec.spoken_dialogue?.trim() || record.technical?.dialogue_match === true);
      if (accepted) {
        sceneRecords[index] = { ...record, status: "qa_passed", qa_score: score, qa: result.data };
        continue;
      }
      if (record.attempt >= (this.config.FAL_SCENE_MAX_ATTEMPTS ?? 3)) {
        sceneRecords[index] = { ...record, status: "qa_failed", qa_score: score, qa: result.data };
        continue;
      }
      const retry = await this.queueVideoScene(
        content,
        sceneSpec,
        generation.reference_image_url,
        record.attempt + 1,
        result.data.retry_prompt || result.data.required_fixes.join("; "),
      );
      sceneRecords[index] = {
        ...retry,
        history: [...(record.history ?? []), {
          attempt: record.attempt,
          asset_url: record.asset_url,
          contact_sheet_url: record.contact_sheet_url,
          qa_score: score,
          qa: result.data,
        }],
      };
      queuedRetry = true;
    }

    generation.scenes = sceneRecords;
    if (sceneRecords.some((scene) => scene.status === "qa_failed")) {
      const failedScenes = sceneRecords.filter((scene) => scene.status === "qa_failed").map((scene) => scene.scene_id);
      const failed = await this.repository.updateContent(content.id, {
        status: "failed",
        provider_task_id: null,
        failure_reason: `Scene QA failed after maximum attempts: ${failedScenes.join(", ")}`,
        decision: { ...content.decision, generation },
      });
      return { skipped: false, pending: false, content: failed };
    }
    if (queuedRetry) {
      const pendingTask = sceneRecords.find((scene) => scene.status === "queued");
      const updated = await this.repository.updateContent(content.id, {
        status: "generating",
        provider_task_id: pendingTask?.task_id ?? null,
        decision: { ...content.decision, generation },
      });
      return { skipped: false, pending: true, content: updated, retrying: true };
    }

    const generatedRecords = sceneRecords.filter((scene) => scene.asset_type === "generated_video");
    const sceneVideoBuffers = [];
    for (const record of generatedRecords) {
      const downloaded = await fetchAsset(record.asset_url);
      sceneVideoBuffers.push({ sceneId: record.scene_id, buffer: downloaded.buffer, localTreatment: record.local_treatment ?? null });
    }
    const voiceoverBuffer = await this.createVoiceover(content);
    const renderOptions = plan.scenes.some((scene) => scene.asset_type)
      ? { sceneVideoBuffers, voiceoverBuffer }
      : { supportingVideoBuffer: sceneVideoBuffers[0]?.buffer ?? null, voiceoverBuffer };
    const renderedVideo = await renderProductVideo(plan, { ...renderOptions, sceneVoiceoverBuffers: await this.sceneAudio(content), appCaptureResolver: this.appCaptureResolver });
    const version = generation.generation_id ?? randomUUID();
    const storedVideo = await this.repository.uploadAsset(`${content.content_key}/${version}/final-video.mp4`, renderedVideo, "video/mp4");
    const duration = plannedVideoDuration(plan);
    const contactSheet = await extractVideoContactSheet(renderedVideo, duration, 16);
    const thumbnailUrl = await this.repository.uploadAsset(`${content.content_key}/${version}/final-contact-sheet-16.jpg`, contactSheet, "image/jpeg");
    generation.final_technical = await this.finalTechnical(content, renderedVideo);
    const updated = await this.repository.updateContent(content.id, {
      status: "generated",
      provider_task_id: null,
      asset_urls: [storedVideo],
      thumbnail_url: thumbnailUrl,
      failure_reason: null,
      decision: { ...content.decision, generation },
    });
    return { skipped: false, pending: false, content: updated };
  }

  async reviewContent(id) {
    const content = await this.repository.contentById(id);
    if (content.status !== "generated" && content.status !== "qa_failed") {
      return { skipped: true, reason: `status is ${content.status}`, content };
    }
    const visuals = content.content_type === "video" ? [content.thumbnail_url].filter(Boolean) : content.asset_urls;
    const reservationId = await this.repository.reserveCost("openai", this.config.OPENAI_ESTIMATED_DAILY_COST_USD, { contentId: content.id, runId: content.run_id, metadata: { operation: "qa" } });
    try {
      const result = await this.brain.qualityReview(content, visuals);
      await this.repository.settleCost(reservationId, result.costUsd, result.responseId);
      const score = overallQaScore(result.data);
      const brand = await this.repository.brandConfig();
      const passed = result.data.publish && score >= brand.minimum_qa_score;
      const updated = await this.repository.updateContent(content.id, {
        status: passed ? "awaiting_approval" : "qa_failed",
        qa_score: score,
        qa: result.data,
        failure_reason: passed ? null : result.data.critical_issues.join("; ") || "QA threshold not met",
      });
      return { skipped: false, passed, content: updated };
    } catch (error) {
      try { await this.repository.releaseCost(reservationId); } catch (_) { /* preserve root error */ }
      throw error;
    }
    if (content.content_type === "video" && content.decision.content.production_version === 2) {
      const technical = content.decision.generation?.final_technical;
      if (!technical?.final_dialogue_match || !technical?.duration_matches_plan) {
        return { skipped: false, passed: false, content: await this.repository.updateContent(id, { status: "qa_failed", failure_reason: "Final edited audio or duration does not match the approved plan. Review the retained cut before asset approval." }) };
      }
    }
  }

  async processContentToReview(id, { pollIntervalMs = 15_000, maxWaitMs = 15 * 60_000 } = {}) {
    if (!Number.isFinite(pollIntervalMs) || pollIntervalMs < 0) throw new Error("pollIntervalMs must be zero or greater");
    if (!Number.isFinite(maxWaitMs) || maxWaitMs <= 0) throw new Error("maxWaitMs must be greater than zero");

    const startedAt = Date.now();
    const stages = [];
    let content = await this.repository.contentById(id);
    const completeStatuses = new Set(["awaiting_approval", "approved", "scheduled", "published"]);

    if (completeStatuses.has(content.status)) {
      return {
        skipped: true,
        pending: false,
        reason: `content already reached ${content.status}`,
        content,
        stages,
      };
    }
    if (content.status === "qa_failed") {
      return {
        skipped: true,
        pending: false,
        reason: "content is waiting for reviewer revision instructions",
        content,
        stages,
      };
    }

    if (["planned", "failed"].includes(content.status)) {
      const generation = await this.generateContent(id);
      stages.push({ stage: "generate", result: generation });
      content = generation.content ?? await this.repository.contentById(id);
    }

    while (content.status === "generating") {
      if (!content.provider_task_id) {
        return {
          skipped: true,
          pending: false,
          reason: "content is generating without an active fal.ai task",
          content,
          stages,
        };
      }
      if (Date.now() - startedAt >= maxWaitMs) {
        return {
          skipped: false,
          pending: true,
          timedOut: true,
          reason: `fal.ai was still processing after ${maxWaitMs}ms`,
          content,
          stages,
        };
      }
      if (pollIntervalMs > 0) await wait(pollIntervalMs);
      const refresh = await this.refreshContent(id);
      stages.push({ stage: "refresh", result: refresh });
      content = refresh.content ?? await this.repository.contentById(id);
      if (refresh.skipped && content.status === "generating") {
        return {
          skipped: true,
          pending: false,
          reason: refresh.reason ?? "fal.ai refresh was skipped",
          content,
          stages,
        };
      }
    }

    if (content.status === "generated") {
      const review = await this.reviewContent(id);
      stages.push({ stage: "qa", result: review });
      content = review.content ?? await this.repository.contentById(id);
      return {
        skipped: false,
        pending: false,
        passed: review.passed,
        content,
        stages,
      };
    }

    return {
      skipped: false,
      pending: false,
      passed: false,
      reason: content.failure_reason ?? `content stopped in ${content.status}`,
      content,
      stages,
    };
  }

  async approveContent(id) {
    const content = await this.repository.contentById(id);
    if (content.status !== "awaiting_approval") return { skipped: true, reason: `status is ${content.status}`, content };
    return { skipped: false, content: await this.repository.updateContent(id, { status: "approved", approved_at: new Date().toISOString() }) };
  }

  async reviseRejectedContent(id, instructions) {
    const content = await this.repository.contentById(id);
    if (!["awaiting_approval", "qa_failed"].includes(content.status)) {
      return { skipped: true, reason: `status is ${content.status}`, content };
    }
    if (!instructions || instructions.trim().length < 5) {
      throw new Error("Reject requires specific revision instructions");
    }
    let reservationId;
    try {
      reservationId = await this.repository.reserveCost("openai", this.config.OPENAI_ESTIMATED_DAILY_COST_USD, {
        contentId: content.id,
        runId: content.run_id,
        metadata: { operation: "reviewer-revision", revision: Number(content.decision?.review_revision ?? 1) + 1 },
      });
      const revised = await this.brain.reviseContent(content, instructions.trim());
      await this.repository.settleCost(reservationId, revised.costUsd, revised.responseId);
      const reset = await this.repository.resetContentForRevision(content, revised.data, instructions.trim());
      return { skipped: false, content: reset };
    } catch (error) {
      if (reservationId) {
        try { await this.repository.releaseCost(reservationId); } catch (_) { /* preserve root error */ }
      }
      throw error;
    }
  }

  async rejectContent(id, instructions) {
    const revised = await this.reviseRejectedContent(id, instructions);
    let generation;
    try {
      generation = await this.generateContent(id);
    } catch (error) {
      generation = { skipped: false, error: error.message, content: await this.repository.contentById(id) };
    }
    return { ...revised, content: await this.repository.contentById(id), generation };
  }

  async syncApprovalContent() {
    if (!this.approvalSheet?.configured) {
      return { skipped: true, reason: "Google Sheets approval queue is not configured" };
    }
    const content = await this.repository.approvalSheetContent();
    return { skipped: false, sync: await this.approvalSheet.syncContent(content) };
  }

  async claimApprovalSheetDecisions() {
    if (!this.approvalSheet?.configured) {
      return { skipped: true, reason: "Google Sheets approval queue is not configured", decisions: [] };
    }
    await this.syncApprovalContent();
    const pending = await this.approvalSheet.pendingDecisions();
    const decisions = [];
    const errors = [];
    for (const entry of pending) {
      try {
        const content = await this.repository.contentById(entry.contentId);
        const currentRevision = Number(content.decision?.review_revision ?? 1);
        if (currentRevision !== entry.revision) throw new Error(`Stale sheet revision ${entry.revision}; current revision is ${currentRevision}`);
        if (entry.decision === "Reject" && entry.instructions.trim().length < 5) {
          throw new Error("Add specific revision instructions before selecting Reject");
        }
        const { review, reused } = await this.repository.createContentReview({
          contentId: entry.contentId,
          revision: entry.revision,
          decision: entry.decision.toLowerCase(),
          instructions: entry.instructions,
          sourceRef: `row:${entry.rowNumber}`,
        });
        if (reused) continue;
        await this.approvalSheet.setProcessingResult(entry.rowNumber, "Queued for the main CMO orchestrator", "");
        decisions.push({ ...entry, reviewId: review.id, mode: "sheet_decision" });
      } catch (error) {
        await this.approvalSheet.setProcessingResult(entry.rowNumber, `ERROR: ${error.message}`);
        errors.push({ contentId: entry.contentId, error: error.message });
      }
    }
    return { skipped: false, decisions, errors };
  }

  async prepareClaimedReview({ reviewId, rowNumber }) {
    const review = await this.repository.contentReviewById(reviewId);
    if (review.status === "processed") return { reused: true, requiresGeneration: false, review, result: review.result };
    const content = await this.repository.contentById(review.content_id);
    const currentRevision = Number(content.decision?.review_revision ?? 1);
    if (currentRevision !== review.revision) throw new Error(`Review revision ${review.revision} does not match content revision ${currentRevision}`);

    if (review.decision === "reject") {
      const revised = await this.reviseRejectedContent(content.id, review.instructions);
      return {
        reused: false,
        requiresGeneration: true,
        reviewId: review.id,
        rowNumber,
        contentId: revised.content.id,
        content: revised.content,
      };
    }

    const approval = await this.approveContent(content.id);
    const publication = this.config.AUTO_PUBLISH ? await this.publishContent(content.id) : null;
    const result = {
      action: this.config.AUTO_PUBLISH ? "sent_to_buffer" : "approved_buffer_disabled",
      content_status: publication?.content?.status ?? approval.content.status,
      publications: publication?.publications ?? [],
    };
    const completed = await this.repository.finishContentReview(review.id, "processed", { result });
    await this.approvalSheet.setProcessingResult(
      rowNumber,
      this.config.AUTO_PUBLISH ? "Approved and sent to Buffer" : "Approved; AUTO_PUBLISH is false",
    );
    return { reused: false, requiresGeneration: false, review: completed, result, content: approval.content };
  }

  async completeClaimedReview({ reviewId, rowNumber }) {
    const review = await this.repository.contentReviewById(reviewId);
    if (review.status === "processed") return { reused: true, review, result: review.result };
    const content = await this.repository.contentById(review.content_id);
    if (content.status !== "awaiting_approval") {
      throw new Error(`Revised content must pass final QA before completing the review; current status is ${content.status}`);
    }
    const revision = Number(content.decision?.review_revision ?? review.revision + 1);
    const result = { action: "revision_ready_for_review", revision, content_status: content.status };
    const completed = await this.repository.finishContentReview(review.id, "processed", { result });
    await this.approvalSheet.setProcessingResult(rowNumber, `Rejected version replaced; revision ${revision} passed QA and is ready for review`);
    return { reused: false, review: completed, result, content };
  }

  async applySheetDecision(entry) {
    const content = await this.repository.contentById(entry.contentId);
    const currentRevision = Number(content.decision?.review_revision ?? 1);
    if (currentRevision !== entry.revision) {
      throw new Error(`Stale sheet revision ${entry.revision}; current revision is ${currentRevision}`);
    }
    if (entry.decision === "Reject" && entry.instructions.trim().length < 5) {
      throw new Error("Add revision instructions before selecting Reject");
    }
    const { review, reused } = await this.repository.createContentReview({
      contentId: entry.contentId,
      revision: entry.revision,
      decision: entry.decision.toLowerCase(),
      instructions: entry.instructions,
      sourceRef: `row:${entry.rowNumber}`,
    });
    if (reused) return { reused: true, review, result: review.result };

    try {
      let result;
      if (entry.decision === "Reject") {
        const rejected = await this.rejectContent(entry.contentId, entry.instructions);
        result = {
          action: "regeneration_started",
          revision: Number(rejected.content.decision?.review_revision ?? currentRevision + 1),
          content_status: rejected.content.status,
          generation_error: rejected.generation?.error ?? null,
        };
      } else {
        const approval = await this.approveContent(entry.contentId);
        let publication = null;
        if (this.config.AUTO_PUBLISH) publication = await this.publishContent(entry.contentId);
        result = {
          action: this.config.AUTO_PUBLISH ? "sent_to_buffer" : "approved_buffer_disabled",
          content_status: publication?.content?.status ?? approval.content.status,
          publications: publication?.publications ?? [],
        };
      }
      const completed = await this.repository.finishContentReview(review.id, "processed", { result });
      return { reused: false, review: completed, result };
    } catch (error) {
      await this.repository.finishContentReview(review.id, "failed", { error: error.message });
      throw error;
    }
  }

  async syncApprovalSheet() {
    if (!this.approvalSheet?.configured) {
      return { skipped: true, reason: "Google Sheets approval queue is not configured", actions: [] };
    }
    const before = await this.repository.approvalSheetContent();
    const syncBefore = await this.approvalSheet.syncContent(before);
    const pending = await this.approvalSheet.pendingDecisions();
    const actions = [];
    for (const entry of pending) {
      try {
        const result = await this.applySheetDecision(entry);
        const message = result.result?.action === "sent_to_buffer"
          ? "Approved and sent to Buffer"
          : result.result?.action === "approved_buffer_disabled"
            ? "Approved; AUTO_PUBLISH is false, so Buffer was not called"
            : result.result?.action === "regeneration_started"
              ? `Rejected; revision ${result.result.revision} regeneration started`
              : "Decision already processed";
        await this.approvalSheet.setProcessingResult(entry.rowNumber, message);
        actions.push({ contentId: entry.contentId, decision: entry.decision, ok: true, result });
      } catch (error) {
        await this.approvalSheet.setProcessingResult(entry.rowNumber, `ERROR: ${error.message}`);
        actions.push({ contentId: entry.contentId, decision: entry.decision, ok: false, error: error.message });
      }
    }
    const after = await this.repository.approvalSheetContent();
    const syncAfter = await this.approvalSheet.syncContent(after);
    return { skipped: false, syncBefore, actions, syncAfter };
  }

  platformPlan(content, platform) {
    const plan = content.decision.content;
    const link = trackingUrl(this.config.GYMFEED_LANDING_URL, platform, content.content_key);
    const disclosure = plan.audio_mode === "ai_voiceover" ? "\n\nAI-generated voice." : "";
    if (content.content_type !== "video") {
      return { text: `${withHashtags(plan.caption, plan.hashtags)}\n\n${link}`, title: null };
    }
    if (platform === "instagram") return { text: `${withHashtags(plan.platform_copy.instagram_caption, plan.platform_copy.hashtags)}\n\n${link}${disclosure}`, title: null };
    if (platform === "tiktok") return { text: `${withHashtags(plan.platform_copy.tiktok_caption, plan.platform_copy.hashtags)}\n\n${link}${disclosure}`, title: null };
    return { text: `${plan.platform_copy.youtube_description}\n\nTry GymFeed: ${link}${disclosure}`, title: plan.platform_copy.youtube_title };
  }

  scheduledTime(content, platform) {
    if (content.decision?.campaign?.id) {
      const campaign = content.decision.campaign;
      const minutes = platform === "tiktok" ? 15 : platform === "youtube" ? 30 : 0;
      const scheduled = campaignSchedule(campaign.date, campaign.timezone ?? "America/New_York", content.content_type === "video" ? 18 : 12, minutes);
      if (Date.parse(scheduled) <= Date.now() + 60_000) throw new Error("Campaign slot is in the past or too soon. Change and reapprove the campaign dates; never publish immediately as a fallback.");
      return scheduled;
    }
    if (!this.config.BUFFER_SCHEDULE_AT) return undefined;
    const base = new Date(this.config.BUFFER_SCHEDULE_AT);
    if (Number.isNaN(base.getTime())) throw new Error("BUFFER_SCHEDULE_AT must be an ISO date-time");
    if (content.content_type !== "video") return base.toISOString();
    const offsets = {
      instagram: 8 * 60 * 60 * 1000,
      tiktok: (8 * 60 + 15) * 60 * 1000,
      youtube: (8 * 60 + 30) * 60 * 1000,
    };
    return new Date(base.getTime() + offsets[platform]).toISOString();
  }

  async publishContent(id, { explicitBatchRelease = false } = {}) {
    const content = await this.repository.contentById(id);
    if (!["approved", "scheduled"].includes(content.status)) return { skipped: true, reason: `status is ${content.status}`, content };
    if (this.campaigns) await this.campaigns.assertPublicationAllowed(id);
    if (!this.config.AUTO_PUBLISH && !(explicitBatchRelease && content.decision?.campaign?.id)) return { skipped: true, reason: "automatic publishing disabled", content };
    const brand = await this.repository.brandConfig();
    if (!brand.enabled) return { skipped: true, reason: "marketing disabled", content };

    const accountByPlatform = {
      instagram: this.config.BUFFER_INSTAGRAM_CHANNEL_ID,
      tiktok: this.config.BUFFER_TIKTOK_CHANNEL_ID,
      youtube: this.config.BUFFER_YOUTUBE_CHANNEL_ID,
    };
    const platforms = (content.content_type === "video" ? ["instagram", "tiktok", "youtube"] : ["instagram"])
      .filter((platform) => accountByPlatform[platform]);
    if (!platforms.length) throw new Error("No Buffer channel IDs are configured for this content");

    const mediaUrls = content.asset_urls;
    const publications = [];
    const existing = this.repository.publicationByContent ? await this.repository.publicationByContent(id) : [];
    for (const platform of platforms) {
      const previous = existing.find((row) => row.platform === platform);
      if (previous?.provider_request_id) { publications.push(previous); continue; }
      if (previous?.status === "pending" && previous.error) throw new Error(`Buffer ${platform} submission is unresolved. Reconcile it in Buffer before retrying.`);
      const copy = this.platformPlan(content, platform);
      const scheduledAt = this.scheduledTime(content, platform);
      if (content.decision?.campaign?.id && !scheduledAt) throw new Error("Campaign publishing requires an explicit future schedule");
      await this.repository.upsertPublication({ content_id: content.id, platform, account_ref: accountByPlatform[platform], status: "pending", platform_copy: copy, error: "Submission in progress; reconcile if interrupted" });
      try {
        const response = await this.publisher.publish({
          platform,
          accountId: accountByPlatform[platform],
          mediaUrls,
          text: copy.text,
          title: copy.title,
          isVideo: content.content_type === "video",
          scheduledTime: scheduledAt,
        });
        const requestId = response.id ?? response.post?.id;
        if (!requestId) throw new Error("Buffer returned no post ID");
        publications.push(await this.repository.upsertPublication({
          content_id: content.id,
          platform,
          account_ref: accountByPlatform[platform],
          status: scheduledAt ? "scheduled" : "publishing",
          platform_copy: copy,
          provider_request_id: requestId,
          scheduled_at: scheduledAt ?? null,
          error: null,
        }));
      } catch (error) {
        publications.push(await this.repository.upsertPublication({
          content_id: content.id,
          platform,
          account_ref: accountByPlatform[platform],
          status: "pending",
          platform_copy: copy,
          error: `Submission uncertain; check Buffer before retrying: ${error.message}`,
        }));
      }
    }
    if (publications.length && publications.every((publication) => publication.provider_request_id)) {
      const scheduledAt = publications.map((publication) => publication.scheduled_at).filter(Boolean).sort()[0] ?? null;
      await this.repository.updateContent(content.id, { status: "scheduled", scheduled_at: scheduledAt });
    }
    return { skipped: false, content, publications };
  }

  async refreshPublications() {
    const publications = await this.repository.pendingPublications();
    const updated = [];
    for (const publication of publications) {
      try {
        const remote = await this.publisher.getPost(publication.provider_request_id);
        const remoteStatus = String(remote.status ?? remote.post?.status ?? "sending").toLowerCase();
        const status = ["published", "success", "succeeded", "sent"].includes(remoteStatus)
          ? "published"
          : ["failed", "error"].includes(remoteStatus) ? "failed" : remoteStatus === "scheduled" ? "scheduled" : remoteStatus === "draft" || remoteStatus === "needs_approval" ? "pending" : "publishing";
        const metricDetails = remote.metrics ?? remote.post?.metrics ?? [];
        const metricValues = Object.fromEntries(metricDetails.map((metric) => [metric.type, metric.value]));
        updated.push(await this.repository.updatePublication(publication.id, {
          status,
          external_post_id: remote.id ?? remote.post?.id ?? publication.external_post_id,
          external_url: remote.externalLink ?? remote.post?.externalLink ?? publication.external_url,
          published_at: status === "published" ? (remote.sentAt ?? remote.post?.sentAt ?? new Date().toISOString()) : publication.published_at,
          ...(status === "published" ? {
            metrics: {
              values: metricValues,
              details: metricDetails,
              provider_updated_at: remote.metricsUpdatedAt ?? remote.post?.metricsUpdatedAt ?? null,
            },
            last_metrics_sync_at: new Date().toISOString(),
          } : {}),
          error: status === "failed" ? (remote.error?.message ?? remote.post?.error?.message ?? remote.message ?? "Buffer publish failed") : null,
        }));
      } catch (error) {
        updated.push(await this.repository.updatePublication(publication.id, { error: error.message }));
      }
    }
    const contentIds = [...new Set(updated.map((publication) => publication.content_id))];
    for (const contentId of contentIds) {
      const rows = await this.repository.publicationByContent(contentId);
      if (rows.length && rows.every((row) => row.status === "published")) {
        await this.repository.updateContent(contentId, { status: "published", published_at: new Date().toISOString() });
      }
    }
    return updated;
  }

  async runPipeline() {
    if (!this.config.GENERATE_ASSETS) return { skipped: true, reason: "asset generation disabled", actions: [] };
    if (this.campaigns) return { skipped: true, reason: "Use the main CMO with an explicitly approved seven-day batch", actions: [] };
    const actions = [];
    const planned = await this.repository.nextContent("planned");
    if (planned) actions.push({ stage: "generate", result: await this.generateContent(planned.id) });
    const generating = await this.repository.nextContent("generating");
    if (generating) actions.push({ stage: "refresh", result: await this.refreshContent(generating.id) });
    const generated = await this.repository.nextContent("generated");
    if (generated) actions.push({ stage: "qa", result: await this.reviewContent(generated.id) });
    if (this.config.AUTO_PUBLISH) {
      const approved = await this.repository.nextContent("approved");
      if (approved) actions.push({ stage: "publish", result: await this.publishContent(approved.id) });
    }
    return { skipped: false, actions };
  }
}
