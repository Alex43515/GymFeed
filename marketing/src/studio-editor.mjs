import { createHash } from "node:crypto";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import sharp from "sharp";
import { probeMp4, UPLOAD_LIMIT } from "./capture-storage.mjs";
import { redact } from "./studio-errors.mjs";
import { hasResumableMediaEdit } from "./studio-jobs.mjs";
import { cutVideoPart, joinVideoParts, planVideoParts } from "./studio-edit-video.mjs";

const VIDEO_MODEL = "fal-ai/kling-video/o3/pro/video-to-video/edit";
const IMAGE_MODEL = "google/nano-banana-2.1/edit";
const GYMFEED_BRAND_PROFILE = "gymfeed-v1";
const wordmarkUrl = new URL("../assets/brand/gymfeed-wordmark-white.png", import.meta.url);
const brandBackground = "#0B100D";
const uuid = /^[a-f0-9]{8}(?:-[a-f0-9]{4}){3}-[a-f0-9]{12}$/i;
const imageTypes = { jpeg: "image/jpeg", png: "image/png", webp: "image/webp" };
const unwrap = ({ data, error }) => {
  if (error) throw Object.assign(new Error(error.message), { statusCode: Number(error.statusCode ?? error.status) || undefined });
  return data;
};
function requireValue(ok, message) {
  if (!ok) throw Object.assign(new Error(message), { statusCode: 400 });
}

async function gymFeedReference() {
  const wordmark = await sharp(await readFile(wordmarkUrl)).resize({ width: 768 }).png().toBuffer();
  const reference = await sharp({ create: { width: 1024, height: 512, channels: 3, background: brandBackground } })
    .composite([{ input: wordmark, gravity: "centre" }]).png().toBuffer();
  return `data:image/png;base64,${reference.toString("base64")}`;
}

function brandDirection(logo) {
  return `GymFeed brand reference: GymFeed (gymfeed.io) is a fitness app for training, nutrition, progress and community. Follow the requested edit and apply the brand only where it fits. Use GymFeed green #0BEA70 for accents, near-black #050605 and charcoal ${brandBackground} for surfaces, high-contrast white text, Poppins-style type and rounded elements. ${logo} shows the official white GymFeed wordmark. Use it as the logo reference, preserving its shape, proportions and spelling. If it fits the requested edit, use it once as a subtle mark or end card. Preserve authentic app UI and existing captions unless asked to change them. Do not invent app screens, product claims or logos.`;
}

