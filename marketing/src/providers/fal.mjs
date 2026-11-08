import { fal } from "@fal-ai/client";

const wait = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds));

function falErrorMessage(error, fallback = "fal.ai request failed") {
  const details = Array.isArray(error?.body?.detail) ? error.body.detail : [];
  const detail = details.map((item) => item?.msg ?? item?.message ?? item?.type).filter(Boolean).join("; ");
  return `${detail || error?.body?.message || error?.message || fallback}${error?.status ? ` (${error.status})` : ""}`;
}

async function submitWithTransientRetry(operation, { attempts = 2 } = {}) {
  let lastError;
  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    try {
      return await operation();
    } catch (error) {
      lastError = error;
      const status = Number(error?.status ?? 0);
      const retryable = status === 422 || status === 429 || status >= 500;
      if (!retryable || attempt === attempts) break;
      await wait(750 * attempt);
    }
  }
  const wrapped = new Error(`fal.ai submission failed: ${falErrorMessage(lastError)}`);
  wrapped.status = lastError?.status ?? null;
  wrapped.body = lastError?.body;
  wrapped.cause = lastError;
  // queue.submit/subscribe failed before a provider request ID existed, so a
  // bounded retry cannot duplicate remote media work.
  wrapped.safeToRetry = true;
  throw wrapped;
}

async function downloadAsset(fetchFn, url, label, { attempts = 3 } = {}) {
  let lastError;
  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    try {
      const response = await fetchFn(url);
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      return {
        buffer: Buffer.from(await response.arrayBuffer()),
        mimeType: response.headers.get("content-type")?.split(";")[0] ?? "application/octet-stream",
      };
    } catch (error) {
      lastError = error;
      if (attempt < attempts) await wait(400 * attempt);
    }
  }
  const error = new Error(`${label} download failed after ${attempts} attempts: ${lastError?.message ?? "unknown network error"}`);
  error.safeToRetry = true;
  throw error;
}

export class FalMediaProvider {
  constructor({
    apiKey,
    imageModel,
    imageWidth,
    imageHeight,
    videoModel,
    referenceVideoModel,
    videoResolution,
    client = fal,
    fetchFn = fetch,
  }) {
    this.apiKey = apiKey;
    this.imageModel = imageModel;
    this.imageWidth = imageWidth;
    this.imageHeight = imageHeight;
    this.videoModel = videoModel;
    this.referenceVideoModel = referenceVideoModel ?? videoModel;
    this.videoResolution = videoResolution;
    this.client = client;
    this.fetchFn = fetchFn;
    if (apiKey) this.client.config({ credentials: apiKey });
  }

  ensureConfigured() {
    if (!this.apiKey) throw new Error("fal.ai is not configured");
  }

  async generateBackground(prompt) {
    this.ensureConfigured();
    const fullPrompt = `${prompt}\n\nNON-NEGOTIABLE ART DIRECTION — override any conflicting object request above:
- Create background and subject imagery only; leave clean negative space for a headline overlay.
- No readable text, pseudo-text, letters, numbers, labels, logos, captions, watermarks, or UI.
- No phones, screens, calendars, planners, notebooks, paperwork, signage, clocks, branded footwear, or branded equipment.
- Use plain unbranded clothing and equipment. Replace any text-bearing prop with an abstract blank object.
- Correct adult anatomy and safe exercise form are mandatory.`;
    const input = ["fal-ai/nano-banana-2", "google/nano-banana-2.1"].includes(this.imageModel)
      ? {
          prompt: fullPrompt,
          aspect_ratio: "4:5",
          resolution: "1K",
          num_images: 1,
          limit_generations: true,
          enable_web_search: false,
          output_format: "png",
        }
      : {
          prompt: fullPrompt,
          image_size: { width: this.imageWidth, height: this.imageHeight },
          num_images: 1,
          enable_safety_checker: true,
          output_format: "png",
        };
    const result = await submitWithTransientRetry(() => this.client.subscribe(this.imageModel, {
      input,
      logs: false,
    }));
    const image = result.data?.images?.[0];
    if (!image?.url) throw new Error("fal.ai returned no image URL");
    const downloaded = await downloadAsset(this.fetchFn, image.url, "fal.ai image");
    return {
      buffer: downloaded.buffer,
      mimeType: image.content_type ?? downloaded.mimeType,
      raw: { requestId: result.requestId ?? null, seed: result.data?.seed ?? null },
    };
  }

