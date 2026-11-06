import test from "node:test";
import assert from "node:assert/strict";
import { createHmac } from "node:crypto";
import Fastify from "fastify";
import { loadOutreachConfig } from "../src/outreach/config.mjs";
import { BOT_OWNER, OUTREACH_HEADERS, OutreachSheet, columnLetter, dmLink, normalizeHandle, recordToRow, rowHandles, rowToRecord } from "../src/outreach/sheet.mjs";
import { parseWebhookEvents, summarizeDiscovery, verifyWebhookSignature } from "../src/outreach/instagram.mjs";
import { OutreachService } from "../src/outreach/service.mjs";
import { registerOutreachRoutes } from "../src/outreach/index.mjs";

const config = loadOutreachConfig({
  OUTREACH_ENABLED: "true",
  OUTREACH_AUTO_REPLY: "true",
  OUTREACH_OWNER_NAME: "Aleks",
  INSTAGRAM_APP_SECRET: "app-secret",
  INSTAGRAM_WEBHOOK_VERIFY_TOKEN: "verify-me",
});

function fakeSheet(records = []) {
  const rows = records.map((record, index) => ({ rowNumber: index + 2, record: rowToRecord(recordToRow(record)) }));
  return {
    rows,
    appended: [],
    updates: [],
    async ensureSheet() {},
    async readRecords() { return structuredClone(rows); },
    async appendRecords(values) { this.appended.push(...values); },
    async updateRecord(rowNumber, changes) {
      this.updates.push({ rowNumber, changes });
      Object.assign(rows.find((row) => row.rowNumber === rowNumber).record, changes);
    },
  };
}

function fakeInstagram({ profiles = {}, discovery = {}, conversation = null } = {}) {
  return {
    sent: [],
    messagingConfigured: true,
    async userProfile(id) { return profiles[id] ?? null; },
    async businessDiscovery(username) { return discovery[username] ?? null; },
    async conversation() { return conversation; },
    async sendText(id, text) { this.sent.push({ id, text }); },
  };
}

function creatorRow(overrides = {}) {
  return {
    Owner: BOT_OWNER, Creator: "Mia Lifts", Platform: "instagram", Handle: "mia.lifts", Status: "Contacted",
    "First message": "Hey Mia, loved your squat breakdown! — GymFeed team", Reached: true, ...overrides,
  };
}

function messagePayload({ sender = "9001", text = "Sounds interesting, tell me more", mid = "m1", echo = false } = {}) {
  return {
    object: "instagram",
    entry: [{ id: "1000", time: 1, messaging: [{
      sender: { id: echo ? "1000" : sender }, recipient: { id: echo ? sender : "1000" }, timestamp: 1760000000000,
      message: { mid, text, ...(echo ? { is_echo: true } : {}) },
    }] }],
  };
}

function decision(overrides = {}) {
  return {
    reply: "Great to hear! We are building an exercise library — would you film a few moves? — GymFeed team",
    should_send: true, stage: "interested", accepted: false, handoff: false, handoff_reason: null,
    summary: "Mia is interested.", next_step_for_owner: null, collected_email: null, ...overrides,
  };
}

test("handles normalize from URLs and @mentions and rows expose every known handle", () => {
  assert.equal(normalizeHandle("https://www.tiktok.com/@AnjaBlaa?lang=en-GB"), "anjablaa");
  assert.equal(normalizeHandle("https://www.instagram.com/mia.lifts/"), "mia.lifts");
  assert.equal(normalizeHandle("@Mia.Lifts"), "mia.lifts");
  assert.deepEqual(rowHandles({ Handle: "mia.lifts", "Other profiles": "tiktok:mia_tt, tiktok:@MiaTwo" }), ["mia.lifts", "mia_tt", "miatwo"]);
  assert.equal(dmLink("instagram", "@mia.lifts"), "https://ig.me/m/mia.lifts");
  assert.equal(columnLetter(0), "A");
  assert.equal(columnLetter(26), "AA");
  assert.equal(OUTREACH_HEADERS.slice(0, 4).join("|"), "Reached|Reacted|Messaged back|Accepted");
});

