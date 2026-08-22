import { minimumQaScore } from "./contracts.mjs";
import { renderCarouselSlide } from "./render-carousel.mjs";

function utcDateKey(now = new Date()) {
  return now.toISOString().slice(0, 10);
}

function isoWeekKey(now = new Date()) {
  const date = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  date.setUTCDate(date.getUTCDate() + 4 - (date.getUTCDay() || 7));
  const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
  const week = Math.ceil((((date - yearStart) / 864e5) + 1) / 7);
  return `${date.getUTCFullYear()}-W${String(week).padStart(2, "0")}`;
}

function videoPrompt(content) {
  const plan = content.decision.content;
  const scene = plan.scenes[0];
  return [
    `Create a vertical 9:16, ${scene.duration_seconds}-second platform-native fitness video for GymFeed.`,
    `Concept: ${plan.concept}`,
    `Hook: ${plan.hook}`,
    `Camera: ${scene.camera}`,
    `Subject: ${scene.subject}`,
    `Action: ${scene.action}`,
    `Environment: ${scene.environment}`,
    `Lighting: ${scene.lighting}`,
    `Visual style: ${scene.visual_style}`,
    scene.spoken_dialogue ? `Spoken dialogue: ${scene.spoken_dialogue}` : "No spoken dialogue.",
    scene.ambient_audio ? `Ambient audio: ${scene.ambient_audio}` : "Natural ambient sound.",
    "Do not show brand logos, watermarks, unsafe exercise technique, body transformations, or text overlays.",
    "Do not imitate a real influencer or celebrity. People should be fictional adults.",
  ].join("\n");
}

