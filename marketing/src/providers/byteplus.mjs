async function responseJson(response, label) {
  const text = await response.text();
  let body;
  try {
    body = text ? JSON.parse(text) : {};
  } catch (_) {
    body = { raw: text };
  }
  if (!response.ok) {
    throw new Error(`${label} failed (${response.status}): ${body?.error?.message ?? body?.message ?? text}`);
  }
  return body;
}

export class BytePlusVideoProvider {
  constructor({ apiKey, baseUrl, model, resolution, watermark }) {
    this.apiKey = apiKey;
    this.baseUrl = baseUrl.replace(/\/$/, "");
    this.model = model;
    this.resolution = resolution;
    this.watermark = watermark;
  }

  headers() {
    if (!this.apiKey) throw new Error("BytePlus is not configured");
    return {
      authorization: `Bearer ${this.apiKey}`,
      "content-type": "application/json",
      accept: "application/json",
    };
  }

  async createTask({ prompt, durationSeconds, generateAudio }) {
    const response = await fetch(`${this.baseUrl}/contents/generations/tasks`, {
      method: "POST",
      headers: this.headers(),
      body: JSON.stringify({
        model: this.model,
        content: [{ type: "text", text: prompt }],
        generate_audio: generateAudio,
        ratio: "9:16",
        duration: Math.max(4, Math.min(15, durationSeconds)),
        resolution: this.resolution,
        watermark: this.watermark,
        return_last_frame: true,
      }),
    });
    return responseJson(response, "BytePlus task creation");
  }

  async getTask(taskId) {
    const response = await fetch(`${this.baseUrl}/contents/generations/tasks/${encodeURIComponent(taskId)}`, {
      headers: this.headers(),
    });
    return responseJson(response, "BytePlus task lookup");
  }
}

