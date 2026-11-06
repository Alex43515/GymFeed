import { BOT_OWNER, dmLink, normalizeHandle, rowHandles } from "./sheet.mjs";
import { parseWebhookEvents } from "./instagram.mjs";
import { SEARCH_ANGLES } from "./offer.mjs";

const CLOSED_STATUSES = new Set(["Accepted", "Handed off", "Declined", "Skip"]);

function weekOf(date = new Date()) {
  const monday = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  monday.setUTCDate(monday.getUTCDate() - ((monday.getUTCDay() + 6) % 7));
  return monday.toISOString().slice(0, 10);
}

function profileUrl(platform, handle) {
  return platform === "instagram" ? `https://www.instagram.com/${handle}/` : `https://www.tiktok.com/@${handle}`;
}

function activity(text, at = new Date()) {
  return `${at.toISOString().slice(0, 16).replace("T", " ")} UTC — ${text}`;
}

export class OutreachService {
  constructor({ config, sheet, instagram, ai, fetchImpl = fetch, logger = console, now = () => new Date() }) {
    this.config = config;
    this.sheet = sheet;
    this.instagram = instagram;
    this.ai = ai;
    this.fetchImpl = fetchImpl;
    this.logger = logger;
    this.now = now;
    this.queues = new Map();
  }

  async runWeekly({ target = this.config.OUTREACH_WEEKLY_TARGET } = {}) {
    if (!this.config.OUTREACH_ENABLED) return { action: "outreach_disabled" };
    await this.sheet.ensureSheet();
    const known = new Set((await this.sheet.readRecords()).flatMap(({ record }) => rowHandles(record)));
    const min = this.config.OUTREACH_MIN_FOLLOWERS;
    const max = this.config.OUTREACH_MAX_FOLLOWERS;
    const skipped = { duplicate: 0, size: 0, low_fit: 0 };
    const candidates = [];
    const notes = [];
    // Qualification rejects thin profiles, so gather about twice the target across several search angles.
    const wanted = Math.max(target * 2, 6);
    for (const angle of SEARCH_ANGLES) {
      if (candidates.length >= wanted) break;
      const found = await this.ai.discover({ count: Math.min(10, wanted - candidates.length + 2), exclude: [...known], minFollowers: min, maxFollowers: max, angle });
      if (found.search_notes) notes.push(found.search_notes);
      for (const candidate of found.candidates) {
        const handles = [candidate.handle, ...candidate.other_profiles.map((profile) => profile.handle)].map(normalizeHandle).filter(Boolean);
        if (!handles.length || handles.some((handle) => known.has(handle))) {
          skipped.duplicate += 1;
          continue;
        }
        handles.forEach((handle) => known.add(handle));
        candidates.push(candidate);
      }
    }

    const enriched = [];
    for (const candidate of candidates) {
      const instagramHandle = normalizeHandle(candidate.platform === "instagram"
        ? candidate.handle
        : candidate.other_profiles.find((profile) => profile.platform === "instagram")?.handle);
      const instagram = instagramHandle
        ? await this.instagram.businessDiscovery(instagramHandle).catch((error) => {
          this.logger.warn?.({ err: error, handle: instagramHandle }, "Instagram business discovery failed");
          return null;
        })
        : null;
      const followers = instagram?.followers ?? candidate.followers_estimate;
      if (followers != null && (followers < min || followers > max)) {
        skipped.size += 1;
        continue;
      }
      enriched.push({ ...candidate, handle: normalizeHandle(candidate.handle), instagram_handle: instagramHandle || null, instagram, followers });
    }

    const verdicts = new Map((enriched.length ? await this.ai.qualify(enriched) : [])
      .map((verdict) => [normalizeHandle(verdict.handle), verdict]));
    const rejected = [];
    const selected = enriched
      .map((creator) => ({ creator, verdict: verdicts.get(creator.handle) }))
      .filter(({ creator, verdict }) => {
        const keep = verdict && !verdict.reject_reason && verdict.fit_score >= this.config.OUTREACH_MIN_FIT_SCORE;
        if (!keep) {
          skipped.low_fit += 1;
          rejected.push({ handle: creator.handle, fit_score: verdict?.fit_score ?? null, reason: verdict?.reject_reason || verdict?.why_fit || "not qualified" });
        }
        return keep;
      })
      .sort((left, right) => right.verdict.fit_score - left.verdict.fit_score)
      .slice(0, target);

    const week = weekOf(this.now());
    const records = selected.map(({ creator, verdict }) => this.newRecord(creator, verdict, week));
    await this.sheet.appendRecords(records);
    return { action: "outreach_week_planned", week, added: records.length, found: candidates.length, skipped, rejected, search_notes: notes.join("\n") };
  }