function withHashtags(text, hashtags = []) {
  const tags = hashtags.map((tag) => tag.startsWith("#") ? tag : `#${tag}`).join(" ");
  return [text, tags].filter(Boolean).join("\n\n");
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
  constructor({ config, repository, brain, gemini, byteplus, blotato }) {
    this.config = config;
    this.repository = repository;
    this.brain = brain;
    this.gemini = gemini;
    this.byteplus = byteplus;
    this.blotato = blotato;
  }

  async runDaily(now = new Date()) {
    const idempotencyKey = `daily:${utcDateKey(now)}`;
    const { run, reused } = await this.repository.startRun("daily-cmo", idempotencyKey, { now: now.toISOString() });
    if (reused) return { reused: true, run };

    let reservationId;
    try {
      const brand = await this.repository.brandConfig();
      if (!brand.enabled) {
        return { reused: false, run: await this.repository.finishRun(run.id, "skipped", { reason: "marketing disabled" }) };
      }
      reservationId = await this.repository.reserveCost("openai", this.config.OPENAI_ESTIMATED_DAILY_COST_USD, { runId: run.id, metadata: { operation: "daily-cmo" } });
      const context = await this.repository.loadContext();
      const result = await this.brain.daily(context);
      const content = await this.repository.saveDailyDecision(run.id, result.data, now);
      await this.repository.settleCost(reservationId, result.costUsd, result.responseId);
      const completed = await this.repository.finishRun(run.id, "succeeded", {
        decision: result.data,
        content_ids: content.map((item) => item.id),
      }, result.costUsd);
      return { reused: false, run: completed, content };
    } catch (error) {
      if (reservationId) {
        try { await this.repository.settleCost(reservationId, this.config.OPENAI_ESTIMATED_DAILY_COST_USD); } catch (_) { /* preserve root error */ }
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
      const result = await this.brain.weekly(await this.repository.loadContext());
      const learnings = await this.repository.saveWeeklyReview(run.id, result.data);
      await this.repository.settleCost(reservationId, result.costUsd, result.responseId);
      const completed = await this.repository.finishRun(run.id, "succeeded", { review: result.data, learning_ids: learnings.map((item) => item.id) }, result.costUsd);
      return { reused: false, run: completed, learnings };
    } catch (error) {
      if (reservationId) {
        try { await this.repository.settleCost(reservationId, this.config.OPENAI_ESTIMATED_WEEKLY_COST_USD); } catch (_) { /* preserve root error */ }
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
    return content.content_type === "video" ? this.generateVideo(content) : this.generateInstagramAsset(content);
  }

  async generateInstagramAsset(content) {
    const slides = content.decision.content.slides;
    const estimate = slides.length * this.config.GEMINI_ESTIMATED_IMAGE_COST_USD;
    const reservationId = await this.repository.reserveCost("gemini", estimate, { contentId: content.id, runId: content.run_id, metadata: { slides: slides.length } });
    let generated = 0;
    try {
      await this.repository.updateContent(content.id, { status: "generating", provider: "google-gemini", failure_reason: null });
      const urls = [];
      const refs = [];
      for (let index = 0; index < slides.length; index += 1) {
        const slide = slides[index];
        const image = await this.gemini.generateBackground(slide.visual_prompt);
        generated += 1;
        if (image.raw?.interactionId) refs.push(image.raw.interactionId);
        const rendered = await renderCarouselSlide({
          background: image.buffer,
          headline: slide.headline,
          body: slide.body,
          index,
          total: slides.length,
        });
        urls.push(await this.repository.uploadAsset(`${content.content_key}/slide-${index + 1}.png`, rendered, "image/png"));
      }
      await this.repository.settleCost(reservationId, estimate, refs.filter(Boolean).join(",") || null);
      const updated = await this.repository.updateContent(content.id, { status: "generated", asset_urls: urls });
      return { skipped: false, content: updated };
    } catch (error) {
      try {
        if (generated) await this.repository.settleCost(reservationId, generated * this.config.GEMINI_ESTIMATED_IMAGE_COST_USD);
        else await this.repository.releaseCost(reservationId);
      } catch (_) { /* preserve root error */ }
      await this.repository.updateContent(content.id, { status: "failed", failure_reason: error.message });
      throw error;
    }
  }

  async generateVideo(content) {
    const estimate = this.config.BYTEPLUS_ESTIMATED_VIDEO_COST_USD;
    const reservationId = await this.repository.reserveCost("byteplus", estimate, { contentId: content.id, runId: content.run_id });
    try {
      await this.repository.updateContent(content.id, { status: "generating", provider: "byteplus-seedance", failure_reason: null });
      const plan = content.decision.content;
      const task = await this.byteplus.createTask({
        prompt: videoPrompt(content),
        durationSeconds: plan.scenes[0].duration_seconds,
        generateAudio: plan.audio_mode !== "silent",
      });
      const taskId = task.id ?? task.task_id ?? task.task?.id;
      if (!taskId) throw new Error("BytePlus returned no task ID");
      await this.repository.settleCost(reservationId, estimate, taskId);
      const updated = await this.repository.updateContent(content.id, { provider_task_id: taskId });
      return { skipped: false, content: updated, task };
    } catch (error) {
      try { await this.repository.releaseCost(reservationId); } catch (_) { /* preserve root error */ }
      await this.repository.updateContent(content.id, { status: "failed", failure_reason: error.message });
      throw error;
    }
  }

  async refreshContent(id) {
    const content = await this.repository.contentById(id);
    if (content.content_type !== "video" || content.status !== "generating" || !content.provider_task_id) {
      return { skipped: true, reason: "content has no active video task", content };
    }
    const task = await this.byteplus.getTask(content.provider_task_id);
    const status = String(task.status ?? task.task?.status ?? "").toLowerCase();
    if (["queued", "running", "processing", "pending"].includes(status)) return { skipped: false, pending: true, content, task };
    if (status !== "succeeded") {
      const reason = task.error?.message ?? task.message ?? `BytePlus task ${status || "failed"}`;
      const failed = await this.repository.updateContent(content.id, { status: "failed", failure_reason: reason });
      return { skipped: false, pending: false, content: failed, task };
    }
    const videoUrl = task.content?.video_url ?? task.output?.video_url;
    if (!videoUrl) throw new Error("BytePlus succeeded without a video URL");
    const video = await fetchAsset(videoUrl);
    const storedVideo = await this.repository.uploadAsset(`${content.content_key}/video.mp4`, video.buffer, "video/mp4");
    const lastFrameUrl = task.content?.last_frame_url ?? task.output?.last_frame_url;
    let thumbnailUrl = null;
    if (lastFrameUrl) {
      const frame = await fetchAsset(lastFrameUrl);
      thumbnailUrl = await this.repository.uploadAsset(`${content.content_key}/last-frame.jpg`, frame.buffer, frame.contentType.startsWith("image/") ? frame.contentType : "image/jpeg");
    }
    const updated = await this.repository.updateContent(content.id, { status: "generated", asset_urls: [storedVideo], thumbnail_url: thumbnailUrl });
    return { skipped: false, pending: false, content: updated, task };
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
      const score = minimumQaScore(result.data);
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
      try { await this.repository.settleCost(reservationId, this.config.OPENAI_ESTIMATED_DAILY_COST_USD); } catch (_) { /* preserve root error */ }
      throw error;
    }
  }

  async approveContent(id) {
    const content = await this.repository.contentById(id);
    if (content.status !== "awaiting_approval") return { skipped: true, reason: `status is ${content.status}`, content };
    return { skipped: false, content: await this.repository.updateContent(id, { status: "approved", approved_at: new Date().toISOString() }) };
  }

  platformPlan(content, platform) {
    const plan = content.decision.content;
    const link = trackingUrl(this.config.GYMFEED_LANDING_URL, platform, content.content_key);
    if (content.content_type !== "video") {
      return { text: `${withHashtags(plan.caption, plan.hashtags)}\n\n${link}`, title: null };
    }
    if (platform === "instagram") return { text: `${withHashtags(plan.platform_copy.instagram_caption, plan.platform_copy.hashtags)}\n\n${link}`, title: null };
    if (platform === "tiktok") return { text: `${withHashtags(plan.platform_copy.tiktok_caption, plan.platform_copy.hashtags)}\n\n${link}`, title: null };
    return { text: `${plan.platform_copy.youtube_description}\n\nTry GymFeed: ${link}`, title: plan.platform_copy.youtube_title };
  }

  async publishContent(id) {
    const content = await this.repository.contentById(id);
    if (content.status !== "approved") return { skipped: true, reason: `status is ${content.status}`, content };
    if (!this.config.AUTO_PUBLISH) return { skipped: true, reason: "automatic publishing disabled", content };
    const brand = await this.repository.brandConfig();
    if (!brand.enabled) return { skipped: true, reason: "marketing disabled", content };

    const accountByPlatform = {
      instagram: this.config.BLOTATO_INSTAGRAM_ACCOUNT_ID,
      tiktok: this.config.BLOTATO_TIKTOK_ACCOUNT_ID,
      youtube: this.config.BLOTATO_YOUTUBE_ACCOUNT_ID,
    };
    const platforms = (content.content_type === "video" ? ["instagram", "tiktok", "youtube"] : ["instagram"])
      .filter((platform) => accountByPlatform[platform]);
    if (!platforms.length) throw new Error("No Blotato account IDs are configured for this content");

    const mediaUrls = await this.blotato.ingestMediaUrls(content.asset_urls);
    const publications = [];
    for (const platform of platforms) {
      const copy = this.platformPlan(content, platform);
      try {
        const response = await this.blotato.publish({
          platform,
          accountId: accountByPlatform[platform],
          mediaUrls,
          text: copy.text,
          title: copy.title,
          isVideo: content.content_type === "video",
        });
        const requestId = response.postSubmissionId ?? response.id ?? response.post?.id;
        if (!requestId) throw new Error("Blotato returned no post submission ID");
        publications.push(await this.repository.upsertPublication({
          content_id: content.id,
          platform,
          account_ref: accountByPlatform[platform],
          status: "publishing",
          platform_copy: copy,
          provider_request_id: requestId,
          error: null,
        }));
      } catch (error) {
        publications.push(await this.repository.upsertPublication({
          content_id: content.id,
          platform,
          account_ref: accountByPlatform[platform],
          status: "failed",
          platform_copy: copy,
          error: error.message,
        }));
      }
    }
    if (publications.some((publication) => publication.status !== "failed")) {
      await this.repository.updateContent(content.id, { status: "scheduled" });
    }
    return { skipped: false, content, publications };
  }

  async refreshPublications() {
    const publications = await this.repository.pendingPublications();
    const updated = [];
    for (const publication of publications) {
      try {
        const remote = await this.blotato.getPost(publication.provider_request_id);
        const remoteStatus = String(remote.status ?? remote.post?.status ?? "publishing").toLowerCase();
        const status = ["published", "success", "succeeded"].includes(remoteStatus)
          ? "published"
          : ["failed", "error"].includes(remoteStatus) ? "failed" : remoteStatus === "scheduled" ? "scheduled" : "publishing";
        updated.push(await this.repository.updatePublication(publication.id, {
          status,
          external_post_id: remote.externalPostId ?? remote.post?.externalPostId ?? publication.external_post_id,
          external_url: remote.url ?? remote.post?.url ?? publication.external_url,
          published_at: status === "published" ? (remote.publishedAt ?? new Date().toISOString()) : publication.published_at,
          error: status === "failed" ? (remote.error?.message ?? remote.message ?? "Blotato publish failed") : null,
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
