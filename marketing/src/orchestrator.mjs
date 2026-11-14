import { randomUUID } from "node:crypto";
import { allocateSpeechScene, dialogueCut, editorialPlan, verifySpokenTimeline } from "./editorial.mjs";
import { timedSceneCaptions } from "./caption-timing.mjs";
import { photoMusicPlan,photoMusicMessage,bufferDeliveryState } from "./photo-music.mjs";
import { ensureContinuity, prepareLockedSpeech, allocatedScene, needsLipSync, queueLockedLipSync } from "./continuity-production.mjs";
import { locationReferencePrompt, locationFingerprint, productionScene } from "./production-continuity.mjs";
import { narrationFingerprint, sceneMediaFingerprint } from "./video-revisions.mjs";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { overallQaScore } from "./contracts.mjs";
import { renderCarouselSlide } from "./render-carousel.mjs";
import { extractVideoAudio, extractVideoContactSheet, inspectVideo, detectSpeechSilences } from "./extract-video-frame.mjs";
import { renderProductSlide } from "./render-product-slide.mjs";
import { plannedVideoDuration, platformVideoDuration, renderProductVideo, verifiedSceneCaptions } from "./render-product-video.mjs";
import { verifiedScreenshotUrl } from "./product-brief.mjs";
import { appCaptureCatalog, preflightAppCaptures, resolveAppCapture } from "./app-captures.mjs";
import { campaignSchedule } from "./campaign-schedule.mjs";
import { sceneCast, sceneReferenceUrls, storyFingerprint, storyReviewPassed, validateVideoStory } from "./video-story.mjs";

const execFileAsync = promisify(execFile);
const openAiBudgetExceeded = (error) => /openai provider budget exceeded/i.test(error?.message ?? "");

async function silentPreviewAudio(seconds) {
  const duration = Math.max(0.25, Number(seconds) || 1);
  const { stdout } = await execFileAsync(process.env.FFMPEG_PATH || "ffmpeg", ["-hide_banner", "-loglevel", "error", "-f", "lavfi", "-i", "anullsrc=r=44100:cl=mono", "-t", String(duration), "-q:a", "9", "-f", "mp3", "pipe:1"], { encoding: "buffer", maxBuffer: 5_000_000 });
  return stdout;
}

function utcDateKey(now = new Date()) {
  return now.toISOString().slice(0, 10);
}