  newRecord(creator, verdict, week) {
    const platform = creator.instagram_handle ? "instagram" : "tiktok";
    const handle = creator.instagram_handle ?? creator.handle;
    const others = [
      ...(creator.platform !== platform ? [{ platform: creator.platform, handle: creator.handle }] : []),
      ...creator.other_profiles.filter((profile) => profile.platform !== platform),
    ];
    return {
      Reached: false,
      Reacted: false,
      "Messaged back": false,
      Accepted: false,
      Owner: BOT_OWNER,
      Creator: creator.instagram?.name || creator.name,
      Platform: platform,
      Handle: handle,
      "Open DM": dmLink(platform, handle),
      "Profile URL": profileUrl(platform, handle),
      "Other profiles": [...new Map(others.map((profile) => [`${profile.platform}:${normalizeHandle(profile.handle)}`, profile])).keys()].join(", "),
      Email: creator.instagram?.email ?? creator.email ?? "",
      Followers: creator.followers ?? "",
      "Engagement %": creator.instagram?.engagement_rate ?? "",
      Market: creator.market,
      Language: creator.language,
      "Fit score": verdict.fit_score,
      Tier: verdict.tier,
      "Why they fit": verdict.why_fit,
      "First message": verdict.first_message,
      Status: "To contact",
      Week: week,
      "Creator ID": `${platform}:${handle}`,
      "Updated at": this.now().toISOString(),
    };
  }

  // Meta needs a fast 200, so the route acknowledges first and calls this in the background.
  async handleInstagramWebhook(payload) {
    const events = parseWebhookEvents(payload);
    await Promise.all(events.map((event) => {
      const creatorId = event.type === "echo" ? event.recipientId : event.senderId;
      if (!creatorId || (event.type !== "echo" && creatorId === event.accountId)) return null;
      return this.serialized(creatorId, () => this.handleEvent(event, creatorId));
    }));
    return { handled: events.length };
  }

  serialized(key, task) {
    const previous = this.queues.get(key) ?? Promise.resolve();
    const next = previous.then(task, task).catch((error) => this.logger.error?.({ err: error, creator: key }, "Outreach event failed"));
    this.queues.set(key, next);
    next.finally(() => { if (this.queues.get(key) === next) this.queues.delete(key); });
    return next;
  }

  async findRow(userId) {
    const rows = await this.sheet.readRecords();
    const byId = rows.find(({ record }) => String(record["Instagram user ID"]) === userId);
    if (byId) return byId;
    if (!this.instagram.messagingConfigured) return null;
    const profile = await this.instagram.userProfile(userId).catch(() => null);
    const username = normalizeHandle(profile?.username);
    if (!username) return null;
    const match = rows.find(({ record }) => rowHandles(record).includes(username));
    if (match) {
      match.record["Instagram user ID"] = userId;
      await this.sheet.updateRecord(match.rowNumber, { "Instagram user ID": userId });
    }
    return match ?? null;
  }

