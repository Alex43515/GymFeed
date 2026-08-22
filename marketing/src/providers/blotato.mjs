async function responseJson(response, label) {
  const text = await response.text();
  let body;
  try {
    body = text ? JSON.parse(text) : {};
  } catch (_) {
    body = { raw: text };
  }
  if (!response.ok) {
    throw new Error(`${label} failed (${response.status}): ${body?.message ?? text}`);
  }
  return body;
}

export class BlotatoPublisher {
  constructor({ apiKey, baseUrl }) {
    this.apiKey = apiKey;
    this.baseUrl = baseUrl.replace(/\/$/, "");
  }

  headers() {
    if (!this.apiKey) throw new Error("Blotato is not configured");
    return {
      "blotato-api-key": this.apiKey,
      "content-type": "application/json",
      accept: "application/json",
    };
  }

  async listAccounts(platform) {
    const suffix = platform ? `?platform=${encodeURIComponent(platform)}` : "";
    const response = await fetch(`${this.baseUrl}/users/me/accounts${suffix}`, {
      headers: this.headers(),
    });
    return responseJson(response, "Blotato account lookup");
  }

  async ingestMedia(url) {
    const response = await fetch(`${this.baseUrl}/media`, {
      method: "POST",
      headers: this.headers(),
      body: JSON.stringify({ url }),
    });
    const body = await responseJson(response, "Blotato media ingest");
    if (!body.url) throw new Error("Blotato media ingest returned no URL");
    return body.url;
  }

  async ingestMediaUrls(urls) {
    const result = [];
    for (const url of urls) result.push(await this.ingestMedia(url));
    return result;
  }

  async publish({ platform, accountId, text, mediaUrls, scheduledTime, title, isVideo = false }) {
    const target = { targetType: platform };
    if (platform === "instagram" && isVideo) {
      target.mediaType = "reel";
    }
    if (platform === "tiktok") {
      Object.assign(target, {
        privacyLevel: "PUBLIC_TO_EVERYONE",
        disabledComments: false,
        disabledDuet: false,
        disabledStitch: false,
        isBrandedContent: false,
        isYourBrand: true,
        isAiGenerated: true,
      });
    }
    if (platform === "youtube") {
      Object.assign(target, {
        title: title?.slice(0, 100) || "GymFeed Short",
        privacyStatus: "public",
        shouldNotifySubscribers: true,
        isMadeForKids: false,
      });
    }

    const payload = {
      post: {
        accountId,
        content: { text, mediaUrls, platform },
        target,
      },
    };
    if (scheduledTime) payload.scheduledTime = scheduledTime;

    const response = await fetch(`${this.baseUrl}/posts`, {
      method: "POST",
      headers: this.headers(),
      body: JSON.stringify(payload),
    });
    return responseJson(response, `Blotato ${platform} publish`);
  }

  async getPost(postSubmissionId) {
    const response = await fetch(`${this.baseUrl}/posts/${encodeURIComponent(postSubmissionId)}`, {
      headers: this.headers(),
    });
    return responseJson(response, "Blotato post lookup");
  }
}