function wait(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

export async function settleOrReleaseOpenAiReservation(repository, reservationId, error) {
  if (!reservationId) return;
  try {
    if (Number.isFinite(error?.openaiCostUsd) && error.openaiCostUsd > 0) {
      await repository.settleCost(reservationId, error.openaiCostUsd, error.openaiResponseId ?? null);
    } else {
      await repository.releaseCost(reservationId);
    }
  } catch (_) {
    // Preserve the provider or validation error that stopped the workflow.
  }
}

function isoWeekKey(now = new Date()) {
  const date = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  date.setUTCDate(date.getUTCDate() + 4 - (date.getUTCDay() || 7));
  const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
  const week = Math.ceil((((date - yearStart) / 864e5) + 1) / 7);
  return `${date.getUTCFullYear()}-W${String(week).padStart(2, "0")}`;
}

export function referenceImagePrompt(content, actor = null) {
  const plan = content.decision.content;
  const shot = plan.scenes?.find((scene) => scene.asset_type === "generated_video" && (!actor || scene.character_ids?.includes(actor.character_id)));
  const reference = plan.character_reference ?? {};
  return [
    "GYMFEED CAST, SET AND PROP CONTINUITY REFERENCE",
    "Photorealistic vertical 9:16 reference for an acted product story, not a poster. Show the starting state of the approved action.",
    `Fictional adult: ${actor?.appearance ?? reference.description ?? shot?.subject ?? "adult trainee"}`,
    actor && plan.casting_policy === "young_adult_women"
      ? `Owner casting policy: woman, age ${actor.age_range}, high camera presence. She is visually striking, photogenic and polished while remaining believable, naturally expressive and non-sexualized.`
      : null,
    actor ? `This is the individual identity reference for ${actor.character_id} (${actor.role}). Show ONLY this actor, not the other cast members. Chest-up face clearly visible. No reference-sheet grid.` : null,
    `Wardrobe: ${actor?.wardrobe ?? reference.wardrobe ?? "plain unbranded training clothes"}`,
    `Location and background: ${reference.environment_anchor ?? shot?.environment}`,
    `Starting action and physical props: ${actor ? "Relaxed neutral pose in the shared set; no other people or handled props" : shot?.action}`,
    `Camera: ${shot?.camera}`,
    `Lighting: ${shot?.lighting}`,
    `Continuity: ${(reference.continuity_rules ?? []).join("; ")}`,
    "Props required by the action must exist from the start. A phone may show its unbranded back/edge only; the screen faces the actor.",
    "Natural adult anatomy, skin texture and safe physical action. No celebrity likeness or invented customer testimonial.",
    "No readable text, logos, watermark or fabricated GymFeed interface. Exact product footage and branding are composited later.",
  ].filter(Boolean).join("\n");
}

export function videoScenePrompt(content, scene, retryInstructions = null) {
  const plan = content.decision.content;
  const reference = plan.character_reference ?? {};
  const cast = sceneCast(plan, scene);
  const speaker = cast.find((actor) => actor.character_id === scene.speaker_id);
  const start = Number(scene.source_start_seconds ?? 0);
  const end = start + scene.duration_seconds;
  return [
    `GYMFEED DIRECTOR SHOT ${scene.scene_id} — ${scene.purpose}`,
    `One continuous ${scene.source_duration_seconds ?? scene.duration_seconds}s vertical 9:16 take at 24 fps. Final edit retains ${start.toFixed(1)}–${end.toFixed(1)}s; complete the intended action and any dialogue inside that interval with a clean ending.`,
    `Treatment: ${plan.creative_treatment?.visual_mode ?? "hybrid"}. Render ONLY the single shot below, never a montage or the whole story.`,
    `Subject: ${scene.subject}`,
    `VISIBLE ACTION (execute, do not replace with posing): ${scene.action}`,
    `Environment: ${scene.environment}`,
    `Camera and movement: ${scene.camera}`,
    `Lighting: ${scene.lighting}`,
    `Look: ${scene.visual_style}`,
    plan.casting_policy === "young_adult_women"
      ? "CASTING LOCK: every visible person is an approved young adult woman. Preserve her photogenic, camera-ready identity and natural expressiveness; no male or unnamed background cast."
      : null,
    cast.length ? cast.map((actor, index) => `<IMAGE_REF_${index}> = ${actor.character_id}: ${actor.appearance}; wardrobe ${actor.wardrobe}. Preserve this specific identity, never merge or exchange actors.`).join("\n")
      : "<IMAGE_REF_0>, when supplied, is the cast/set/prop reference; preserve identity, clothes, room geometry and lighting. It is not a guaranteed first frame for reference-to-video.",
    cast.length ? `Visible cast ONLY: ${cast.map((actor) => actor.character_id).join(", ")}. Other actors remain off-camera. Reference images establish identity, not a mandatory pose; perform this shot's action.`
      : `Cast: ${reference.description ?? scene.subject}. Wardrobe: ${reference.wardrobe ?? "unbranded"}.`,
    speaker ? plan.narrative?.format === "dialogue_story"
      ? `ONLY SPEAKER: ${speaker.character_id}. Voice continuity: ${speaker.voice_direction}. Address the scene partner naturally, not the viewer. Others listen silently; no overlapping speech or voice swapping.`
      : `ONLY SPEAKER: ${speaker.character_id}. Voice continuity: ${speaker.voice_direction}. Speak directly to the viewer with natural creator energy, not a polished commercial read. No extra voices or overlapping speech.`
      : null,
    `Continuity: ${scene.continuity_notes}; ${(reference.continuity_rules ?? []).join("; ")}`,
    "Establish every handled prop before contact; preserve its shape, position and grip through the action. No appearing weights, teleporting objects, impossible joints or duplicated limbs. Phone screen faces actor unless a separately planned tracked composite exists.",
    scene.spoken_dialogue ? `EXACT dialogue, spoken once with natural lip sync: "${scene.spoken_dialogue}". This is the ONLY permitted speech. Do not repeat any campaign hook, recap or other scene's dialogue. Conversational 130–170 words per minute, with a short breath before and after. Never rush or compress the delivery to fit; leave natural edit handles. Finish before the retained cut ends.` : "No spoken dialogue, voiceover, campaign hook or background conversation. Tell the beat through the specified physical action and expression.",
    scene.location_id ? `<IMAGE_REF_${cast.length}> is the EMPTY SET for location ${scene.location_id}. Reconstruct its exact equipment, furniture, colours and layout. Actor images establish identity only; never copy their background into this location.` : null,
    scene.canonical_audio ? "LOCKED AUDIO: this is silent picture generation for a separately recorded performance. Mouth the exact line naturally; do not generate sound, music, extra words or captions. Final mouth synchronization and speech are applied from the canonical recording." : null,
    `Sound: ${scene.ambient_audio || "subtle natural room tone"}. Clean speech when specified; no music or captions baked into the source.`,
    "Do not generate GymFeed UI or branding. The editor inserts real app captures, exact logo, Poppins captions and CTA. Do not invent the app's functionality.",
    "Continuity errors, a missing story action or an unrelated static talking head are blocking defects; a beautiful frame is not a substitute.",
    // The planner already applied the complete revision brief to this shot.
    // Repeating the full screenplay here makes the model render other scenes.
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


export function safeBackgroundPrompt(slide, reviewerInstructions = null) {
  const constraint = "Background imagery only. Do not render text, pseudo-text, logos, icons, labels, cards, panels, buttons, controls, device frames, screens, or anything resembling an app interface. Leave clean copy-safe space for the compositor.";
  return `${slide.visual_prompt}\nVisual role: ${slide.visual_type ?? "branded_graphic"}.\n${reviewerInstructions ? `Mandatory reviewer correction: ${reviewerInstructions}\n` : ""}${constraint}`;
}

export function generationPromptForContent(content) {
  const plan = content.decision?.content ?? {};
  if (content.content_type === "video") {
    const generatedScenes = (plan.scenes ?? []).filter((scene) => scene.asset_type === "generated_video");
    const captureScenes = (plan.scenes ?? []).filter((scene) => scene.asset_type === "app_capture");
    const sections = [];
    if (generatedScenes.length) {
      if (plan.cast?.length) for (const actor of plan.cast) sections.push(`CAST REFERENCE ${actor.character_id}\n${referenceImagePrompt(content, actor)}`);
      else sections.push(`REFERENCE IMAGE PROMPT\n${referenceImagePrompt(content)}`);
    }
    for (const scene of generatedScenes) {
      sections.push(`VIDEO SCENE ${scene.scene_id}\n${videoScenePrompt(content, scene)}`);
    }
    for (const scene of captureScenes) {
      const start = Number(scene.source_start_seconds ?? 0);
      const end = start + Number(scene.duration_seconds ?? 0);
      sections.push([
        `NATIVE APP CAPTURE ${scene.scene_id}`,
        `Use verified recording ${scene.capture_ref}.`,
        `Retain ${start.toFixed(1)}-${end.toFixed(1)} seconds.`,
        `Compositor overlay: ${scene.overlay_text ?? ""}`,
        "Do not generate or simulate this app interaction.",
      ].join("\n"));
    }
    return sections.join("\n\n---\n\n");
  }

  return (plan.slides ?? []).map((slide, index) => {
    if (slide.screenshot_ref) {
      return `SLIDE ${index + 1}\nUse verified GymFeed screenshot ${slide.screenshot_ref}; no image-model prompt is used.\nHeadline: ${slide.headline}\nBody: ${slide.body}`;
    }
    return `SLIDE ${index + 1}\n${safeBackgroundPrompt(slide, content.decision?.review_instructions)}\nCompositor headline: ${slide.headline}\nCompositor body: ${slide.body}`;
  }).join("\n\n---\n\n");
}

function trackingUrl(base, platform, contentKey) {
  const url = new URL(base);
  url.searchParams.set("utm_source", platform);
  url.searchParams.set("utm_medium", "organic_social");
  url.searchParams.set("utm_campaign", "always_on_content");
  url.searchParams.set("utm_content", contentKey);
  return url.toString();
}

async function fetchAsset(url, fetchFn = fetch, { attempts = 3, retryDelayMs = 400 } = {}) {
  let lastError;
  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    try {
      const response = await fetchFn(url, { signal: AbortSignal.timeout(60_000) });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      return {
        buffer: Buffer.from(await response.arrayBuffer()),
        contentType: response.headers.get("content-type")?.split(";")[0] ?? "application/octet-stream",
      };
    } catch (error) {
      lastError = error;
      if (attempt < attempts) await wait(retryDelayMs * attempt);
    }
  }
  const error = new Error(`download generated asset failed after ${attempts} attempts: ${lastError?.message ?? "unknown network error"}`);
  error.safeToRetry = true;
  throw error;
}

export class MarketingOrchestrator {
  constructor({ config, repository, brain, mediaProvider, publisher, analyticsReporter, voiceProvider, approvalSheet, campaigns, appCaptureResolver = resolveAppCapture, fetchFn = fetch }) {
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
    this.fetchFn = fetchFn;
  }

  get humanReviewOnly() { return this.config.MARKETING_REVIEW_MODE === "human"; }
  get lockNewProductions() { return this.humanReviewOnly && this.config.MARKETING_CONTINUITY_MODE === "locked"; }

  async sceneAudio(content) {
    const buffers = [];
    const generation = content.decision.generation ?? {};
    const narration = { ...generation.narration };
    const downloadedMasters = new Map();
    for (const scene of content.decision.content.scenes ?? []) {
      if (scene.audio_strategy !== "voiceover" || !scene.voiceover_text?.trim()) continue;
      if(generation.continuity){
        const speech=generation.speech?.[scene.scene_id];
        if(!speech)throw Error(`Missing locked narrator audio for ${scene.scene_id}`);
        const audio=await fetchAsset(speech.url,this.fetchFn);
        buffers.push({sceneId:scene.scene_id,buffer:audio.buffer,words:speech.technical.words??[],technical:speech.technical});
        continue;
      }
      try {
        const fingerprint = narrationFingerprint(scene);
        const cached = narration[scene.scene_id];
        if (this.humanReviewOnly && cached?.fingerprint === fingerprint && cached.url) {
          const audio = await fetchAsset(cached.url, this.fetchFn);
          buffers.push({ sceneId: scene.scene_id, buffer: audio.buffer, words: cached.words ?? [], technical: cached.technical });
          continue;
        }
        const previous = generation.narration_sources?.[scene.scene_id];
        let buffer;
        if (this.humanReviewOnly && previous?.fingerprint === fingerprint) {
          if (!downloadedMasters.has(previous.url)) downloadedMasters.set(previous.url, (await fetchAsset(previous.url, this.fetchFn)).buffer);
          buffer = await extractVideoAudio(downloadedMasters.get(previous.url), { startSeconds: previous.start, durationSeconds: previous.duration });
        } else buffer = await this.createVoiceover({ ...content, decision: { ...content.decision, content: {
          ...content.decision.content, audio_mode: "ai_voiceover", voiceover_script: scene.voiceover_text,
        } } });
        if (this.humanReviewOnly) {
          const technical = await this.timedSpeech(content, { ...scene, spoken_dialogue: scene.voiceover_text }, buffer, await inspectVideo(buffer));
          const url = await this.repository.uploadAsset(`${content.content_key}/${generation.generation_id}/audio/${scene.scene_id}-${fingerprint.slice(0, 16)}.mp3`, buffer, "audio/mpeg");
          narration[scene.scene_id] = { fingerprint, url, words: technical.words ?? [], technical };
          content.decision.generation = { ...content.decision.generation, narration };
          await this.repository.updateContent(content.id, { decision: content.decision });
          buffers.push({ sceneId: scene.scene_id, buffer, words: technical.words ?? [], technical });
        } else buffers.push({ sceneId: scene.scene_id, buffer });
      } catch (error) {
        if (!openAiBudgetExceeded(error)) throw error;
        buffers.push({ sceneId: scene.scene_id, buffer: await silentPreviewAudio(scene.duration_seconds), missingNarration: true });
      }
    }
    return buffers;
  }

  async timedSpeech(content, scene, buffer, technical) {
    if (!technical.has_audio) return { ...technical, words: [], speech_timing_source: "missing_audio" };
    if (!this.voiceProvider?.transcribe) return { ...technical, words: [], speech_timing_source: "unavailable" };
    let reservation;
    try {
      reservation = await this.repository.reserveCost("openai", this.config.OPENAI_ESTIMATED_TRANSCRIPTION_COST_USD ?? .01,
        { contentId: content.id, runId: content.run_id, metadata: { operation: "editorial-speech-timing", scene_id: scene.scene_id } });
      const audio = await extractVideoAudio(buffer);
      const transcript = await this.voiceProvider.transcribe({ buffer: audio, timestamps: true });
      await this.repository.settleCost(reservation, this.config.OPENAI_ESTIMATED_TRANSCRIPTION_COST_USD ?? .01, transcript.requestId);
      reservation = null;
      return { ...technical, expected_dialogue: scene.spoken_dialogue, transcript: transcript.text, source_transcript: transcript.text,
        words: transcript.words ?? [], segments: transcript.segments ?? [], speech_timing_source: "full_source",
        silences: await detectSpeechSilences(buffer).catch(() => []) };
    } catch (error) {
      if (reservation) await this.repository.releaseCost(reservation).catch(() => {});
      return { ...technical, words: [], speech_timing_source: "unavailable", speech_timing_error: error.message };
    }
  }

  async finalTechnical(content, buffer, { expectedDuration = plannedVideoDuration(content.decision.content), sceneIds = null } = {}) {
    const technical = await inspectVideo(buffer);
    if (this.humanReviewOnly) {
      let reservation;
      try {
        if (!technical.has_audio || !this.voiceProvider?.transcribe) throw new Error("Final speech could not be checked");
        reservation = await this.repository.reserveCost("openai", this.config.OPENAI_ESTIMATED_TRANSCRIPTION_COST_USD ?? .01,
          { contentId: content.id, runId: content.run_id, metadata: { operation: "final-sentence-integrity" } });
        const transcript = await this.voiceProvider.transcribe({ buffer: await extractVideoAudio(buffer), timestamps: true });
        await this.repository.settleCost(reservation, this.config.OPENAI_ESTIMATED_TRANSCRIPTION_COST_USD ?? .01, transcript.requestId);
        reservation = null;
        const integrity = verifySpokenTimeline(content.decision.content, transcript.text);
        return { ...technical, duration_matches_plan: Math.abs(technical.duration_seconds - expectedDuration) <= .3,
          final_transcript: transcript.text, sentence_integrity: integrity, review_status: "human_review_required" };
      } catch (error) {
        if (reservation) await this.repository.releaseCost(reservation).catch(() => {});
        return { ...technical, sentence_integrity: { checked: false, passed: false, issues: [error.message] }, review_status: "human_review_required" };
      }
    }
    const plan = content.decision.content;
    if (!(Number(plan.production_version) >= 2)) return technical;
    const included = sceneIds ? new Set(sceneIds) : null;
    const expected = (plan.scenes ?? []).filter((scene) => !included || included.has(scene.scene_id))
      .map((scene) => scene.audio_strategy === "voiceover" ? scene.voiceover_text : scene.audio_strategy === "native" ? scene.spoken_dialogue : "")
      .filter(Boolean).join(" ");
    const durationOk = Math.abs(technical.duration_seconds - expectedDuration) <= 0.3;
    if (!expected) return { ...technical, retained_audio_checked: true, final_dialogue_match: true, duration_matches_plan: durationOk };
    if (!technical.has_audio || !this.voiceProvider?.transcribe) return { ...technical, retained_audio_checked: false, final_dialogue_match: false, duration_matches_plan: durationOk };
    let reservation;
    try {
      reservation = await this.repository.reserveCost("openai", this.config.OPENAI_ESTIMATED_TRANSCRIPTION_COST_USD ?? 0.01, { contentId: content.id, runId: content.run_id, metadata: { operation: "final-edit-audio-verification" } });
    } catch (error) {
      if (!openAiBudgetExceeded(error)) throw error;
      return { ...technical, retained_audio_checked: false, final_dialogue_match: false, duration_matches_plan: durationOk, verification_note: "Final audio verification unavailable: monthly OpenAI budget reached" };
    }
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

  performanceContextAudit(context) {
    const buffer = context?.buffer ?? { status: "not_configured" };
    return {
      ga4: {
        status: context?.ga4?.status ?? "unknown",
      },
      buffer: {
        status: buffer.status ?? "unknown",
        source: buffer.source ?? null,
        collected_at: buffer.collected_at ?? null,
        posts_analyzed: Number(buffer.posts_analyzed ?? 0),
        truncated: Boolean(buffer.truncated),
        benchmark_posts: (buffer.benchmark_posts ?? []).map((post) => ({
          id: post.id,
          platform: post.platform,
          sent_at: post.sent_at,
          metrics: post.metrics,
          metrics_updated_at: post.metrics_updated_at,
          duration_seconds: post.duration_seconds,
          watch_ratio: post.watch_ratio,
        })),
        benchmark_errors: buffer.benchmark_errors ?? [],
        error: buffer.message ?? null,
      },
    };
  }

  assertPerformanceContext(context) {
    if (!this.publisher?.performanceSummary) return;
    if (context.buffer?.status !== "ok") {
      throw new Error(`Buffer performance context unavailable: ${context.buffer?.message ?? "unknown error"}`);
    }
    const expected = this.publisher.benchmarkPostIds?.length ?? 0;
    const received = context.buffer?.benchmark_posts?.length ?? 0;
    if (expected > 0 && received !== expected) {
      const errors = (context.buffer?.benchmark_errors ?? []).map((item) => `${item.id}: ${item.error}`).join("; ");
      throw new Error(`Buffer benchmark context incomplete (${received}/${expected})${errors ? `: ${errors}` : ""}`);
    }
  }

  async runDaily(now = new Date(), { revision = 1, campaignId = null, retryFailed = false, resumeBefore } = {}) {
    if (!Number.isInteger(revision) || revision < 1 || revision > 999) throw new Error("Daily revision must be an integer from 1 to 999");
    const dailyKey = revision === 1
      ? `daily:${utcDateKey(now)}`
      : `daily:${utcDateKey(now)}:r${String(revision).padStart(3, "0")}`;
    const idempotencyKey = campaignId ? `campaign:${campaignId}:${dailyKey}` : dailyKey;
    const { run, reused } = await this.repository.startRun(
      "daily-cmo",
      idempotencyKey,
      { now: now.toISOString(), revision },
      { restartFailed: retryFailed, ...(campaignId && resumeBefore ? { resumeBefore } : {}) },
    );
    if (reused) return { reused: true, run };

    let reservationId;
    let context;
    try {
      const brand = await this.repository.brandConfig();
      if (!brand.enabled) {
        return { reused: false, run: await this.repository.finishRun(run.id, "skipped", { reason: "marketing disabled" }) };
      }
      reservationId = await this.repository.reserveCost("openai", this.config.OPENAI_ESTIMATED_DAILY_COST_USD, { runId: run.id, metadata: { operation: "daily-cmo" } });
      context = await this.decisionContext();
      this.assertPerformanceContext(context);
      if (campaignId) context.campaign = await this.campaigns.status(campaignId);
      const result = await this.brain.daily(context, now);
      const content = await this.repository.saveDailyDecision(run.id, result.data, now, revision, campaignId);
      await this.repository.settleCost(reservationId, result.costUsd, result.responseId);
      const completed = await this.repository.finishRun(run.id, "succeeded", {
        decision: result.data,
        content_ids: content.map((item) => item.id),
        measurement_context: this.performanceContextAudit(context),
      }, result.costUsd);
      return { reused: false, run: completed, content };
    } catch (error) {
      await settleOrReleaseOpenAiReservation(this.repository, reservationId, error);
      await this.repository.finishRun(run.id, "failed", {
        measurement_context: this.performanceContextAudit(context),
      }, error.openaiCostUsd ?? null, error.message);
      throw error;
    }
  }

  async runWeekly(now = new Date(), { retryFailed = false } = {}) {
    const { run, reused } = await this.repository.startRun(
      "weekly-cmo",
      `weekly:${isoWeekKey(now)}`,
      { now: now.toISOString() },
      { restartFailed: retryFailed },
    );
    if (reused) return { reused: true, run };
    let reservationId;
    let context;
    try {
      const brand = await this.repository.brandConfig();
      if (!brand.enabled) {
        return { reused: false, run: await this.repository.finishRun(run.id, "skipped", { reason: "marketing disabled" }) };
      }
      reservationId = await this.repository.reserveCost("openai", this.config.OPENAI_ESTIMATED_WEEKLY_COST_USD, { runId: run.id, metadata: { operation: "weekly-cmo" } });
      context = await this.decisionContext();
      this.assertPerformanceContext(context);
      const result = await this.brain.weekly(context);
      const learnings = await this.repository.saveWeeklyReview(run.id, result.data);
      await this.repository.settleCost(reservationId, result.costUsd, result.responseId);
      const completed = await this.repository.finishRun(run.id, "succeeded", {
        review: result.data,
        learning_ids: learnings.map((item) => item.id),
        measurement_context: this.performanceContextAudit(context),
      }, result.costUsd);
      return { reused: false, run: completed, learnings };
    } catch (error) {
      await settleOrReleaseOpenAiReservation(this.repository, reservationId, error);
      await this.repository.finishRun(run.id, "failed", {
        measurement_context: this.performanceContextAudit(context),
      }, error.openaiCostUsd ?? null, error.message);
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
      const scenes = content.decision?.generation?.scenes ?? [];
      const generated = scenes.filter((scene) => scene.asset_type === "generated_video");
      if (this.humanReviewOnly && generated.length) {
        if (generated.every((scene) => scene.asset_url)) return this.finishVideoGeneration(content, scenes, content.decision.generation);
        if (generated.some((scene) => ["queued", "running"].includes(scene.status))) {
          const pending = generated.find((scene) => ["queued", "running"].includes(scene.status));
          await this.repository.updateContent(id, { status: "generating", provider_task_id: pending.task_id, failure_reason: null });
          return this.refreshContent(id);
        }
        throw new Error("Generation failed. Existing scene work is preserved; a new paid attempt requires an explicit revision approval.");
      }
      if (generated.length && generated.every((scene) => ["qa_passed", "qa_failed"].includes(scene.status) && scene.asset_url)
        && generated.filter((scene) => scene.status === "qa_failed")
          .every((scene) => Number(scene.attempt ?? 0) >= (this.config.FAL_SCENE_MAX_ATTEMPTS ?? 2))) {
        return this.finishVideoGeneration(content, scenes, content.decision.generation);
      }
      const resumed = await this.resumeFailedVideoScene(content);
      if (resumed) return resumed;
    }
    return content.content_type === "video" ? this.generateVideo(content) : this.generateInstagramAsset(content);
  }

  async resumeFailedVideoScene(content) {
    if (this.humanReviewOnly) return null;
    const generation = { ...(content.decision?.generation ?? {}) };
    const sceneRecords = [...(generation.scenes ?? [])];
    const maximumAttempts = this.config.FAL_SCENE_MAX_ATTEMPTS ?? 2;
    const retryableIndexes = sceneRecords
      .map((scene, index) => ({ scene, index }))
      .filter(({ scene }) => scene.asset_type === "generated_video"
        && (scene.status === "qa_failed" && Number(scene.attempt ?? 0) < maximumAttempts
          || scene.status === "failed" && (scene.provider_error?.infrastructureFailure === true
            || /downstream_service_unavailable|\b504\b/i.test(scene.failure_reason ?? ""))));
    if (!retryableIndexes.length) return null;

    const sceneSpecs = new Map((content.decision.content.scenes ?? []).map((scene) => [scene.scene_id, scene]));
    for (const { scene: record, index } of retryableIndexes) {
      const sceneSpec = sceneSpecs.get(record.scene_id);
      if (!sceneSpec) throw new Error(`Cannot resume missing scene specification: ${record.scene_id}`);
      const retry = await this.queueVideoScene(
        content,
        sceneSpec,
        content.decision.content.cast?.length ? generation.character_reference_urls : generation.reference_image_url,
        Number(record.attempt ?? 0) + 1,
        record.qa?.retry_prompt || record.qa?.required_fixes?.join("; ")
          || `The previous provider attempt failed before producing media: ${record.failure_reason}. Preserve the approved shot and try it again.`,
      );
      sceneRecords[index] = {
        ...retry,
        edit_attempts: record.edit_attempts ?? 0,
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
      provider: "fal-reference+gymfeed-edit",
      provider_task_id: pendingTask?.task_id ?? null,
      failure_reason: null,
      decision: { ...content.decision, generation },
    });
    return { skipped: false, pending: true, resumed: true, retrying: true, content: updated, tasks: retryableIndexes.length };
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
    if (content.decision.generation?.continuity) scene = allocatedScene(content,scene);
    else if (this.humanReviewOnly) scene = allocateSpeechScene(scene);
    const sourceDuration = scene.source_duration_seconds ?? scene.duration_seconds;
    const taskOptions = {
      prompt: videoScenePrompt(content, scene, retryInstructions),
      durationSeconds: sourceDuration,
      generateAudio: scene.canonical_audio ? false : scene.audio_strategy ? scene.audio_strategy === "native"
        : ["native_audio", "ambient_plus_captions", "mixed"].includes(content.decision.content.audio_mode),
      referenceImageUrls: sceneReferenceUrls(content.decision.content, scene, referenceImageUrl),
    };
    const prepared = this.mediaProvider.prepareTask?.(taskOptions);
    const billedDuration = prepared?.durationSeconds ?? sourceDuration;
    const estimatedCost = Number((billedDuration * this.config.FAL_VIDEO_USD_PER_SECOND).toFixed(6));
    const reservationId = await this.repository.reserveCost("fal", estimatedCost, {
      contentId: content.id,
      runId: content.run_id,
      metadata: {
        operation: "campaign-video-scene",
        scene_id: scene.scene_id,
        attempt,
        duration_seconds: billedDuration,
        model: prepared?.model,
        cost_basis: "configured_estimate_not_provider_invoice",
        edit_duration_seconds: scene.duration_seconds,
      },
    });
    try {
      const task = await this.mediaProvider.createTask(taskOptions);
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
        production_spec: scene,
        media_fingerprint: sceneMediaFingerprint(content.decision.content, scene),
        qa: null,
        history: [],
      };
    } catch (error) {
      try { await this.repository.releaseCost(reservationId); } catch (_) { /* preserve provider error */ }
      throw error;
    }
  }

  async queueSceneEdit(content, scene, record, qa, score) {
    const duration = Number(record.technical?.duration_seconds);
    if (!this.config.FAL_SCENE_EDIT_ENABLED || !this.mediaProvider.editTask
      || record.asset_type !== "generated_video" || !record.asset_url
      || Number(record.edit_attempts ?? 0) >= 1 || score < 70
      || Number(qa.scores?.scene_match ?? 0) < 85
      || !qa.required_fixes?.length || !Number.isFinite(duration) || duration < 2 || duration > 10
      || scene.spoken_dialogue?.trim() && record.technical?.dialogue_match !== true) return null;
    const model = this.config.FAL_EDIT_MODEL;
    const estimatedCost = Number((Math.ceil(duration) * this.config.FAL_EDIT_USD_PER_SECOND).toFixed(6));
    const reservation = await this.repository.reserveCost("fal", estimatedCost, {
      contentId: content.id, runId: content.run_id,
      metadata: { operation: "scene-edit", scene_id: scene.scene_id, source_asset_url: record.asset_url, model },
    });
    try {
      const task = await this.mediaProvider.editTask({ model, videoUrl: record.asset_url,
        prompt: [
          "Edit this existing fictional human scene. Apply only these visual corrections:",
          ...qa.required_fixes,
          `Approved action: ${scene.action}. Preserve the existing actors, their identities, camera composition, action order, duration and original audio exactly.`,
          "Do not add speech, captions, logos, UI, product screens or additional people. Preserve everything unaffected by the requested correction.",
        ].join("\n"),
      });
      return { ...record, status: "queued", attempt: Number(record.attempt) + 1,
        edit_attempts: Number(record.edit_attempts ?? 0) + 1, operation: "edit",
        source_asset_url: record.asset_url, task_id: task.id, model: task.model,
        reservation_id: reservation, estimated_cost_usd: estimatedCost,
        asset_url: null, contact_sheet_url: null, technical: null, qa: null,
      };
    } catch (error) {
      await this.repository.releaseCost(reservation);
      if (error.safeToRetry) return null;
      throw error;
    }
  }

  async generateVideo(content) {
    if (this.campaigns) await this.campaigns.assertGenerationAllowed(content.id);
    const plan = content.decision.content;
    await preflightAppCaptures(plan, this.appCaptureResolver);
    const plannedScenes = plan.scenes ?? [];
    const generatedSceneSpecs = plannedScenes.filter((scene) => (scene.asset_type ?? "generated_video") === "generated_video");
    if(this.lockNewProductions&&generatedSceneSpecs.length)content=await ensureContinuity(this,content);
    let carried = this.humanReviewOnly ? content.decision.generation ?? {} : {};
    const existing = new Map((carried.scenes ?? []).map((scene) => [scene.scene_id, scene]));
    const missing = generatedSceneSpecs.filter((scene) => !existing.get(scene.scene_id)?.asset_url && !existing.get(scene.scene_id)?.task_id);
    if (carried.revision_scope && missing.some((scene) => !carried.revision_scope.replace_scene_ids.includes(scene.scene_id))) {
      throw new Error("Revision cannot generate an unaffected shot whose existing footage is missing. Restore that source first.");
    }
    const costPreflight = () => {
      if(!this.humanReviewOnly)return;
      const sceneCost = missing.reduce((sum, original) => {
        const scene = carried.continuity?allocatedScene(content,original):allocateSpeechScene(original);
        const referenceCount=carried.continuity?(scene.character_ids?.length??0)+1:plan.character_reference?.required?1:0;
        const prepared = this.mediaProvider.prepareTask?.({ prompt: "Cost preflight", durationSeconds: scene.source_duration_seconds ?? scene.duration_seconds, generateAudio: !carried.continuity&&scene.audio_strategy === "native", referenceImageUrls: Array.from({length:referenceCount},(_,i)=>`cost-preflight-${i}`) });
        return sum + Number(prepared?.durationSeconds ?? scene.source_duration_seconds ?? scene.duration_seconds) * this.config.FAL_VIDEO_USD_PER_SECOND;
      }, 0);
      const requiredActors = new Set(missing.flatMap((scene) => scene.character_ids ?? []));
      const referenceCount = (!plan.character_reference?.required&&!carried.continuity) || !missing.length ? 0 : plan.cast?.length
        ? plan.cast.filter((actor) => requiredActors.has(actor.character_id) && !carried.character_reference_urls?.[actor.character_id]).length
        : carried.reference_image_url ? 0 : 1;
      const sets=carried.continuity?.locations.filter(place=>!carried.location_reference_urls?.[place.location_id]||carried.location_reference_hashes?.[place.location_id]!==locationFingerprint(place)).length??0;
      const lipSync=carried.continuity?generatedSceneSpecs.filter(scene=>scene.audio_strategy==="native"&&(!existing.get(scene.scene_id)?.lip_sync||needsLipSync(content,scene,existing.get(scene.scene_id)))).reduce((sum,scene)=>sum+(allocatedScene(content,scene).source_duration_seconds*(this.config.FAL_LIPSYNC_USD_PER_SECOND??.05)),0):0;
      const estimated = sceneCost + (referenceCount+sets) * this.config.FAL_ESTIMATED_IMAGE_COST_USD+lipSync;
      if (estimated > (this.config.FAL_MAX_VIDEO_ATTEMPT_USD ?? 25)) {
        const error = new Error(`Generation not started: estimated attempt cost $${estimated.toFixed(2)} exceeds the $${(this.config.FAL_MAX_VIDEO_ATTEMPT_USD ?? 25).toFixed(2)} per-video limit. Review the plan before approving a new attempt.`);
        error.safeToRetry = true;
        throw error;
      }
    };
    costPreflight();
    if(carried.continuity){content=await prepareLockedSpeech(this,content);carried=content.decision.generation;costPreflight();}
    try {
      if (!this.humanReviewOnly && Number(plan.production_version) >= 3) {
        validateVideoStory(plan);
        const fingerprint = storyFingerprint(plan);
        let review = content.decision.story_review;
        if (review?.fingerprint !== fingerprint) {
          let reservation;
          try {
            reservation = await this.repository.reserveCost("openai", this.config.OPENAI_ESTIMATED_QA_COST_USD ?? 0.05, {
              contentId: content.id, runId: content.run_id, metadata: { operation: "preproduction-story-review" },
            });
          } catch (error) {
            if (!openAiBudgetExceeded(error)) throw error;
            review = { accept: false, fingerprint, review_status: "budget_blocked", summary: "Creative story QA unavailable: monthly OpenAI budget reached", required_fixes: [], scores: {} };
          }
          if (reservation) {
            let result;
            try {
              result = await this.brain.storyQualityReview(plan);
              await this.repository.settleCost(reservation, result.costUsd, result.responseId);
            } catch (error) {
              await settleOrReleaseOpenAiReservation(this.repository, reservation, error);
              throw error;
            }
            review = { ...result.data, fingerprint, response_id: result.responseId };
          }
          content = await this.repository.updateContent(content.id, { decision: { ...content.decision, story_review: review } });
        }
        if (!storyReviewPassed(review) && content.decision?.workflow?.story_preview_authorized_fingerprint !== fingerprint) {
          const humanApproved = content.decision?.campaign?.generation_authorized === true;
          if (!humanApproved) {
            const error = new Error(`Creative story QA failed before media generation: ${review.required_fixes?.join("; ") || review.summary || "one or more story scores below 85"}`);
            error.safeToRetry = true;
            error.storyQaFailed = true;
            throw error;
          }
          content = await this.repository.updateContent(content.id, {
            decision: {
              ...content.decision,
              workflow: {
                ...content.decision?.workflow,
                story_qa_advisory_override_fingerprint: fingerprint,
                story_qa_advisory_override_at: new Date().toISOString(),
              },
            },
          });
        }
      }
      if (!generatedSceneSpecs.length) {
        await this.repository.updateContent(content.id, {
          status: "generating",
          provider: "gymfeed-product-motion",
          provider_task_id: null,
          failure_reason: null,
        });
        let voiceoverBuffer = null;
        let fullNarrationMissing = false;
        if (Number(plan.production_version) < 2) {
          try { voiceoverBuffer = await this.createVoiceover(content); }
          catch (error) {
            if (!openAiBudgetExceeded(error)) throw error;
            voiceoverBuffer = await silentPreviewAudio(plannedVideoDuration(plan));
            fullNarrationMissing = true;
          }
        }
        const sceneVoiceoverBuffers = await this.sceneAudio(content);
        const previewAudioGaps = sceneVoiceoverBuffers.filter((scene) => scene.missingNarration).map((scene) => scene.sceneId);
        const sceneCaptions = Number(plan.production_version) >= 3
          ? verifiedSceneCaptions(plan, [], previewAudioGaps)
          : {};
        const renderedVideo = await renderProductVideo(plan, { voiceoverBuffer, sceneVoiceoverBuffers, sceneCaptions, appCaptureResolver: this.appCaptureResolver });
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
            generation: { mode: "product_led", scenes: [], final_technical: technical, preview_caption_gaps: Number(plan.production_version) >= 3 ? previewAudioGaps : [], preview_audio_gaps: [
              ...(fullNarrationMissing ? ["full_narration"] : []),
              ...previewAudioGaps,
            ] },
          },
        });
        return { skipped: false, pending: false, content: updated };
      }

      const generationId = carried.generation_id ?? randomUUID();
      let referenceImageUrl = carried.reference_image_url ?? null;
      const characterReferenceUrls = { ...carried.character_reference_urls };
      const locationReferenceUrls={...carried.location_reference_urls}, locationReferenceHashes={...carried.location_reference_hashes};
      const sceneRecords = [...existing.values()].filter((record) => plannedScenes.some((scene) => scene.scene_id === record.scene_id));
      const checkpoint = () => this.repository.updateContent(content.id, {
        status: "generating", provider: "fal-reference+gymfeed-edit",
        provider_task_id: sceneRecords.find((record) => ["queued", "running"].includes(record.status))?.task_id ?? null,
        decision: { ...content.decision, generation: {
          ...carried, mode: carried.revision_scope ? "selective_revision" : "multi_scene_reference", generation_id: generationId,
          reference_image_url: referenceImageUrl, character_reference_urls: { ...characterReferenceUrls },
          location_reference_urls:{...locationReferenceUrls},location_reference_hashes:{...locationReferenceHashes},
          scenes: [...sceneRecords],
        } },
      });
      if ((plan.character_reference?.required||carried.continuity) && missing.length) {
        for (const actor of plan.cast?.length ? plan.cast : [null]) {
          if (actor && (characterReferenceUrls[actor.character_id] || !missing.some((scene) => (scene.character_ids ?? []).includes(actor.character_id)))) continue;
          if (!actor && referenceImageUrl) continue;
          const referenceReservationId = await this.repository.reserveCost("fal", this.config.FAL_ESTIMATED_IMAGE_COST_USD, {
            contentId: content.id,
            runId: content.run_id,
            metadata: { operation: "campaign-character-reference", character_id: actor?.character_id ?? null },
          });
          let reference;
          try {
            reference = await this.mediaProvider.generateReferenceImage(carried.continuity&&actor
              ? `LOCKED ACTOR IDENTITY ${actor.character_id}. ${actor.appearance}. Exact wardrobe and hair: ${actor.wardrobe}. Face and upper body clearly visible against a plain neutral grey backdrop. Only this fictional adult. No setting, props, other people, text, logos or UI. Natural skin and expression; identity reference, not a poster.`
              : referenceImagePrompt(content, actor));
            await this.repository.settleCost(referenceReservationId, this.config.FAL_ESTIMATED_IMAGE_COST_USD, reference.raw?.requestId ?? null);
          } catch (error) {
            try { await this.repository.releaseCost(referenceReservationId); } catch (_) { /* preserve provider error */ }
            throw error;
          }
          referenceImageUrl = await this.repository.uploadAsset(
            `${content.content_key}/${generationId}/character-reference${actor ? `-${actor.character_id}` : ""}.png`,
            reference.buffer,
            reference.mimeType ?? "image/png",
          );
          if (actor) characterReferenceUrls[actor.character_id] = referenceImageUrl;
          await checkpoint();
        }
      }
      for(const place of carried.continuity?.locations??[]){
        if(locationReferenceUrls[place.location_id]&&locationReferenceHashes[place.location_id]===locationFingerprint(place))continue;
        const reservation=await this.repository.reserveCost("fal",this.config.FAL_ESTIMATED_IMAGE_COST_USD,{contentId:content.id,runId:content.run_id,metadata:{operation:"locked-location-reference",location_id:place.location_id}});
        let reference;
        try{reference=await this.mediaProvider.generateReferenceImage(locationReferencePrompt(place));await this.repository.settleCost(reservation,this.config.FAL_ESTIMATED_IMAGE_COST_USD,reference.raw?.requestId??null);}
        catch(error){await this.repository.releaseCost(reservation).catch(()=>{});throw error;}
        locationReferenceUrls[place.location_id]=await this.repository.uploadAsset(`${content.content_key}/${generationId}/location-${place.location_id}-${locationFingerprint(place).slice(0,12)}.png`,reference.buffer,reference.mimeType??"image/png");
        locationReferenceHashes[place.location_id]=locationFingerprint(place);await checkpoint();
      }
      for (const scene of plannedScenes) {
        if (existing.has(scene.scene_id)) continue;
        if ((scene.asset_type ?? "generated_video") === "generated_video") {
          sceneRecords.push(await this.queueVideoScene(content, scene, plan.cast?.length ? {...characterReferenceUrls,...(carried.continuity?{_locations:locationReferenceUrls,_scene_locations:carried.continuity.scene_locations}:{})} : referenceImageUrl));
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
        await checkpoint();
      }
      sceneRecords.sort((a, b) => plannedScenes.findIndex((s) => s.scene_id === a.scene_id) - plannedScenes.findIndex((s) => s.scene_id === b.scene_id));
      const firstPending = sceneRecords.find((scene) => ["queued", "running"].includes(scene.status));
      const updated = await this.repository.updateContent(content.id, {
        status: "generating",
        provider: "fal-reference+gymfeed-edit",
        provider_task_id: firstPending?.task_id ?? null,
        failure_reason: null,
        decision: {
          ...content.decision,
          generation: {
            ...carried,
            mode: carried.revision_scope ? "selective_revision" : "multi_scene_reference",
            generation_id: generationId,
            reference_image_url: referenceImageUrl,
            character_reference_urls: characterReferenceUrls,
            location_reference_urls:locationReferenceUrls,location_reference_hashes:locationReferenceHashes,
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
        if (!this.humanReviewOnly && (task.error?.infrastructureFailure === true
          || record.operation === "edit" && task.error?.type === "literal_error")
          && Number(record.attempt ?? 0) < (this.config.FAL_SCENE_MAX_ATTEMPTS ?? 2)) {
          const sceneSpec = sceneSpecs.get(record.scene_id) ?? plan.scenes[0];
          const retry = await this.queueVideoScene(
            content,
            sceneSpec,
            plan.cast?.length ? generation.character_reference_urls : generation.reference_image_url,
            Number(record.attempt ?? 0) + 1,
            `The previous provider attempt failed before producing media: ${reason}. Preserve the approved story and execute the same shot cleanly.`,
          );
          sceneRecords[index] = {
            ...retry,
            edit_attempts: record.edit_attempts ?? 0,
            history: [...(record.history ?? []), {
              attempt: record.attempt,
              task_id: record.task_id,
              failure_reason: reason,
              provider_error: task.error,
            }],
          };
          continue;
        }
        sceneRecords[index] = { ...record, status: "failed", failure_reason: reason };
        continue;
      }
      const videoUrl = task.content?.video_url ?? task.output?.video_url;
      if (!videoUrl) throw new Error(`fal.ai scene ${record.scene_id} succeeded without a video URL`);
      const video = await fetchAsset(videoUrl, this.fetchFn);
      const sceneSpec = sceneSpecs.get(record.scene_id) ?? plan.scenes[0];
      const version = `${generation.generation_id ?? content.provider_task_id}/${record.scene_id}/attempt-${record.attempt}`;
      const assetUrl = await this.repository.uploadAsset(`${content.content_key}/${version}/${record.operation==="lip_sync"?"synchronized":"raw"}.mp4`, video.buffer, video.contentType);
      const contactSheet = await extractVideoContactSheet(video.buffer, sceneSpec.source_duration_seconds ?? sceneSpec.duration_seconds, 9);
      const contactSheetUrl = await this.repository.uploadAsset(`${content.content_key}/${version}/contact-sheet-9.jpg`, contactSheet, "image/jpeg");
      let technical = await inspectVideo(video.buffer);
      if(generation.continuity&&sceneSpec.audio_strategy==="native"){
        if(record.operation==="lip_sync"){
          const speech=generation.speech[record.scene_id];
          technical={...technical,...speech.padded.technical,has_audio:true,source_transcript:speech.technical.transcript,
            transcript:speech.technical.transcript,expected_dialogue:sceneSpec.spoken_dialogue,speech_timing_source:"full_source",audio_provenance:"canonical_locked"};
        }
      } else if (this.humanReviewOnly && sceneSpec.audio_strategy === "native" && sceneSpec.spoken_dialogue?.trim()) {
        technical = await this.timedSpeech(content, sceneSpec, video.buffer, technical);
      } else if (!this.humanReviewOnly && sceneSpec.spoken_dialogue?.trim()) {
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
            const audio = await extractVideoAudio(video.buffer, this.humanReviewOnly ? {} : { startSeconds: sceneSpec.source_start_seconds ?? 0, durationSeconds: sceneSpec.duration_seconds });
            const transcription = await this.voiceProvider.transcribe({ audioBuffer: audio, buffer: audio, timestamps: this.humanReviewOnly });
            const normalize = (value) => String(value ?? "").toLowerCase().replace(/[^a-z0-9\s]/g, " ").replace(/\s+/g, " ").trim();
            technical = {
              ...technical,
              expected_dialogue: sceneSpec.spoken_dialogue,
              transcript: transcription.text,
              ...(transcription.words?.length ? { words: transcription.words } : {}),
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
      const editorialCut = this.humanReviewOnly && sceneSpec.audio_strategy === "native" && (!generation.continuity||record.operation==="lip_sync") ? dialogueCut(sceneSpec, technical, generation.editorial_settings) : null;
      if (editorialCut) technical = { ...technical, source_transcript: technical.transcript, transcript: editorialCut.transcript };
      sceneRecords[index] = { ...record, status: "generated", asset_url: assetUrl, contact_sheet_url: contactSheetUrl, technical, editorial_cut: editorialCut, failure_reason: null,
        ...(record.operation==="lip_sync"?{lip_sync:{...record.lip_sync,status:"completed"}}:{}) };
      // Save each downloaded clip immediately. A restart must not discard paid
      // results or cause the already completed scene to be submitted again.
      generation.scenes = [...sceneRecords];
      await this.repository.updateContent(content.id, {
        decision: { ...content.decision, generation: { ...generation, scenes: [...sceneRecords] },
          ...(this.humanReviewOnly ? { workflow: { ...content.decision.workflow, stage: "generating", at: new Date().toISOString(), message: `Saving existing clips: ${sceneRecords.filter((s) => s.asset_url).length}/${sceneRecords.filter((s) => s.asset_type === "generated_video").length}. No automatic AI QA or paid retakes.` } } : {}),
        },
      });
    }

    generation.scenes = sceneRecords;
    const pendingTask = sceneRecords.find((scene) => ["queued", "running"].includes(scene.status));
    content = await this.repository.updateContent(content.id, {
      decision: { ...content.decision, generation },
      provider_task_id: pendingTask?.task_id ?? null,
      ...(pendingTask ? { failure_reason: null } : {}),
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

    if (this.humanReviewOnly) return this.finishVideoGeneration(content, sceneRecords, generation);

    let queuedRetry = false;
    for (let index = 0; index < sceneRecords.length; index += 1) {
      const record = sceneRecords[index];
      if (record.asset_type !== "generated_video" || record.status !== "generated") continue;
      const sceneSpec = sceneSpecs.get(record.scene_id) ?? plan.scenes[0];
      let reservationId;
      try {
        reservationId = await this.repository.reserveCost("openai", this.config.OPENAI_ESTIMATED_QA_COST_USD ?? 0.15, {
          contentId: content.id,
          runId: content.run_id,
          metadata: { operation: "scene-qa", scene_id: record.scene_id, attempt: record.attempt },
        });
      } catch (error) {
        if (!openAiBudgetExceeded(error)) throw error;
        sceneRecords[index] = { ...record, status: "qa_failed", qa_score: null, qa: { accept: false, summary: "Scene AI QA unavailable: monthly OpenAI budget reached", defects: ["Scene AI QA unavailable: monthly OpenAI budget reached"], required_fixes: [], review_status: "budget_blocked" } };
        continue;
      }
      let result;
      try {
        result = await this.brain.sceneQualityReview(content, sceneSpec, [record.contact_sheet_url,
          ...sceneReferenceUrls(plan, sceneSpec, plan.cast?.length ? generation.character_reference_urls : generation.reference_image_url)]);
        await this.repository.settleCost(reservationId, result.costUsd, result.responseId);
      } catch (error) {
        await settleOrReleaseOpenAiReservation(this.repository, reservationId, error);
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
      const edited = await this.queueSceneEdit(content, sceneSpec, record, result.data, score);
      const retry = edited ?? await this.queueVideoScene(
        content,
        sceneSpec,
        plan.cast?.length ? generation.character_reference_urls : generation.reference_image_url,
        record.attempt + 1,
        result.data.retry_prompt || result.data.required_fixes.join("; "),
      );
      sceneRecords[index] = {
        ...retry,
        edit_attempts: retry.edit_attempts ?? record.edit_attempts ?? 0,
        history: [...(record.history ?? []), {
          attempt: record.attempt,
          operation: record.operation ?? "generate",
          task_id: record.task_id,
          model: record.model,
          asset_url: record.asset_url,
          contact_sheet_url: record.contact_sheet_url,
          qa_score: score,
          qa: result.data,
        }],
      };
      queuedRetry = true;
    }

    generation.scenes = sceneRecords;
    if (queuedRetry) {
      const pendingTask = sceneRecords.find((scene) => scene.status === "queued");
      const updated = await this.repository.updateContent(content.id, {
        status: "generating",
        provider_task_id: pendingTask?.task_id ?? null,
        failure_reason: null,
        decision: { ...content.decision, generation },
      });
      return { skipped: false, pending: true, content: updated, retrying: true };
    }

    return this.finishVideoGeneration(content, sceneRecords, generation);
  }

  async finishVideoGeneration(content, sceneRecords, generation) {
    let generatedRecords = sceneRecords.filter((scene) => scene.asset_type === "generated_video");
    if (!generatedRecords.length || generatedRecords.some((scene) => !(this.humanReviewOnly ? ["generated", "qa_passed", "qa_failed"] : ["qa_passed", "qa_failed"]).includes(scene.status) || !scene.asset_url)) {
      throw new Error("Cannot assemble this revision: at least one required shot has no saved source clip");
    }
    if(generation.continuity){
      content=await prepareLockedSpeech(this,content);generation={...content.decision.generation,scenes:sceneRecords};
      // One face per native shot prevents the sync model assigning speech to a listener.
      const unsynced=generatedRecords.filter(record=>needsLipSync(content,content.decision.content.scenes.find(scene=>scene.scene_id===record.scene_id),record));
      for(const record of unsynced){
        const scene=content.decision.content.scenes.find(scene=>scene.scene_id===record.scene_id);
        if((record.production_spec?.character_ids??scene.character_ids)?.length!==1)throw Error(`Single-speaker framing required before synchronizing ${scene.scene_id}. Existing footage is retained.`);
      }
      for(const record of unsynced){
        const scene=content.decision.content.scenes.find(scene=>scene.scene_id===record.scene_id);
        const queued=await queueLockedLipSync(this,content,scene,record);
        sceneRecords=sceneRecords.map(item=>item.scene_id===record.scene_id?queued:item);
        generation={...content.decision.generation,scenes:sceneRecords};
        content=await this.repository.updateContent(content.id,{status:"generating",provider_task_id:queued.task_id,decision:{...content.decision,generation,
          workflow:{...content.decision.workflow,stage:"generating",at:new Date().toISOString(),message:`Synchronizing fixed creator voices on saved shots (${unsynced.length} required). No new scene generation.`}}});
      }
      if(unsynced.length)return {skipped:false,pending:true,content};
      generatedRecords=sceneRecords.filter(scene=>scene.asset_type==="generated_video");
    }
    if (this.humanReviewOnly) content = await this.repository.updateContent(content.id, {
      decision: { ...content.decision, workflow: { ...content.decision.workflow, stage: "generating", at: new Date().toISOString(), message: `All ${generatedRecords.length} clips are saved. Assembling the review video locally; no new fal generation.` } },
    });
    const sceneVideoBuffers = [];
    for (const record of generatedRecords) {
      const downloaded = await fetchAsset(record.asset_url, this.fetchFn);
      const spec = content.decision.content.scenes.find((scene) => scene.scene_id === record.scene_id);
      if (this.humanReviewOnly && spec.audio_strategy === "native" && spec.spoken_dialogue?.trim()) {
        if (record.technical?.speech_timing_source !== "full_source") {
          record.technical = await this.timedSpeech(content, spec, downloaded.buffer, await inspectVideo(downloaded.buffer));
        }
        record.editorial_cut = dialogueCut(spec, record.technical, generation.editorial_settings);
        if (record.editorial_cut) record.technical = { ...record.technical, transcript: record.editorial_cut.transcript };
        generation.scenes = [...sceneRecords];
        content = await this.repository.updateContent(content.id, { decision: { ...content.decision, generation: { ...generation } } });
      }
      sceneVideoBuffers.push({ sceneId: record.scene_id, buffer: downloaded.buffer, localTreatment: record.local_treatment ?? null });
    }
    const sceneVoiceoverBuffers = await this.sceneAudio(content);
    generation.narration = { ...generation.narration, ...content.decision.generation?.narration };
    const narrationDurations = {};
    if (this.humanReviewOnly) for (const narration of sceneVoiceoverBuffers) {
      if (!narration.missingNarration) narrationDurations[narration.sceneId] = (await inspectVideo(narration.buffer)).duration_seconds;
    }
    const plan = this.humanReviewOnly ? editorialPlan(content.decision.content, sceneRecords, narrationDurations, generation.editorial_settings) : content.decision.content;
    if(generation.continuity)plan.discard_source_audio=true;
    const sceneDialogueBuffers=[];
    for(const scene of generation.continuity?plan.scenes:[]){
      if(scene.audio_strategy!=="native")continue;
      const speech=generation.speech[scene.scene_id];
      if(!speech?.padded?.url)throw Error(`No canonical dialogue track for ${scene.scene_id}`);
      const audio=await fetchAsset(speech.padded.url,this.fetchFn);
      sceneDialogueBuffers.push({sceneId:scene.scene_id,buffer:await extractVideoAudio(audio.buffer,{startSeconds:scene.source_start_seconds,durationSeconds:scene.duration_seconds})});
    }
    if (this.humanReviewOnly) generation.editorial_timeline = plan.scenes.map(({scene_id, source_start_seconds, duration_seconds}) => ({scene_id, source_start_seconds, duration_seconds}));
    const voiceoverBuffer = await this.createVoiceover(content);
    const renderOptions = plan.scenes.some((scene) => scene.asset_type)
      ? { sceneVideoBuffers, voiceoverBuffer }
      : { supportingVideoBuffer: sceneVideoBuffers[0]?.buffer ?? null, voiceoverBuffer };
    generation.preview_audio_gaps = sceneVoiceoverBuffers.filter((scene) => scene.missingNarration).map((scene) => scene.sceneId);
    const sceneCaptions = Number(plan.production_version) >= 3
      ? verifiedSceneCaptions(plan, sceneRecords, generation.preview_audio_gaps)
      : {};
    generation.preview_caption_gaps = Number(plan.production_version) >= 3
      ? (plan.scenes ?? [])
        .filter((scene) => ["native", "voiceover"].includes(scene.audio_strategy) && !sceneCaptions[scene.scene_id])
        .map((scene) => scene.scene_id)
      : [];
    const sceneCaptionTimings = this.humanReviewOnly ? timedSceneCaptions(plan, sceneRecords, sceneVoiceoverBuffers) : null;
    if (sceneCaptionTimings) generation.preview_caption_gaps = plan.captions_enabled === false ? [] : plan.scenes
      .filter((scene) => ["native", "voiceover"].includes(scene.audio_strategy) && !sceneCaptionTimings[scene.scene_id]?.length)
      .map((scene) => scene.scene_id);
    const version = generation.generation_id ?? randomUUID();
    const variants = [
      { platform: "instagram", filename: "final-instagram-reel.mp4" },
      { platform: "tiktok", filename: "final-tiktok.mp4" },
      { platform: "youtube", filename: "final-youtube-short.mp4" },
    ];
    const platformVariants = { ...(generation.platform_variants ?? {}) };
    let sharedLongMaster = this.humanReviewOnly && plan.preserve_story_timeline
      ? Object.values(platformVariants).find((variant) => variant.url && variant.contact_sheet_url) : null;
    for (const variant of variants) {
      if (platformVariants[variant.platform]?.url && platformVariants[variant.platform]?.contact_sheet_url) continue;
      // Owner-review stories retain the approved sequence on every platform.
      // Encode once rather than spending three times the local rendering time.
      if (this.humanReviewOnly && plan.preserve_story_timeline && sharedLongMaster) {
        platformVariants[variant.platform] = { ...sharedLongMaster };
        continue;
      }
      const renderedVideo = await renderProductVideo(plan, {
        ...renderOptions,
        sceneVoiceoverBuffers,
        sceneCaptions,
        sceneCaptionTimings,
        sceneDialogueBuffers,
        platform: variant.platform,
        appCaptureResolver: this.appCaptureResolver,
      });
      const duration = platformVideoDuration(plan, variant.platform);
      if (this.humanReviewOnly) content = await this.repository.updateContent(content.id, {
        decision: { ...content.decision, workflow: { ...content.decision.workflow, stage: "generating", at: new Date().toISOString(), message: "Local rendering is complete. Uploading the finished review video; no new fal generation." } },
      });
      const storedVideo = await this.repository.uploadAsset(`${content.content_key}/${version}/${variant.filename}`, renderedVideo, "video/mp4");
      const contactSheet = await extractVideoContactSheet(renderedVideo, duration, 16);
      const contactSheetUrl = await this.repository.uploadAsset(`${content.content_key}/${version}/contact-sheet-${variant.platform}-16.jpg`, contactSheet, "image/jpeg");
      let technical;
      if (this.humanReviewOnly || variant.platform === "youtube") {
        technical = await this.finalTechnical(content, renderedVideo, { expectedDuration: duration });
      } else {
        const inspected = await inspectVideo(renderedVideo);
        technical = {
          ...inspected,
          duration_matches_plan: Math.abs(inspected.duration_seconds - duration) <= 0.3,
          derived_from_verified_scenes: true,
        };
      }
      platformVariants[variant.platform] = { url: storedVideo, contact_sheet_url: contactSheetUrl, duration_seconds: duration, technical };
      if (this.humanReviewOnly && plan.preserve_story_timeline) sharedLongMaster = platformVariants[variant.platform];
      generation.platform_variants = { ...platformVariants };
      await this.repository.updateContent(content.id, { decision: { ...content.decision, generation: { ...generation } } });
    }
    generation.platform_variants = platformVariants;
    generation.final_technical = platformVariants.youtube.technical;
    generation.scenes = sceneRecords;
    const updated = await this.repository.updateContent(content.id, {
      status: "generated",
      provider_task_id: null,
      asset_urls: variants.map(({ platform }) => platformVariants[platform].url),
      thumbnail_url: platformVariants.youtube.contact_sheet_url,
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
    if (this.humanReviewOnly) {
      if (!content.asset_urls?.length) throw new Error("Cannot request human review without a completed asset");
      const music=photoMusicPlan(content,this.config);
      const generation = content.decision?.generation ?? {};
      const editNotes = [...new Set([
        ...(generation.scenes ?? []).flatMap((scene) => scene.editorial_cut?.issues ?? (scene.editorial_cut?.note ? [`${scene.scene_id}: ${scene.editorial_cut.note}`] : [])),
        ...(generation.final_technical?.sentence_integrity?.issues ?? []),
        ...(generation.preview_audio_gaps ?? []).map((id) => `${id}: narration is missing from this preview`),
        ...(generation.preview_caption_gaps ?? []).map((id) => `${id}: timed captions could not be verified from the audio`),
        ...(content.content_type === "video" && !generation.final_technical?.sentence_integrity?.checked ? ["Complete final speech has not been verified"] : []),
        ...(generation.final_technical?.duration_matches_plan === false ? ["Export duration differs from the complete story timeline"] : []),
      ])];
      const reviewSummary = ["AI QA is disabled. Review the finished asset, then Approve to send it to Buffer or Reject with revision instructions.", ...editNotes].join("\n");
      const updated = await this.repository.updateContent(id, {
        status: "awaiting_approval", qa_score: null, failure_reason: null,
        qa: { review_status: "human_review_required", summary: reviewSummary, editorial_notes: editNotes, publish: false },
        decision: { ...content.decision, ...(music?{photo_music:music}:{}), workflow: { ...content.decision?.workflow, stage: "review", message: music?photoMusicMessage(music):editNotes.length
          ? `Needs Review: ${editNotes.join("; ")}. Preview is available. No automatic retakes; Approve accepts it as-is, Reject with instructions revises the affected parts.`
          : content.content_type === "video"
            ? "Ready for your review. Frame preview created and complete audio checked. Approve sends this asset to Buffer; Reject with instructions revises the affected parts."
            : "Ready for your review. Approve sends this asset to Buffer; Reject with instructions requests a revised version." } },
      });
      return { skipped: false, passed: true, humanReviewRequired: true, content: updated };
    }
    const sceneIssues = content.content_type === "video"
      ? (content.decision?.generation?.scenes ?? []).filter((scene) => scene.status === "qa_failed")
        .map((scene) => `${scene.scene_id}: ${scene.qa?.defects?.[0] || scene.qa?.required_fixes?.[0] || "Scene QA failed"}`)
      : [];
    const story = content.decision?.story_review;
    const storyIssues = content.content_type === "video" && Number(content.decision.content.production_version) >= 3
      && story?.fingerprint === storyFingerprint(content.decision.content) && !storyReviewPassed(story)
      ? [`Creative story QA: ${story.required_fixes?.join("; ") || story.summary || "did not pass"}`] : [];
    const technical = content.decision?.generation?.final_technical;
    const technicalIssues = content.content_type === "video" && Number(content.decision.content.production_version) >= 2
      && (!technical?.final_dialogue_match || !technical?.duration_matches_plan)
      ? ["Final edited audio or duration does not match the approved plan"] : [];
    const audioIssues = (content.decision?.generation?.preview_audio_gaps ?? []).map((sceneId) => `${sceneId}: Narration missing from budget-limited preview`);
    const captionIssues = (content.decision?.generation?.preview_caption_gaps ?? []).map((sceneId) => `${sceneId}: Subtitle omitted because spoken audio could not be verified`);
    const variantVisuals = Object.values(content.decision?.generation?.platform_variants ?? {})
      .map((variant) => variant.contact_sheet_url).filter(Boolean);
    const visuals = content.content_type === "video"
      ? (variantVisuals.length ? variantVisuals : [content.thumbnail_url].filter(Boolean))
      : content.asset_urls;
    let reservationId;
    try {
      reservationId = await this.repository.reserveCost("openai", this.config.OPENAI_ESTIMATED_DAILY_COST_USD, { contentId: content.id, runId: content.run_id, metadata: { operation: "qa" } });
    } catch (error) {
      if (content.content_type !== "video" || !content.asset_urls?.length || !/openai provider budget exceeded/i.test(error.message)) throw error;
      const scores = (content.decision?.generation?.scenes ?? []).map((scene) => scene.qa_score).filter(Number.isFinite);
      const lowest = scores.length ? Math.min(...scores) : null;
      const issues = [...storyIssues, ...sceneIssues, ...audioIssues, ...captionIssues, ...technicalIssues, "Final AI QA could not run: monthly OpenAI budget reached"];
      const updated = await this.repository.updateContent(id, {
        status: "qa_failed", qa_score: lowest,
        qa: { publish: false, summary: `Preview ready. ${lowest == null ? "Scene QA scores unavailable" : `Lowest scene QA: ${lowest}`}; final AI QA pending budget reset.`, critical_issues: issues, required_fixes: [], review_status: "budget_blocked" },
        failure_reason: issues.join("; ").slice(0, 1800),
      });
      return { skipped: false, passed: false, content: updated };
    }
    try {
      const qaVisuals = [];
      for (const visualUrl of visuals) {
        const visual = await fetchAsset(visualUrl, this.fetchFn);
        if (!visual.contentType.startsWith("image/")) throw new Error(`Final QA visual is not an image: ${visual.contentType}`);
        qaVisuals.push(`data:${visual.contentType};base64,${visual.buffer.toString("base64")}`);
      }
      const result = await this.brain.qualityReview(content, qaVisuals);
      await this.repository.settleCost(reservationId, result.costUsd, result.responseId);
      const score = overallQaScore(result.data);
      const brand = await this.repository.brandConfig();
      const issues = [...storyIssues, ...sceneIssues, ...audioIssues, ...captionIssues, ...technicalIssues, ...(result.data.critical_issues ?? [])];
      const passed = result.data.publish && score >= brand.minimum_qa_score && !storyIssues.length && !sceneIssues.length && !audioIssues.length && !captionIssues.length && !technicalIssues.length;
      const updated = await this.repository.updateContent(content.id, {
        status: passed ? "awaiting_approval" : "qa_failed",
        qa_score: score,
        qa: { ...result.data, publish: passed, critical_issues: issues },
        failure_reason: passed ? null : issues.join("; ").slice(0, 1800) || "QA threshold not met",
      });
      return { skipped: false, passed, content: updated };
    } catch (error) {
      await settleOrReleaseOpenAiReservation(this.repository, reservationId, error);
      throw error;
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
      const resumableGeneratedScene = (content.decision?.generation?.scenes ?? [])
        .some((scene) => scene.asset_type === "generated_video" && (scene.status === "generated" || this.humanReviewOnly && scene.asset_url));
      if (!content.provider_task_id && !resumableGeneratedScene) {
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
      if (content.provider_task_id && pollIntervalMs > 0) await wait(pollIntervalMs);
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
      await settleOrReleaseOpenAiReservation(this.repository, reservationId, error);
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
      const scheduled = campaignSchedule(campaign.date, campaign.timezone ?? "America/New_York", content.content_type === "video" ? 18 : content.content_type === "image" ? 9 : 12, minutes);
      if (Date.parse(scheduled) <= Date.now() + 60_000) {
        const error = new Error("Campaign slot is in the past or too soon. Change and reapprove the campaign dates; never publish immediately as a fallback.");
        // This check happens before any Buffer request, so retrying after the
        // reviewer changes the planned date cannot create a duplicate post.
        error.safeToRetry = true;
        throw error;
      }
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

  publicationChannels(contentType) {
    const accounts = {
      instagram: this.config.BUFFER_INSTAGRAM_CHANNEL_ID,
      tiktok: this.config.BUFFER_TIKTOK_CHANNEL_ID,
      ...(contentType === "video" ? { youtube: this.config.BUFFER_YOUTUBE_CHANNEL_ID } : {}),
    };
    return Object.fromEntries(Object.entries(accounts).filter(([, account]) => account));
  }

  publicationMedia(content, platform) {
    const variants = content.decision?.generation?.platform_variants;
    const variant = variants?.[platform]?.url;
    if (content.content_type === "video" && variants && !variant) {
      throw new Error(`Missing ${platform} video variant; publication stopped before Buffer submission`);
    }
    const urls = content.content_type === "video" ? [variant ?? content.asset_urls?.[0]].filter(Boolean) : content.asset_urls;
    if (!urls?.length) throw new Error(`No media asset is available for ${platform}`);
    return urls;
  }

  async publishContent(id, { explicitBatchRelease = false } = {}) {
    const content = await this.repository.contentById(id);
    if (!["approved", "scheduled"].includes(content.status)) return { skipped: true, reason: `status is ${content.status}`, content };
    if (this.campaigns) await this.campaigns.assertPublicationAllowed(id);
    if (!this.config.AUTO_PUBLISH && !(explicitBatchRelease && content.decision?.campaign?.id)) return { skipped: true, reason: "automatic publishing disabled", content };
    const brand = await this.repository.brandConfig();
    if (!brand.enabled) return { skipped: true, reason: "marketing disabled", content };

    const accountByPlatform = this.publicationChannels(content.content_type);
    const platforms = Object.keys(accountByPlatform);
    if (!platforms.length) throw new Error("No Buffer channel IDs are configured for this content");

    const publications = [];
    const existing = this.repository.publicationByContent ? await this.repository.publicationByContent(id) : [];
    for (const platform of platforms) {
      const previous = existing.find((row) => row.platform === platform);
      if (previous?.provider_request_id) { publications.push(previous); continue; }
      if (previous?.status === "pending" && previous.error) throw new Error(`Buffer ${platform} submission is unresolved. Reconcile it in Buffer before retrying.`);
      const copy = this.platformPlan(content, platform);
      const mediaUrls = this.publicationMedia(content, platform);
      const scheduledAt = this.scheduledTime(content, platform);
      if (content.decision?.campaign?.id && !scheduledAt) throw new Error("Campaign publishing requires an explicit future schedule");
      const music=photoMusicPlan(content,this.config);
      const copyWithMedia = { ...copy, media_url: mediaUrls[0],...(music?{photo_music:music,delivery:{scheduling_type:"notification",user_action_required:false,music_status:"scheduled_music_notification"}}:{}) };
      await this.repository.upsertPublication({ content_id: content.id, platform, account_ref: accountByPlatform[platform], status: "pending", platform_copy: copyWithMedia, error: "Submission in progress; reconcile if interrupted" });
      try {
        const response = await this.publisher.publish({
          platform,
          accountId: accountByPlatform[platform],
          mediaUrls,
          text: copy.text,
          title: copy.title,
          isVideo: content.content_type === "video",
          scheduledTime: scheduledAt,
          ...(music?{music}:{}),
        });
        const requestId = response.id ?? response.post?.id;
        if (!requestId) throw new Error("Buffer returned no post ID");
        publications.push(await this.repository.upsertPublication({
          content_id: content.id,
          platform,
          account_ref: accountByPlatform[platform],
          status: scheduledAt ? "scheduled" : "publishing",
          platform_copy: copyWithMedia,
          provider_request_id: requestId,
          scheduled_at: scheduledAt ?? null,
          error: null,
        }));
      } catch (error) {
        publications.push(await this.repository.upsertPublication({
          content_id: content.id,
          platform,
          account_ref: accountByPlatform[platform],
          status: error.safeToRetry ? "failed" : "pending",
          ...(error.bufferPostId ? { provider_request_id: error.bufferPostId } : {}),
          platform_copy: copyWithMedia,
          error: error.safeToRetry ? `Buffer rejected submission: ${error.message}` : `Submission uncertain; check Buffer before retrying: ${error.message}`,
        }));
      }
    }
    if (publications.length && publications.every((publication) => publication.provider_request_id && !publication.error)) {
      const scheduledAt = publications.map((publication) => publication.scheduled_at).filter(Boolean).sort()[0] ?? null;
      await this.repository.updateContent(content.id, { status: "scheduled", scheduled_at: scheduledAt });
    }
    return { skipped: false, content: await this.repository.contentById(id), publications };
  }

  async refreshPublications() {
    const publications = await this.repository.pendingPublications();
    const updated = [];
    for (const publication of publications) {
      try {
        const remote = await this.publisher.getPost(publication.provider_request_id);
        const delivery=bufferDeliveryState(remote,publication);
        const status=delivery.status;
        const metricDetails = remote.metrics ?? remote.post?.metrics ?? [];
        const metricValues = Object.fromEntries(metricDetails.map((metric) => [metric.type, metric.value]));
        updated.push(await this.repository.updatePublication(publication.id, {
          status,
          ...(delivery.delivery.scheduling_type==="notification"?{platform_copy:{...publication.platform_copy,delivery:delivery.delivery}}:{}),
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