export function createStudioEditor({ repository, mediaProvider, publisher, config }) {
  const client = repository.client;
  const storage = client.storage.from("marketing-edit-media");
  const accounts = {
    instagram: config.BUFFER_INSTAGRAM_CHANNEL_ID,
    tiktok: config.BUFFER_TIKTOK_CHANNEL_ID,
    youtube: config.BUFFER_YOUTUBE_CHANNEL_ID,
  };
  const getEdit = async id => unwrap(await client.from("marketing_studio_jobs").select("id,status,payload,result")
    .eq("id", id).eq("kind", "media_edit").maybeSingle());
  const signed = async (path, seconds = 3600) => unwrap(await storage.createSignedUrl(path, seconds)).signedUrl;
  const output = kind => kind === "video" ? ["mp4", "video/mp4"] : ["jpg", "image/jpeg"];
  const saveState = async (job, result) => unwrap(await client.from("marketing_studio_jobs").update({ result })
    .eq("id", job.id).eq("lock_token", job.lock_token).eq("status", "running").select("id").single());
  const download = async path => Buffer.from(await unwrap(await storage.download(path)).arrayBuffer());

  async function submitEdit(job, state, persist, source, duration, prompt) {
    const p = job.payload;
    const video = p.mediaType === "video";
    const model = video ? VIDEO_MODEL : IMAGE_MODEL;
    if (state.submitting && !state.requestId) throw new Error("fal.ai submission is uncertain. Reconcile the previous request before starting a new edit.");
    if (!state.requestId) {
      const url = await source();
      const logo = p.brandProfile === GYMFEED_BRAND_PROFILE ? await gymFeedReference() : null;
      const editPrompt = logo
        ? `${prompt}\n\n${brandDirection(video ? "@Image1" : "The second reference image")}`
        : prompt;
      const estimate = video ? Math.ceil(duration) * 0.168 : config.FAL_ESTIMATED_IMAGE_COST_USD;
      const reservation = await repository.reserveCost("fal", estimate, { metadata: { operation: "media_edit", studioJob: job.id, model } });
      state = { submitting: true, model, reservation, estimate };
      await persist(state);
      try {
        const requestId = await mediaProvider.submitMediaEdit(model, video
          ? { prompt: `Edit @Video1. ${editPrompt}`, video_url: url, ...(logo ? { image_urls: [logo] } : {}),
            keep_audio: true, enable_safety_checker: true }
          : { prompt: editPrompt, image_urls: logo ? [url, logo] : [url],
            num_images: 1, resolution: "1K", output_format: "jpeg", limit_generations: true });
        state = { ...state, requestId, submitting: false };
        await persist(state);
      } catch (error) {
        const code = Number(error.status);
        if (!state.requestId && code >= 400 && code < 500 && ![408, 429].includes(code)) {
          await repository.releaseCost(reservation);
          await persist({});
          throw error;
        }
        throw new Error("fal.ai submission is uncertain. Check the saved provider task before retrying.", { cause: error });
      }
    }
    return state;
  }

  async function editLongVideo(job) {
    const { duration, source, prompt } = job.payload;
    const parts = planVideoParts(duration);
    const states = job.result?.parts ?? parts.map(() => ({}));
    const directory = await mkdtemp(join(tmpdir(), "gymfeed-edit-"));
    const sourceFile = join(directory, "source.mp4");
    const clips = [];
    try {
      await writeFile(sourceFile, await download(source));
      for (const [index, part] of parts.entries()) {
        const outputFile = join(directory, `edited-${index}.mp4`);
        clips.push(outputFile);
        if (states[index].path) {
          await writeFile(outputFile, await download(states[index].path));
          continue;
        }
        const persist = async state => {
          states[index] = state;
          await saveState(job, { parts: states });
        };
        const continuity = "Apply the same edit consistently across the full video. Preserve the shot timing, framing and original aspect ratio.";
        const isEarlyBrandedPart = job.payload.brandProfile === GYMFEED_BRAND_PROFILE && index < parts.length - 1;
        const placement = isEarlyBrandedPart
          ? " Preserve existing branding and leave any new GymFeed mark or end card for the final segment unless the requested edit explicitly calls for it here."
          : "";
        const partPrompt = `${prompt} ${continuity}${placement}`;
        const state = await submitEdit(job, states[index], persist, async () => {
          const inputFile = join(directory, `part-${index}.mp4`);
          await cutVideoPart(sourceFile, inputFile, part);
          const inputPath = `parts/${job.id}/source-${index}.mp4`;
          unwrap(await storage.upload(inputPath, await readFile(inputFile), { contentType: "video/mp4", upsert: true }));
          return signed(inputPath, 7200);
        }, part.duration, partPrompt);
        const buffer = await mediaProvider.mediaEditResult(state.model, state.requestId, true);
        const path = `parts/${job.id}/edited-${index}.mp4`;
        unwrap(await storage.upload(path, buffer, { contentType: "video/mp4", upsert: true }));
        await repository.settleCost(state.reservation, state.estimate, state.requestId);
        await persist({ ...state, path });
        await writeFile(outputFile, buffer);
      }
      const combined = join(directory, "result.mp4");
      await joinVideoParts(sourceFile, clips, parts, combined);
      const path = `outputs/${job.id}.mp4`;
      unwrap(await storage.upload(path, await readFile(combined), { contentType: "video/mp4", upsert: true }));
      return { requestIds: states.map(state => state.requestId), model: VIDEO_MODEL, mediaType: "video", path,
        partCount: parts.length, estimatedCostUsd: states.reduce((sum, state) => sum + state.estimate, 0) };
    } finally {
      await rm(directory, { recursive: true, force: true });
    }
  }

  async function edit(job) {
    const p = job.payload;
    const video = p.mediaType === "video";
    if (video && p.duration > 15.05) return editLongVideo(job);
    const state = await submitEdit(job, job.result ?? {}, state => saveState(job, state),
      () => signed(p.source, 7200), p.duration, p.prompt);
    const buffer = await mediaProvider.mediaEditResult(state.model, state.requestId, video);
    const [ext, contentType] = output(p.mediaType);
    const path = `outputs/${job.id}.${ext}`;
    unwrap(await storage.upload(path, buffer, { contentType, upsert: true }));
    await repository.settleCost(state.reservation, state.estimate, state.requestId);
    return { requestId: state.requestId, model: state.model, mediaType: p.mediaType, path, estimatedCostUsd: state.estimate };
  }

  async function publish(job) {
    const p = job.payload;
    if (job.result?.postId) return job.result;
    if (job.result?.submitting) throw new Error("Buffer submission is uncertain. Check the Buffer queue before retrying.");
    requireValue(Date.parse(p.scheduledTime) > Date.now(), "Termin objave je prošao.");
    const entry = await getEdit(p.editId);
    requireValue(entry?.status === "succeeded" && entry.result?.path, "Sačekaj da se obrada završi.");
    requireValue(accounts[p.platform] && (p.platform !== "youtube" || entry.payload.mediaType === "video"), "Kanal nije dostupan za ovaj format.");
    const buffer = await download(entry.result.path);
    const [ext, contentType] = output(entry.payload.mediaType);
    const mediaUrl = await repository.uploadAsset(`studio-edits/${p.editId}/media.${ext}`, buffer, contentType);
    requireValue(Date.parse(p.scheduledTime) > Date.now(), "Termin objave je prošao.");
    await saveState(job, { submitting: true });
    try {
      const post = await publisher.publish({ platform: p.platform, accountId: accounts[p.platform],
        text: p.caption, title: p.title, mediaUrls: [mediaUrl], scheduledTime: p.scheduledTime, isVideo: entry.payload.mediaType === "video" });
      const result = { postId: post.id, platform: p.platform, scheduledTime: p.scheduledTime };
      await saveState(job, result);
      return result;
    } catch (error) {
      if (error.bufferPostId) {
        await saveState(job, { rejectedPostId: error.bufferPostId });
        throw error;
      }
      throw new Error("Buffer submission is uncertain. Check the Buffer queue before retrying. " + error.message, { cause: error });
    }
  }

  function register(app, jobs, secrets) {
    app.get("/v1/studio/editor", async (_request, reply) => {
      reply.header("cache-control", "no-store");
      const rows = unwrap(await client.from("marketing_studio_jobs").select("id,kind,status,payload,result,error,attempts,max_attempts,created_at")
        .in("kind", ["media_edit", "media_publish"]).order("created_at", { ascending: false }).limit(100));
      const edits = await Promise.all(rows.filter(row => row.kind === "media_edit").map(async row => {
        const { id, status, payload, result, error, attempts, max_attempts, created_at } = row;
        const previewUrl = status === "succeeded" && result?.path ? await signed(result.path) : null;
        return { id, status, mediaType: payload.mediaType, prompt: payload.prompt, created_at, previewUrl,
          error: redact(error, secrets), attempts, max_attempts, resumable: hasResumableMediaEdit(result),
          partCount: result?.parts?.length ?? result?.partCount,
          partsComplete: result?.parts?.filter(part => part.path).length ?? result?.partCount,
          publications: rows.filter(item => item.kind === "media_publish" && item.payload.editId === id).map(item => ({
            platform: item.payload.platform, scheduledTime: item.payload.scheduledTime, status: item.status,
            postId: item.result?.postId, error: redact(item.error, secrets),
          })) };
      }));
      return { channels: Object.keys(accounts).filter(platform => Boolean(accounts[platform])), edits };
    });

    app.post("/v1/studio/editor/upload", { bodyLimit: UPLOAD_LIMIT }, async (request, reply) => {
      const key = request.headers["idempotency-key"];
      requireValue(uuid.test(key ?? ""), "Nedostaje identifikator za otpremanje.");
      let prompt;
      try { prompt = decodeURIComponent(request.headers["x-edit-prompt"] ?? "").trim(); }
      catch { requireValue(false, "Prompt nije ispravno kodiran."); }
      requireValue(prompt.length >= 5 && prompt.length <= 1200, "Unesi prompt od 5 do 1200 znakova.");
      const buffer = request.body;
      requireValue(Buffer.isBuffer(buffer) && buffer.length > 0, "Dodaj video ili sliku.");
      const existing = unwrap(await client.from("marketing_studio_jobs").select("id,status").eq("request_key", `media-edit:${key}`).maybeSingle());
      if (existing) return reply.code(202).send(existing);
      const mediaType = request.headers["x-edit-media-type"];
      let contentType, ext, duration;
      if (mediaType === "video") {
        const info = await probeMp4(buffer);
        duration = info.duration;
        requireValue(duration >= 3 && duration <= 60.05 && Math.min(info.width, info.height) >= 720 && Math.max(info.width, info.height) <= 3840,
          "Editor prihvata MP4 od 3 do 60 sekundi i dimenzije od 720 do 3840 px.");
        [ext, contentType] = output(mediaType);
      } else {
        requireValue(mediaType === "image", "Izaberi video ili sliku.");
        const metadata = await sharp(buffer, { limitInputPixels: 40_000_000 }).metadata().catch(() => null);
        ext = metadata?.format;
        contentType = imageTypes[ext];
        requireValue(contentType && metadata.width && metadata.height, "Dodaj čitljivu JPG, PNG ili WebP sliku.");
      }
      const hash = createHash("sha256").update(buffer).digest("hex");
      const source = `inputs/${key}-${hash}.${ext}`;
      unwrap(await storage.upload(source, buffer, { contentType, upsert: true }));
      const job = await jobs.enqueue({ kind: "media_edit",
        payload: { source, mediaType, prompt, duration, brandProfile: GYMFEED_BRAND_PROFILE }, requestKey: `media-edit:${key}` });
      return reply.code(202).send({ id: job.id, status: job.status });
    });

    app.post("/v1/studio/editor/:id/schedule", async (request, reply) => {
      const id = request.params.id;
      const { platforms, scheduledTime, caption, title } = request.body ?? {};
      requireValue(uuid.test(id), "Prerada nije pronađena.");
      requireValue(typeof scheduledTime === "string" && scheduledTime.endsWith("Z") && Date.parse(scheduledTime) > Date.now(), "Izaberi budući datum i vreme.");
      requireValue(typeof caption === "string" && caption.length <= 2200 && typeof title === "string" && title.length <= 100, "Proveri dužinu naslova i opisa.");
      const entry = await getEdit(id);
      requireValue(entry?.status === "succeeded" && entry.result?.path, "Sačekaj da se obrada završi.");
      requireValue(Array.isArray(platforms) && platforms.length > 0 && platforms.length <= 3 && platforms.every(platform =>
        typeof platform === "string" && Object.hasOwn(accounts, platform) && accounts[platform] && (platform !== "youtube" || entry.payload.mediaType === "video")),
      "Izaberi povezane kanale koji podržavaju ovaj format.");
      const scheduled = [];
      for (const platform of new Set(platforms)) {
        const job = await jobs.enqueue({ kind: "media_publish", payload: { editId: id, platform, scheduledTime, caption, title },
          requestKey: `media-publish:${id}:${platform}` });
        scheduled.push({ id: job.id, platform, status: job.status, scheduledTime: job.payload.scheduledTime });
      }
      return reply.code(202).send({ scheduled });
    });
  }
  return { register, edit, publish };
}