  async handleEvent(event, userId) {
    // DMs from people who are not in the outreach list are never answered by the bot.
    const row = await this.findRow(userId);
    if (!row) return { action: "ignored_unknown_sender" };
    const { rowNumber, record } = row;
    const at = new Date(event.timestamp || this.now());

    if (event.type === "echo") {
      if (record.Reached) return { action: "already_reached" };
      return this.sheet.updateRecord(rowNumber, {
        Reached: true,
        ...(["", "To contact"].includes(record.Status) ? { Status: "Contacted" } : {}),
        "Last activity": activity("First message sent", at),
      });
    }
    if (event.type === "read") return this.sheet.updateRecord(rowNumber, { "Last activity": activity("Seen our message", at) });
    if (event.type === "reaction") {
      return this.sheet.updateRecord(rowNumber, { Reacted: true, "Last activity": activity(`Reacted ${event.reaction ?? ""}`.trim(), at) });
    }
    return this.handleCreatorMessage(event, userId, rowNumber, record, at);
  }

  async handleCreatorMessage(event, userId, rowNumber, record, at) {
    const seen = {
      Reached: true,
      Reacted: true,
      "Messaged back": true,
      ...(!CLOSED_STATUSES.has(record.Status) ? { Status: "In conversation" } : {}),
    };
    if (record.Owner !== BOT_OWNER) {
      return this.sheet.updateRecord(rowNumber, { ...seen, "Last activity": activity(`New message for ${record.Owner}: ${event.text.slice(0, 200)}`, at) });
    }
    if (event.mid && event.mid === record["Last handled message ID"]) return { action: "duplicate_message" };

    let conversation = await this.instagram.conversation(userId, this.config.OUTREACH_ACCOUNT_USERNAME).catch((error) => {
      this.logger.warn?.({ err: error }, "Could not load Instagram conversation; using the sheet context");
      return null;
    });
    if (!conversation?.length) conversation = record["First message"] ? [{ from: "gymfeed", text: record["First message"] }] : [];
    if (conversation.at(-1)?.text !== event.text) conversation.push({ from: "creator", text: event.text });

    const creator = Object.fromEntries(["Creator", "Handle", "Platform", "Followers", "Market", "Language", "Tier", "Why they fit", "Conversation summary", "Notes"]
      .map((key) => [key, record[key]]));
    const decision = await this.ai.reply({ creator, conversation });

    const changes = {
      ...seen,
      "Last handled message ID": event.mid ?? "",
      "Conversation summary": decision.summary,
      "Last activity": activity(`Creator: ${event.text.slice(0, 200)}`, at),
      "Suggested reply": "",
    };
    if (decision.collected_email && !record.Email) changes.Email = decision.collected_email;
    if (decision.stage === "declined") changes.Status = "Declined";
    if (decision.accepted) Object.assign(changes, { Accepted: true, Status: "Accepted" });
    if (decision.handoff) {
      Object.assign(changes, {
        Owner: this.config.OUTREACH_OWNER_NAME,
        ...(decision.accepted ? {} : { Status: "Handed off" }),
        "Next step for you": decision.next_step_for_owner ?? decision.handoff_reason ?? "Take over the conversation",
      });
    }

    let sent = false;
    if (decision.should_send && decision.reply.trim()) {
      if (this.config.OUTREACH_AUTO_REPLY && this.instagram.messagingConfigured) {
        await this.instagram.sendText(userId, decision.reply.trim());
        sent = true;
      } else {
        changes["Suggested reply"] = decision.reply.trim();
      }
    }
    await this.sheet.updateRecord(rowNumber, changes);
    if (decision.handoff) await this.notifyHandoff(record, decision);
    return { action: decision.handoff ? "handed_off" : "replied", sent, stage: decision.stage };
  }

  async notifyHandoff(record, decision) {
    if (!this.config.OUTREACH_HANDOFF_WEBHOOK_URL) return;
    try {
      await this.fetchImpl(this.config.OUTREACH_HANDOFF_WEBHOOK_URL, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          creator: record.Creator,
          handle: record.Handle,
          dm: record["Open DM"],
          accepted: decision.accepted,
          reason: decision.handoff_reason,
          next_step: decision.next_step_for_owner,
          summary: decision.summary,
        }),
      });
    } catch (error) {
      this.logger.warn?.({ err: error }, "Outreach handoff notification failed");
    }
  }
}
