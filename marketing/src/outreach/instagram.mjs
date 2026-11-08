import { createHmac, timingSafeEqual } from "node:crypto";

// Meta signs webhook bodies with the app secret; reject anything that does not match.
export function verifyWebhookSignature(rawBody, header, appSecret) {
  if (!rawBody || !header || !appSecret) return false;
  const expected = `sha256=${createHmac("sha256", appSecret).update(rawBody).digest("hex")}`;
  const supplied = Buffer.from(String(header));
  const wanted = Buffer.from(expected);
  return supplied.length === wanted.length && timingSafeEqual(supplied, wanted);
}

// Flattens an Instagram messaging webhook into the events the outreach flow cares about.
export function parseWebhookEvents(payload) {
  if (payload?.object !== "instagram") return [];
  const events = [];
  for (const entry of payload.entry ?? []) {
    for (const item of entry.messaging ?? []) {
      const base = {
        accountId: String(entry.id ?? ""),
        senderId: String(item.sender?.id ?? ""),
        recipientId: String(item.recipient?.id ?? ""),
        timestamp: Number(item.timestamp ?? entry.time ?? Date.now()),
      };
      if (item.message?.is_echo) {
        events.push({ ...base, type: "echo", mid: item.message.mid, text: item.message.text ?? "" });
      } else if (item.message && !item.message.is_deleted) {
        const attachments = (item.message.attachments ?? []).map((attachment) => attachment.type).filter(Boolean);
        events.push({
          ...base,
          type: "message",
          mid: item.message.mid,
          text: item.message.text ?? (attachments.length ? `[sent ${attachments.join(", ")}]` : ""),
        });
      } else if (item.reaction) {
        events.push({ ...base, type: "reaction", mid: item.reaction.mid, reaction: item.reaction.emoji ?? item.reaction.reaction });
      } else if (item.read) {
        events.push({ ...base, type: "read", mid: item.read.mid });
      }
    }
  }
  return events;
}

export class InstagramClient {
  constructor({ version = "v23.0", businessAccountId, graphAccessToken, messagingAccessToken, fetchImpl = fetch } = {}) {
    this.version = version;
    this.businessAccountId = businessAccountId;
    this.graphAccessToken = graphAccessToken;
    this.messagingAccessToken = messagingAccessToken;
    this.fetchImpl = fetchImpl;
  }

  get discoveryConfigured() {
    return Boolean(this.businessAccountId && this.graphAccessToken);
  }

  get messagingConfigured() {
    return Boolean(this.messagingAccessToken);
  }

  async call(url, { method = "GET", token, body } = {}) {
    const response = await this.fetchImpl(url, {
      method,
      headers: { authorization: `Bearer ${token}`, ...(body ? { "content-type": "application/json" } : {}) },
      ...(body ? { body: JSON.stringify(body) } : {}),
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok || payload.error) {
      const error = new Error(`Instagram ${method} ${new URL(url).pathname}: ${payload.error?.message ?? response.status}`);
      error.code = payload.error?.code;
      throw error;
    }
    return payload;
  }

  // Public stats for another professional (business/creator) account. Personal accounts return null.
  async businessDiscovery(username) {
    if (!this.discoveryConfigured) return null;
    const fields = `business_discovery.username(${username}){username,name,biography,website,followers_count,media_count,`
      + "media.limit(12){caption,like_count,comments_count,timestamp,permalink}}";
    try {
      const payload = await this.call(
        `https://graph.facebook.com/${this.version}/${this.businessAccountId}?fields=${encodeURIComponent(fields)}`,
        { token: this.graphAccessToken },
      );
      return summarizeDiscovery(payload.business_discovery);
    } catch (error) {
      if (error.code === 110 || error.code === 100) return null;
      throw error;
    }
  }

  async sendText(recipientId, text) {
    return this.call(`https://graph.instagram.com/${this.version}/me/messages`, {
      method: "POST",
      token: this.messagingAccessToken,
      body: { recipient: { id: recipientId }, message: { text } },
    });
  }

  async userProfile(userId) {
    return this.call(`https://graph.instagram.com/${this.version}/${userId}?fields=username,name`, { token: this.messagingAccessToken });
  }

  // Oldest-first conversation history with one user, as [{ from: "creator"|"gymfeed", text, at }].
  async conversation(userId, ownUsername) {
    const fields = encodeURIComponent("messages.limit(30){message,from,created_time}");
    const payload = await this.call(
      `https://graph.instagram.com/${this.version}/me/conversations?platform=instagram&user_id=${userId}&fields=${fields}`,
      { token: this.messagingAccessToken },
    );
    const messages = payload.data?.[0]?.messages?.data ?? [];
    return messages
      .map((message) => ({
        from: String(message.from?.username ?? "").toLowerCase() === ownUsername.toLowerCase() ? "gymfeed" : "creator",
        text: message.message ?? "",
        at: message.created_time,
      }))
      .filter((message) => message.text)
      .reverse();
  }
}

export function summarizeDiscovery(account) {
  if (!account) return null;
  const media = account.media?.data ?? [];
  const followers = Number(account.followers_count ?? 0);
  const interactions = media.map((item) => Number(item.like_count ?? 0) + Number(item.comments_count ?? 0));
  const average = interactions.length ? interactions.reduce((sum, value) => sum + value, 0) / interactions.length : 0;
  const email = String(account.biography ?? "").match(/[\w.+-]+@[\w-]+\.[\w.-]+/)?.[0] ?? null;
  return {
    username: account.username,
    name: account.name ?? null,
    biography: account.biography ?? "",
    website: account.website ?? null,
    followers,
    media_count: account.media_count ?? null,
    engagement_rate: followers ? Number((average / followers * 100).toFixed(2)) : null,
    email,
    recent_captions: media.slice(0, 6).map((item) => String(item.caption ?? "").slice(0, 200)),
    last_post_at: media[0]?.timestamp ?? null,
  };
}