test("sheet appends directly below the last creator instead of after empty checkbox rows", async () => {
  const calls = [];
  const sheet = new OutreachSheet({
    spreadsheetId: "s",
    auth: { getClient: async () => ({ getRequestHeaders: async () => ({}) }) },
    fetchImpl: async (url, init = {}) => {
      calls.push({ url: decodeURIComponent(url), method: init.method ?? "GET", body: init.body ? JSON.parse(init.body) : null });
      if (url.includes("fields=sheets.properties")) {
        return { ok: true, json: async () => ({ sheets: [{ properties: { title: "Influencer Outreach", sheetId: 7, gridProperties: { rowCount: 3 } } }] }) };
      }
      if (url.includes("UNFORMATTED_VALUE")) {
        return { ok: true, json: async () => ({ values: [recordToRow(creatorRow()), recordToRow(creatorRow({ Handle: "two" }))] }) };
      }
      return { ok: true, json: async () => ({}) };
    },
  });
  await sheet.appendRecords([creatorRow({ Handle: "three" }), creatorRow({ Handle: "four" })]);
  const [batch] = calls.filter((call) => call.url.endsWith(":batchUpdate"));
  assert.deepEqual(batch.body.requests[0], { appendDimension: { sheetId: 7, dimension: "ROWS", length: 2 } });
  assert.equal(batch.body.requests[1].setDataValidation.range.startRowIndex, 3);
  const write = calls.find((call) => call.method === "PUT");
  assert.match(write.url, /'Influencer Outreach'!A4:[A-Z]+5\?/);
});

test("webhook signatures must match the app secret", () => {
  const body = Buffer.from(JSON.stringify(messagePayload()));
  const signature = `sha256=${createHmac("sha256", "app-secret").update(body).digest("hex")}`;
  assert.equal(verifyWebhookSignature(body, signature, "app-secret"), true);
  assert.equal(verifyWebhookSignature(body, signature, "other"), false);
  assert.equal(verifyWebhookSignature(body, undefined, "app-secret"), false);
});

test("webhook events are flattened into message, echo, reaction and read", () => {
  const payload = {
    object: "instagram",
    entry: [{ id: "1000", messaging: [
      { sender: { id: "9001" }, recipient: { id: "1000" }, message: { mid: "a", text: "hi" } },
      { sender: { id: "1000" }, recipient: { id: "9001" }, message: { mid: "b", text: "hey", is_echo: true } },
      { sender: { id: "9001" }, recipient: { id: "1000" }, reaction: { mid: "b", emoji: "🔥" } },
      { sender: { id: "9001" }, recipient: { id: "1000" }, read: { mid: "b" } },
    ] }],
  };
  assert.deepEqual(parseWebhookEvents(payload).map((event) => event.type), ["message", "echo", "reaction", "read"]);
  assert.deepEqual(parseWebhookEvents({ object: "page" }), []);
});

test("business discovery is summarised into followers, engagement and bio email", () => {
  const summary = summarizeDiscovery({
    username: "mia.lifts", followers_count: 20000, biography: "Coach | collabs: mia@lifts.com",
    media: { data: [{ like_count: 900, comments_count: 100 }, { like_count: 500, comments_count: 100 }] },
  });
  assert.equal(summary.engagement_rate, 4);
  assert.equal(summary.email, "mia@lifts.com");
});