  async generateReferenceImage(prompt) {
    this.ensureConfigured();
    const fullPrompt = `${prompt}\n\nNON-NEGOTIABLE CAST REFERENCE RULES:
- Follow the requested cast count and composition. Individual identity references contain only their named fictional adult. Preserve natural proportions and realistic hands, face, skin, and clothing.
- Preserve the exact requested location, counter or equipment, meal and physical props in one coherent frame. Do not replace a meal with a can, bottle, appliance, or different object.
- If a phone is required, show only its plain unbranded back or edge. The display must face away from the camera and contain no UI.
- Use plain unbranded clothing and an unbranded environment.
- No text, letters, numbers, labels, logos, watermarks, readable screens, or unrequested extras.
- Photorealistic candid creator footage, not glossy advertising or a posed stock photo.`;
    const input = ["fal-ai/nano-banana-2", "google/nano-banana-2.1"].includes(this.imageModel)
      ? {
          prompt: fullPrompt,
          aspect_ratio: "9:16",
          resolution: "1K",
          num_images: 1,
          limit_generations: true,
          enable_web_search: false,
          output_format: "png",
        }
      : {
          prompt: fullPrompt,
          image_size: { width: 1024, height: 1792 },
          num_images: 1,
          enable_safety_checker: true,
          output_format: "png",
        };
    const result = await submitWithTransientRetry(() => this.client.subscribe(this.imageModel, { input, logs: false }));
    const image = result.data?.images?.[0];
    if (!image?.url) throw new Error("fal.ai returned no casting reference image URL");
    const downloaded = await downloadAsset(this.fetchFn, image.url, "fal.ai casting reference");
    return {
      buffer: downloaded.buffer,
      mimeType: image.content_type ?? downloaded.mimeType,
      raw: { requestId: result.requestId ?? null, seed: result.data?.seed ?? null },
    };
  }

  prepareTask({ prompt, durationSeconds, generateAudio, referenceImageUrls = [] }) {
    const model = referenceImageUrls.length ? this.referenceVideoModel : this.videoModel;
    if (!Number.isFinite(durationSeconds) || durationSeconds <= 0) throw new Error("Video duration must be positive");
    if (model.startsWith("alibaba/wan-3.0/")) {
      if (referenceImageUrls.length > 10) throw new Error("Wan 3.0 supports at most 10 image references");
      const duration = Math.ceil(durationSeconds);
      return { model, durationSeconds: duration, input: {
        prompt: prompt.replace(/<IMAGE_REF_(\d+)>/g, (_, index) => `Image ${Number(index) + 1}`),
        duration, resolution: this.videoResolution, aspect_ratio: "9:16",
        audio: Boolean(generateAudio), enable_prompt_expansion: false, enable_safety_checker: true,
        ...(referenceImageUrls.length ? { reference_image_urls: referenceImageUrls } : {}),
      } };
    }
    if (model.startsWith("bytedance/seedance-2.0/")) {
      if (referenceImageUrls.length > 9) throw new Error("Seedance 2.0 supports at most 9 image references");
      const duration = Math.max(4, Math.ceil(durationSeconds));
      if (duration > 15) throw new Error("Seedance 2.0 clip exceeds 15 seconds; split the scene");
      const boundPrompt = prompt.replace(/<IMAGE_REF_(\d+)>/g, (_, index) => `Image ${Number(index) + 1}`)
        .replace(/\bImage\s+(\d+)\b/g, "@Image$1");
      return { model, durationSeconds: duration, input: {
        prompt: boundPrompt, duration: String(duration), resolution: this.videoResolution,
        aspect_ratio: "9:16", generate_audio: Boolean(generateAudio),
        ...(referenceImageUrls.length ? { image_urls: referenceImageUrls } : {}),
      } };
    }
    if (referenceImageUrls.length > 1 && model.includes("image-to-video")) {
      throw new Error("This image-to-video adapter accepts one start image, not multiple cast references. Use the configured Gemini reference-to-video adapter for multi-character scenes.");
    }
    const isVeo31 = model.includes("veo3.1");
    const isGeminiOmni11 = model.includes("gemini-omni-flash/v1.1");
    const numericDuration = isVeo31
      ? [4, 6, 8].find((value) => value >= durationSeconds)
      : isGeminiOmni11
        ? Math.max(3, Math.min(10, Math.ceil(durationSeconds)))
        : Math.max(4, Math.min(15, durationSeconds));
    const duration = isVeo31 ? `${numericDuration}s` : isGeminiOmni11 ? numericDuration : String(numericDuration);
    if (!numericDuration || numericDuration < durationSeconds) throw new Error("Requested cut exceeds this model's clip duration; split the scene");
    const referenceInput = referenceImageUrls.length
      ? model.includes("image-to-video")
        ? { image_url: referenceImageUrls[0] }
        : { image_urls: referenceImageUrls }
      : {};
    return { model, durationSeconds: numericDuration, input: {
        prompt,
        ...referenceInput,
        duration,
        resolution: this.videoResolution,
        aspect_ratio: "9:16",
        ...(!isGeminiOmni11 ? { generate_audio: generateAudio } : {}),
        ...(isVeo31 ? { auto_fix: true, safety_tolerance: "4" } : {}),
        ...(!isGeminiOmni11 ? { end_user_id: "gymfeed-marketing" } : {}),
      } };
  }

