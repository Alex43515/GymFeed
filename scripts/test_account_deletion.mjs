import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { createClient } from "@supabase/supabase-js";

if (process.env.GYMFEED_RUN_DELETION_QA !== "1") {
  throw new Error("Set GYMFEED_RUN_DELETION_QA=1 to create and delete isolated QA fixtures.");
}
const url = process.env.SUPABASE_URL;
const publicKey = process.env.SUPABASE_ANON_KEY ?? "sb_publishable_iyY6WXUGOBK2pkePZFZurw_ZIStK1ge";
const options = { auth: { persistSession: false, autoRefreshToken: false } };
const admin = createClient(url, process.env.SUPABASE_SERVICE_ROLE_KEY, options);
const fixtures = [];
const checked = ({ data, error }, label) => { if (error) throw new Error(`${label}: ${error.message}`); return data; };
const pixel = Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aS1cAAAAASUVORK5CYII=", "base64");
let chatId;

async function createFixture() {
  const tag = randomUUID().replaceAll("-", "").slice(0, 12);
  const email = `gymfeed-deletion-qa-${tag}@example.invalid`;
  const password = randomUUID() + "aA1!";
  const { user } = checked(await admin.auth.admin.createUser({
    email, password, email_confirm: true,
    user_metadata: { username: `delqa_${tag}`, display_name: "Temporary deletion QA" },
  }), "create temporary fixture");
  const client = createClient(url, publicKey, options);
  const fixture = { id: user.id, client, deleted: false };
  fixtures.push(fixture);
  checked(await client.auth.signInWithPassword({ email, password }), "fixture sign-in");
  console.log(JSON.stringify({ createdQaFixture: user.id }));
  checked(await client.storage.from("images").upload(`${user.id}/deletion-qa.png`, pixel, { contentType: "image/png" }), "fixture upload");
  return fixture;
}

async function deleteFixture(fixture, body = {}) {
  const result = await fixture.client.functions.invoke("delete-account", { body });
  if (result.error || result.data?.deleted !== true) {
    const details = result.error?.context ? await result.error.context.text().catch(() => "") : "";
    throw new Error(`QA deletion failed for ${fixture.id}: ${result.error?.message ?? JSON.stringify(result.data)} ${details}`);
  }
  fixture.deleted = true;
}

try {
  const a = await createFixture(), b = await createFixture();
  const { data: sessionData } = await a.client.auth.getSession();
  const accessToken = sessionData.session.access_token;
  const denied = await a.client.from("media_assets").insert({ owner_id: a.id, kind: "video", provider: "bunny_stream", bunny_video_guid: randomUUID() });
  assert.ok(denied.error, "Clients must not forge Bunny ownership");

  const seed = [
    ["posts", { user_id: a.id, caption: "Temporary deletion fixture" }],
    ["meal_scans", { user_id: a.id, dish_name: "Temporary deletion fixture" }],
    ["workout_entries", { user_id: a.id, exercise_name: "Temporary deletion fixture" }],
    ["progress_entries", { user_id: a.id, month_start: "2026-10-01", note: "Temporary deletion fixture" }],
    ["starter_plans", { user_id: a.id }],
    ["ai_coach_threads", { user_id: a.id, memory_summary: "Temporary deletion fixture" }],
    ["ai_coach_messages", { user_id: a.id, role: "user", content: "Temporary deletion fixture" }],
  ];
  for (const [table, row] of seed) checked(await admin.from(table).insert(row), `seed ${table}`);
  const chat = checked(await admin.from("chats").insert({ last_message: "Temporary deletion fixture", last_message_sent_by: a.id }).select("id").single(), "seed chat");
  chatId = chat.id;
  checked(await admin.from("chat_members").insert([{ chat_id: chatId, user_id: a.id }, { chat_id: chatId, user_id: b.id }]), "seed chat members");
  checked(await admin.from("chat_messages").insert([{ chat_id: chatId, user_id: a.id, text: "Remove this fixture" }, { chat_id: chatId, user_id: b.id, text: "Keep this fixture" }]), "seed chat messages");
  checked(await admin.from("chats").update({ last_message: "Remove this fixture", last_message_sent_by: a.id }).eq("id", chatId), "seed last-message reference");

  if (process.env.GYMFEED_QA_BUNNY === "1") {
    const ticket = checked(await a.client.functions.invoke("create-upload", { body: { title: "Temporary GymFeed deletion QA - no user media" } }), "create empty QA video");
    assert.ok(ticket.videoId, "Expected a provider video ID");
  }
  await deleteFixture(a, { userId: b.id });
  const missingUser = await admin.auth.admin.getUserById(a.id);
  assert.ok(missingUser.error, "Auth user must be removed");
  for (const [table, key] of [["profiles", "id"], ["profile_private", "id"], ["media_assets", "owner_id"], ...seed.map(([table]) => [table, "user_id"]), ["chat_messages", "user_id"], ["chat_members", "user_id"]]) {
    const rows = checked(await admin.from(table).select(key).eq(key, a.id), `verify ${table}`);
    assert.equal(rows.length, 0, `${table} retained deleted-user data`);
  }
  assert.equal(checked(await admin.storage.from("images").list(a.id), "verify removed files").length, 0);
  assert.ok(checked(await admin.auth.admin.getUserById(b.id), "verify second account").user);
  assert.equal(checked(await admin.storage.from("images").list(b.id), "verify second account files").length, 1);
  assert.equal(checked(await admin.from("chat_messages").select("id").eq("chat_id", chatId).eq("user_id", b.id), "verify second account message").length, 1);

  const stale = createClient(url, publicKey, { ...options, global: { headers: { Authorization: `Bearer ${accessToken}` } } });
  const upload = await stale.storage.from("images").upload(`${a.id}/must-not-survive.png`, pixel, { contentType: "image/png" });
  assert.ok(upload.error, "Deleted-user token must not create new storage objects");
  console.log(JSON.stringify({ deletedUser: a.id, authAndDataPurged: true, otherAccountPreserved: true, staleTokenUploadDenied: true, bunnyPathTested: process.env.GYMFEED_QA_BUNNY === "1" }));
} finally {
  for (const fixture of fixtures) {
    if (!fixture.deleted) await deleteFixture(fixture);
  }
  if (chatId) checked(await admin.from("chats").delete().eq("id", chatId), "remove fixture conversation");
  console.log(JSON.stringify({ allCreatedQaAccountsRemoved: fixtures.every((f) => f.deleted) }));
}