test("weekly run dedupes, filters by size and fit, and writes Instagram-first rows", async () => {
  const sheet = fakeSheet([creatorRow({ Handle: "existing" })]);
  const instagram = fakeInstagram({ discovery: { "mia.lifts": { name: "Mia", followers: 20000, engagement_rate: 4.1, email: "mia@lifts.com" } } });
  const ai = {
    async discover({ exclude, angle }) {
      assert.ok(exclude.includes("existing"));
      assert.ok(angle);
      if (exclude.includes("mia_tt")) return { search_notes: "", candidates: [] };
      return {
        search_notes: "ok",
        candidates: [
          { name: "Dup", platform: "instagram", handle: "Existing", profile_url: "", other_profiles: [], email: null, followers_estimate: 10000, market: "international", language: "en", content_summary: "", evidence_urls: [] },
          { name: "Mia", platform: "tiktok", handle: "mia_tt", profile_url: "", other_profiles: [{ platform: "instagram", handle: "@mia.lifts" }], email: null, followers_estimate: 50000, market: "balkan", language: "sr", content_summary: "", evidence_urls: [] },
          { name: "Huge", platform: "instagram", handle: "huge", profile_url: "", other_profiles: [], email: null, followers_estimate: 2000000, market: "international", language: "en", content_summary: "", evidence_urls: [] },
          { name: "Weak", platform: "tiktok", handle: "weak", profile_url: "", other_profiles: [], email: null, followers_estimate: 8000, market: "international", language: "en", content_summary: "", evidence_urls: [] },
        ],
      };
    },
    async qualify(creators) {
      assert.deepEqual(creators.map((creator) => creator.handle), ["mia_tt", "weak"]);
      return [
        { handle: "mia_tt", fit_score: 88, tier: "partner", reject_reason: null, why_fit: "Great form videos", first_message: "Hey Mia!" },
        { handle: "weak", fit_score: 40, tier: "starter", reject_reason: null, why_fit: "", first_message: "" },
      ];
    },
  };
  const service = new OutreachService({ config, sheet, instagram, ai, now: () => new Date("2026-10-08T10:00:00Z") });
  const result = await service.runWeekly({ target: 10 });
  assert.equal(result.added, 1);
  assert.deepEqual(result.skipped, { duplicate: 1, size: 1, low_fit: 1 });
  assert.deepEqual(result.rejected.map((item) => item.handle), ["weak"]);
  const [row] = sheet.appended;
  assert.equal(row.Platform, "instagram");
  assert.equal(row.Handle, "mia.lifts");
  assert.equal(row["Open DM"], "https://ig.me/m/mia.lifts");
  assert.equal(row["Other profiles"], "tiktok:mia_tt");
  assert.equal(row.Followers, 20000);
  assert.equal(row.Email, "mia@lifts.com");
  assert.equal(row.Week, "2026-10-05");
  assert.equal(row.Owner, BOT_OWNER);
  assert.equal(row.Reached, false);
});

test("weekly run does nothing while outreach is disabled", async () => {
  const service = new OutreachService({ config: { ...config, OUTREACH_ENABLED: false }, sheet: fakeSheet(), instagram: fakeInstagram(), ai: {} });
  assert.deepEqual(await service.runWeekly(), { action: "outreach_disabled" });
});

test("our manually sent first DM marks the creator as reached", async () => {
  const sheet = fakeSheet([creatorRow({ Reached: false, Status: "To contact" })]);
  const service = new OutreachService({ config, sheet, instagram: fakeInstagram({ profiles: { 9001: { username: "Mia.Lifts" } } }), ai: {} });
  await service.handleInstagramWebhook(messagePayload({ echo: true }));
  const { record } = sheet.rows[0];
  assert.equal(record.Reached, true);
  assert.equal(record.Status, "Contacted");
  assert.equal(record["Instagram user ID"], "9001");
});

test("a creator reply is answered by the bot and recorded in the sheet", async () => {
  const sheet = fakeSheet([creatorRow({ "Instagram user ID": "9001" })]);
  const instagram = fakeInstagram({ conversation: [{ from: "gymfeed", text: "Hey Mia" }, { from: "creator", text: "Sounds interesting, tell me more" }] });
  let seenConversation;
  const ai = { async reply({ conversation }) { seenConversation = conversation; return decision(); } };
  const service = new OutreachService({ config, sheet, instagram, ai });
  await service.handleInstagramWebhook(messagePayload());
  assert.equal(seenConversation.length, 2);
  assert.equal(instagram.sent.length, 1);
  const { record } = sheet.rows[0];
  assert.equal(record.Reacted, true);
  assert.equal(record["Messaged back"], true);
  assert.equal(record.Status, "In conversation");
  assert.equal(record["Last handled message ID"], "m1");

  await service.handleInstagramWebhook(messagePayload());
  assert.equal(instagram.sent.length, 1, "a redelivered webhook must not trigger a second reply");
});