  async createTask(options) {
    this.ensureConfigured();
    const { model, input, durationSeconds } = this.prepareTask(options);
    // A lost submission response does not prove the provider rejected the job.
    // Never automatically repeat a paid request with an unknown outcome.
    const task = await submitWithTransientRetry(() => this.client.queue.submit(model, { input }), { attempts: 1 });
    const requestId = task.request_id ?? task.requestId;
    if (!requestId) throw new Error("fal.ai returned no video request ID");
    return { id: requestId, model, durationSeconds, status: "queued", raw: task };
  }

  async getTask(requestId, model = this.videoModel) {
    this.ensureConfigured();
    const remote = await this.client.queue.status(model, { requestId, logs: false });
    const remoteStatus = String(remote.status ?? "").toUpperCase();
    if (remoteStatus === "IN_QUEUE") return { id: requestId, status: "queued", raw: remote };
    if (remoteStatus === "IN_PROGRESS") return { id: requestId, status: "running", raw: remote };
    if (remoteStatus !== "COMPLETED") {
      return {
        id: requestId,
        status: "failed",
        message: remote.error?.message ?? remote.error ?? `fal.ai task ${remoteStatus || "failed"}`,
        raw: remote,
      };
    }

    let result;
    try {
      result = await this.client.queue.result(model, { requestId });
    } catch (error) {
      const detail = Array.isArray(error?.body?.detail) ? error.body.detail[0] : null;
      const type = detail?.type ?? "provider_result_error";
      const message = detail?.msg ?? error?.message ?? "fal.ai result failed";
      const infrastructureFailure = [
        "generation_timeout",
        "downstream_service_error",
        "downstream_service_unavailable",
        "internal_server_error",
      ].includes(type);
      return {
        id: requestId,
        status: "failed",
        message: `fal.ai ${type}: ${message}${error?.status ? ` (${error.status})` : ""}`,
        error: { type, status: error?.status ?? null, infrastructureFailure },
      };
    }
    const videoUrl = result.data?.video?.url;
    if (!videoUrl) throw new Error("fal.ai completed without a video URL");
    return {
      id: requestId,
      status: "succeeded",
      output: { video_url: videoUrl },
      raw: { status: remote, result: result.data },
    };
  }

  async editTask({ model = "fal-ai/wan/v2.7/edit-video", videoUrl, prompt, resolution = "1080p" }) {
    this.ensureConfigured();
    if (model !== "fal-ai/wan/v2.7/edit-video") throw new Error("Unsupported scene editing adapter");
    const task = await submitWithTransientRetry(() => this.client.queue.submit(model, { input: {
      prompt, video_url: videoUrl, resolution, duration: 0, audio_setting: "origin",
      enable_safety_checker: true,
    } }));
    const id = task.request_id ?? task.requestId;
    if (!id) throw new Error("fal.ai returned no editing request ID");
    return { id, model, status: "queued" };
  }

  async submitMediaEdit(model, input) {
    this.ensureConfigured();
    const task = await this.client.queue.submit(model, { input });
    const requestId = task.request_id ?? task.requestId;
    if (!requestId) throw new Error("fal.ai returned no editing request ID");
    return requestId;
  }

  async mediaEditResult(model, requestId, isVideo) {
    this.ensureConfigured();
    for (let attempt = 0; attempt < 100; attempt += 1) {
      const status = await this.client.queue.status(model, { requestId, logs: false });
      if (status.status === "COMPLETED") {
        const result = await this.client.queue.result(model, { requestId });
        const asset = isVideo ? result.data?.video : result.data?.images?.[0];
        if (!asset?.url) throw new Error("fal.ai did not return an edited file");
        return (await downloadAsset(this.fetchFn, asset.url, "fal.ai edited media")).buffer;
      }
      if (!["IN_QUEUE", "IN_PROGRESS"].includes(status.status)) throw new Error("fal.ai editing failed: " + status.status);
      await wait(6000);
    }
    throw Object.assign(new Error("fal.ai editing status timed out. The saved request can be checked again."), { safeToRetry: true });
  }

  async createLipSyncTask({videoUrl,audioUrl,model="fal-ai/sync-lipsync/v2"}) {
    this.ensureConfigured();
    if(model!=="fal-ai/sync-lipsync/v2")throw Error("Unsupported locked-speech lip-sync model");
    const result=await submitWithTransientRetry(()=>this.client.queue.submit(model,{input:{video_url:videoUrl,audio_url:audioUrl,
      model:"lipsync-2",sync_mode:"silence",enable_safety_checker:true}}),{attempts:1});
    const id=result.request_id??result.requestId;
    if(!id)throw Error("fal.ai returned no lip-sync request ID");
    return {id,model,status:"queued"};
  }
}
