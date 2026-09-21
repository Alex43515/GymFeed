import { fal } from "@fal-ai/client";

async function downloadAsset(fetchFn, url, label) {
  const response = await fetchFn(url);
  if (!response.ok) throw new Error(`${label} download failed (${response.status})`);
  return {
    buffer: Buffer.from(await response.arrayBuffer()),
    mimeType: response.headers.get("content-type")?.split(";")[0] ?? "application/octet-stream",
  };
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
    const input = this.imageModel === "fal-ai/nano-banana-2"
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
    const result = await this.client.subscribe(this.imageModel, {
      input,
      logs: false,
    });
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
    const fullPrompt = `${prompt}\n\nNON-NEGOTIABLE VEO START-FRAME RULES:
- Show exactly one fictional adult in the requested production composition, with natural proportions and realistic hands, face, skin, and clothing.
- Preserve the exact requested location, counter or equipment, meal and physical props in one coherent frame. Do not replace a meal with a can, bottle, appliance, or different object.
- If a phone is required, show only its plain unbranded back or edge. The display must face away from the camera and contain no UI.
- Use plain unbranded clothing and an unbranded environment.
- No text, letters, numbers, labels, logos, watermarks, readable screens, or additional people.
- Photorealistic candid creator footage, not glossy advertising or a posed stock photo.`;
    const input = this.imageModel === "fal-ai/nano-banana-2"
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
    const result = await this.client.subscribe(this.imageModel, { input, logs: false });
    const image = result.data?.images?.[0];
    if (!image?.url) throw new Error("fal.ai returned no casting reference image URL");
    const downloaded = await downloadAsset(this.fetchFn, image.url, "fal.ai casting reference");
    return {
      buffer: downloaded.buffer,
      mimeType: image.content_type ?? downloaded.mimeType,
      raw: { requestId: result.requestId ?? null, seed: result.data?.seed ?? null },
    };
  }

  async createTask({ prompt, durationSeconds, generateAudio, referenceImageUrls = [] }) {
    this.ensureConfigured();
    const model = referenceImageUrls.length ? this.referenceVideoModel : this.videoModel;
    const isVeo31 = model.includes("veo3.1");
    const isGeminiOmni11 = model.includes("gemini-omni-flash/v1.1");
    const numericDuration = isVeo31
      ? [4, 6, 8].reduce((best, value) => Math.abs(value - durationSeconds) < Math.abs(best - durationSeconds) ? value : best, 8)
      : isGeminiOmni11
        ? Math.max(3, Math.min(10, Math.round(durationSeconds)))
        : Math.max(4, Math.min(15, durationSeconds));
    const duration = isVeo31 ? `${numericDuration}s` : isGeminiOmni11 ? numericDuration : String(numericDuration);
    const referenceInput = referenceImageUrls.length
      ? model.includes("image-to-video")
        ? { image_url: referenceImageUrls[0] }
        : { image_urls: referenceImageUrls }
      : {};
    const task = await this.client.queue.submit(model, {
      input: {
        prompt,
        ...referenceInput,
        duration,
        resolution: this.videoResolution,
        aspect_ratio: "9:16",
        ...(!isGeminiOmni11 ? { generate_audio: generateAudio } : {}),
        ...(isVeo31 ? { auto_fix: true, safety_tolerance: "4" } : {}),
        ...(!isGeminiOmni11 ? { end_user_id: "gymfeed-marketing" } : {}),
      },
    });
    const requestId = task.request_id ?? task.requestId;
    if (!requestId) throw new Error("fal.ai returned no video request ID");
    return { id: requestId, model, status: "queued", raw: task };
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

    const result = await this.client.queue.result(model, { requestId });
    const videoUrl = result.data?.video?.url;
    if (!videoUrl) throw new Error("fal.ai completed without a video URL");
    return {
      id: requestId,
      status: "succeeded",
      output: { video_url: videoUrl },
      raw: { status: remote, result: result.data },
    };
  }
}