test("acceptance hands the conversation to the founder and notifies", async () => {
  const sheet = fakeSheet([creatorRow({ "Instagram user ID": "9001" })]);
  const notifications = [];
  const service = new OutreachService({
    config: { ...config, OUTREACH_HANDOFF_WEBHOOK_URL: "https://hooks.example/handoff" },
    sheet,
    instagram: fakeInstagram(),
    ai: { async reply() { return decision({ stage: "accepted", accepted: true, handoff: true, handoff_reason: "Agreed", next_step_for_owner: "Send the contract", collected_email: "mia@lifts.com" }); } },
    fetchImpl: async (url, init) => { notifications.push({ url, body: JSON.parse(init.body) }); return { ok: true }; },
  });
  await service.handleInstagramWebhook(messagePayload({ text: "I'm in!" }));
  const { record } = sheet.rows[0];
  assert.equal(record.Accepted, true);
  assert.equal(record.Status, "Accepted");
  assert.equal(record.Owner, "Aleks");
  assert.equal(record["Next step for you"], "Send the contract");
  assert.equal(record.Email, "mia@lifts.com");
  assert.equal(notifications[0].body.handle, "mia.lifts");
});

test("the bot stays silent for unknown senders and for conversations the founder owns", async () => {
  const sheet = fakeSheet([creatorRow({ "Instagram user ID": "9001", Owner: "Aleks", Status: "Handed off" })]);
  const instagram = fakeInstagram();
  let calls = 0;
  const service = new OutreachService({ config, sheet, instagram, ai: { async reply() { calls += 1; return decision(); } } });
  await service.handleInstagramWebhook(messagePayload({ sender: "5555" }));
  await service.handleInstagramWebhook(messagePayload());
  assert.equal(calls, 0);
  assert.equal(instagram.sent.length, 0);
  assert.equal(sheet.rows[0].record.Status, "Handed off");
  assert.match(sheet.rows[0].record["Last activity"], /New message for Aleks/);
});

test("without auto-reply the bot only suggests the reply in the sheet", async () => {
  const sheet = fakeSheet([creatorRow({ "Instagram user ID": "9001" })]);
  const instagram = fakeInstagram();
  const service = new OutreachService({ config: { ...config, OUTREACH_AUTO_REPLY: false }, sheet, instagram, ai: { async reply() { return decision(); } } });
  await service.handleInstagramWebhook(messagePayload());
  assert.equal(instagram.sent.length, 0);
  assert.match(sheet.rows[0].record["Suggested reply"], /exercise library/);
});

test("webhook routes verify the subscription and reject unsigned payloads", async () => {
  const handled = [];
  const app = Fastify();
  registerOutreachRoutes(app, { config, handleInstagramWebhook: async (body) => handled.push(body), runWeekly: async () => ({}) });
  const verify = await app.inject({ method: "GET", url: "/webhooks/instagram?hub.mode=subscribe&hub.verify_token=verify-me&hub.challenge=42" });
  assert.equal(verify.body, "42");
  const wrong = await app.inject({ method: "GET", url: "/webhooks/instagram?hub.mode=subscribe&hub.verify_token=nope&hub.challenge=42" });
  assert.equal(wrong.statusCode, 403);

  const body = JSON.stringify(messagePayload());
  const unsigned = await app.inject({ method: "POST", url: "/webhooks/instagram", payload: body, headers: { "content-type": "application/json" } });
  assert.equal(unsigned.statusCode, 401);
  const signature = `sha256=${createHmac("sha256", "app-secret").update(body).digest("hex")}`;
  const signed = await app.inject({ method: "POST", url: "/webhooks/instagram", payload: body, headers: { "content-type": "application/json", "x-hub-signature-256": signature } });
  assert.equal(signed.statusCode, 200);
  assert.equal(handled.length, 1);
  await app.close();
});
