import assert from "node:assert/strict";
import test from "node:test";
import { drainLifecycleEmails } from "./handler.mjs";
import { daysLeft, emailFor, foundingLabel, reminderEmail, welcomeEmail } from "./templates.mjs";

const NOW = new Date("2026-12-06T15:00:00Z");
const hoursFromNow = (hours) => new Date(NOW.getTime() + hours * 3_600_000).toISOString();

const founding = {
  id: "row-1",
  kind: "welcome",
  email: "maria@gmail.com",
  display_name: "Maria Lopez",
  username: "maria_fit",
  founding_number: 142,
  trial_days: 7,
  premium_until: hoursFromNow(7 * 24),
  invites_used: 0,
};

test("founding welcome matches the plan copy", () => {
  const email = welcomeEmail(founding);
  assert.equal(email.subject, "You're GymFeed Founding Member #0142");
  assert.match(email.text, /^Hi Maria,/);
  assert.match(email.text, /one of the first 1,000 people here/);
  assert.match(email.text, /7 days of Premium, starting today/);
  assert.match(email.text, /enter your username, @maria_fit, when they sign up/);
  assert.match(email.text, /goes straight to the founders/);
  assert.match(email.text, /https:\/\/gymfeed\.io\/download/);
  assert.match(email.text, /Reply STOP/);
  assert.match(email.html, /Founding Member #0142/);
});

test("users after the first 1,000 get a plain welcome with their days", () => {
  const email = welcomeEmail({ ...founding, founding_number: null, trial_days: 3 });
  assert.equal(email.subject, "Welcome to GymFeed");
  assert.match(email.text, /3 days of Premium, starting today/);
  assert.doesNotMatch(email.text, /Founding/);
});

test("names and usernames are escaped in HTML", () => {
  const email = welcomeEmail({ ...founding, display_name: "<script>x</script>", username: "a&b" });
  assert.doesNotMatch(email.html, /<script>/);
  assert.match(email.html, /&lt;script&gt;/);
  assert.match(email.html, /@a&amp;b/);
});

test("reminder counts whole days left and invites remaining", () => {
  const row = { ...founding, kind: "premium_reminder", premium_until: hoursFromNow(41), invites_used: 1 };
  const email = reminderEmail(row, NOW);
  assert.equal(email.subject, "2 days of Premium left, Founding Member #0142");
  assert.match(email.text, /ends in 2 days/);
  assert.match(email.text, /enter @maria_fit under "Who invited you\?"/);
  assert.match(email.text, /You have 3 invites left/);
});

test("reminder after all 4 invites points to Pro instead", () => {
  const row = { ...founding, kind: "premium_reminder", premium_until: hoursFromNow(20), invites_used: 4 };
  const email = reminderEmail(row, NOW);
  assert.equal(email.subject, "1 day of Premium left, Founding Member #0142");
  assert.match(email.text, /GymFeed Pro/);
  assert.doesNotMatch(email.text, /Who invited you/);
});

test("no reminder once Premium ended or after an invite extended it", () => {
  assert.equal(reminderEmail({ ...founding, premium_until: hoursFromNow(-1) }, NOW), null);
  assert.equal(reminderEmail({ ...founding, premium_until: hoursFromNow(9 * 24) }, NOW), null);
  assert.equal(emailFor({ ...founding, kind: "unknown" }, NOW), null);
});

test("helpers", () => {
  assert.equal(foundingLabel(7), "#0007");
  assert.equal(foundingLabel(null), null);
  assert.equal(daysLeft(hoursFromNow(48), NOW), 2);
  assert.equal(daysLeft(hoursFromNow(48.5), NOW), 3);
  assert.equal(daysLeft("not a date", NOW), 0);
});

function fakeAdmin(rows) {
  const calls = [];
  return {
    calls,
    async rpc(name, params) {
      calls.push([name, params]);
      if (name === "claim_lifecycle_emails") return { data: rows, error: null };
      return { data: null, error: null };
    },
  };
}

test("without a Resend key nothing is claimed, stale rows expire", async () => {
  const admin = fakeAdmin([founding]);
  const result = await drainLifecycleEmails({ admin, resendApiKey: "", from: "x", fetchImpl: () => assert.fail("no send") });
  assert.equal(result.configured, false);
  assert.deepEqual(admin.calls.map(([name]) => name), ["expire_lifecycle_emails"]);
});

test("sends through Resend with an idempotency key and records the outcome", async () => {
  const admin = fakeAdmin([
    founding,
    { ...founding, id: "row-2", kind: "premium_reminder", premium_until: hoursFromNow(9 * 24) },
    { ...founding, id: "row-3", email: null },
    { ...founding, id: "row-4" },
    { ...founding, id: "row-5" },
  ]);
  const sent = [];
  const statuses = { "row-4": 500, "row-5": 422 };
  const fetchImpl = async (url, init) => {
    sent.push({ url, init, body: JSON.parse(init.body) });
    const id = init.headers["Idempotency-Key"].replace("gymfeed-lifecycle-", "");
    const status = statuses[id] ?? 200;
    return new Response(status === 200 ? "{}" : "nope", { status });
  };

  const result = await drainLifecycleEmails({
    admin, resendApiKey: "re_test", from: "GymFeed <hello@gymfeed.io>", replyTo: "founders@gymfeed.io",
    fetchImpl, now: () => NOW,
  });

  assert.deepEqual(result, { configured: true, sent: 1, skipped: 2, retried: 1, failed: 1 });
  assert.equal(sent.length, 3);
  assert.equal(sent[0].url, "https://api.resend.com/emails");
  assert.equal(sent[0].init.headers.Authorization, "Bearer re_test");
  assert.equal(sent[0].init.headers["Idempotency-Key"], "gymfeed-lifecycle-row-1");
  assert.deepEqual(sent[0].body.to, ["maria@gmail.com"]);
  assert.equal(sent[0].body.reply_to, "founders@gymfeed.io");
  assert.equal(sent[0].body.subject, "You're GymFeed Founding Member #0142");

  const finishes = admin.calls.filter(([name]) => name === "finish_lifecycle_email").map(([, p]) => [p.p_id, p.p_status]);
  assert.deepEqual(finishes, [
    ["row-1", "sent"],
    ["row-2", "skipped"],
    ["row-3", "skipped"],
    ["row-4", "retry"],
    ["row-5", "failed"],
  ]);
});

test("a network error is retried, not lost", async () => {
  const admin = fakeAdmin([founding]);
  const result = await drainLifecycleEmails({
    admin, resendApiKey: "re_test", from: "x", now: () => NOW,
    fetchImpl: async () => { throw new Error("offline"); },
  });
  assert.equal(result.retried, 1);
  const [, params] = admin.calls.find(([name]) => name === "finish_lifecycle_email");
  assert.equal(params.p_status, "retry");
  assert.match(params.p_error, /offline/);
});
