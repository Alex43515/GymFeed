import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { MarketingCampaigns, campaignDates, campaignIdeaCard } from "../src/campaigns.mjs";

function fake(handler = (_action, payload) => payload) {
  const calls = [];
  const repository = { campaignCommand: async (action, payload) => {
    calls.push({ action, payload });
    return handler(action, payload);
  } };
  return { repository, calls, engine: new MarketingCampaigns({ repository }) };
}

test("campaign dates are real dates, calendar-based and capped at one month", () => {
  assert.deepEqual(campaignDates("2026-10-31", 3), ["2026-10-31", "2026-11-01", "2026-11-02"]);
  assert.throws(() => campaignDates("2026-02-30", 1), /Invalid campaign date/);
  assert.throws(() => campaignDates("2026-10-01", 32), /between 1 and 31/);
  assert.throws(() => campaignDates("2026-10-01", 1.5), /between 1 and 31/);
});

test("create requires a stable request key and valid timezone", async () => {
  const { engine, calls } = fake();
  await assert.rejects(engine.create({ name: "October", startDate: "2026-10-01" }), /request key/);
  await assert.rejects(engine.create({ name: "October", startDate: "2026-10-01", timezone: "bad-zone", requestKey: "oct" }), /timezone/);
  await engine.create({ name: "October", startDate: "2026-10-01", days: 31, requestKey: "oct" });
  assert.equal(calls.length, 1);
  assert.deepEqual(calls[0], { action: "create", payload: {
    name: "October", start_date: "2026-10-01", days: 31, timezone: "Europe/Belgrade", request_key: "oct",
  } });
});

test("idea decisions require explicit version, key, and rejection instructions", async () => {
  const { engine, calls } = fake();
  const input = { campaignId: "campaign", contentId: "content", revision: 1, requestKey: "row-v1" };
  assert.throws(() => engine.decideIdea({ ...input, decision: "reject" }), /instructions/);
  assert.throws(() => engine.decideIdea({ ...input, revision: undefined, decision: "approve" }), /revision/);
  assert.throws(() => engine.decideIdea({ ...input, decision: "publish" }), /approve or reject/);
  await engine.decideIdea({ ...input, decision: "Reject", instructions: " Show actual Train use " });
  assert.equal(calls.length, 1);
  assert.equal(calls[0].action, "decide_idea");
  assert.equal(calls[0].payload.instructions, "Show actual Train use");
  assert.equal(calls[0].payload.revision, 1);
});

test("registerDay never accepts ambiguous or duplicate content IDs", () => {
  const { engine, calls } = fake();
  assert.throws(() => engine.registerDay({ campaignId: "campaign", date: "2026-10-01", contentIds: ["a", "a"] }), /exactly one/);
  assert.throws(() => engine.registerDay({ campaignId: "campaign", date: "2026-10-01", contentIds: ["a"] }), /exactly one/);
  assert.equal(calls.length, 0);
});

test("idea card preserves source metrics and gaps instead of claiming a proven winner", () => {
  const trend = { evidence_id: "source-1", observed_at: "2026-09-20", metrics: [{ name: "views", value: 41 }], source_urls: ["https://example.org/post"] };
  const card = campaignIdeaCard({ content_id: "v1", revision: 2, publication_date: "2026-10-01", idea_status: "pending",
    content: { content_type: "video", decision: { content: { topic: "Train", hook: "Now what?", concept: "See the real routine", scenes: [{ action: "Open Train" }],
      creative_treatment: { evidence_ids: ["source-1"] } }, research: { trends: [trend], gaps: ["No conversion attribution"] } } } });
  assert.equal(card.title, "Train");
  assert.equal(card.evidence[0].metrics[0].value, 41);
  assert.equal(card.evidence[0].explicitly_cited, true);
  assert.deepEqual(card.evidence_gaps, ["No conversion attribution"]);
  assert.equal(card.estimated_cost_usd, null);
});

test("idea revision claims before LLM use and finishes only the rejected content/version", async () => {
  const { repository, calls } = fake((action) => action === "claim_revision"
    ? { claimed: true, token: "claim", content: { id: "v1" }, instructions: "Show product use" } : { done: true });
  let revisions = 0;
  const engine = new MarketingCampaigns({ repository, revise: async (content, instructions) => {
    revisions += 1;
    assert.equal(content.id, "v1");
    assert.equal(instructions, "Show product use");
    return { data: { topic: "Train", concept: "Visible product action", hook: "Now what?" }, costUsd: 0.01 };
  } });
  await engine.reviseIdea({ campaignId: "campaign", contentId: "v1", revision: 2 });
  assert.equal(revisions, 1);
  assert.deepEqual(calls.map((call) => call.action), ["claim_revision", "finish_revision"]);
  assert.equal(calls[1].payload.token, "claim");
  assert.equal(calls[1].payload.content_id, "v1");
  assert.equal(calls[1].payload.revision, 2);
});

test("concurrent revision does not make a second paid call", async () => {
  const { repository } = fake(() => ({ claimed: false, reason: "revision_in_progress" }));
  const engine = new MarketingCampaigns({ repository, revise: async () => { throw new Error("Must not call LLM"); } });
  assert.equal((await engine.reviseIdea({ campaignId: "campaign", contentId: "v1", revision: 1 })).claimed, false);
});

test("failed revision records error without approving or releasing generation", async () => {
  const { repository, calls } = fake((action) => action === "claim_revision"
    ? { claimed: true, token: "claim", content: {}, instructions: "Fix" } : {});
  const engine = new MarketingCampaigns({ repository, revise: async () => { throw new Error("provider timeout"); } });
  await assert.rejects(engine.reviseIdea({ campaignId: "campaign", contentId: "v1", revision: 1 }), /provider timeout/);
  assert.deepEqual(calls.map((call) => call.action), ["claim_revision", "fail_revision"]);
  assert.equal(calls[1].payload.error, "provider timeout");
});

test("generation and publication use database gates, never cached Sheet decisions", async () => {
  const { engine, calls } = fake(() => { throw new Error("Not approved"); });
  await assert.rejects(engine.assertGenerationAllowed("v1"), /Not approved/);
  await assert.rejects(engine.assertPublicationAllowed("v1"), /Not approved/);
  assert.deepEqual(calls.map((call) => call.action), ["assert_generation", "assert_publication"]);
});

test("duplicate work does not execute; ambiguous errors are held for reconciliation", async () => {
  const duplicate = fake(() => ({ acquired: false, reused: false, reason: "work_needs_completion_or_reconciliation" }));
  const skipped = await duplicate.engine.withWork("v1", "generate", async () => { throw new Error("Must not run"); });
  assert.equal(skipped.skipped, true);
  const { engine, calls } = fake((action) => action === "acquire_work" ? { acquired: true, token: "claim" } : {});
  await assert.rejects(engine.withWork("v1", "generate", async () => { throw new Error("network timeout"); }), /network timeout/);
  assert.equal(calls[1].payload.state, "uncertain");
});

test("completed work stores its result and never auto-starts another batch", async () => {
  const { engine, calls } = fake((action) => action === "acquire_work" ? { acquired: true, token: "claim" } : {});
  assert.deepEqual(await engine.withWork("v1", "generate", async () => ({ provider_task_id: "fal-task" })), { provider_task_id: "fal-task" });
  assert.deepEqual(calls.map((call) => call.action), ["acquire_work", "finish_work"]);
  assert.equal(calls[1].payload.state, "completed");
});

// Optional integration test: run ONLY against a disposable PostgreSQL container
// with no production data. It exercises the actual migration and atomic gates.
test("PostgreSQL campaign state gates and exact version manifests", {
  skip: !process.env.CAMPAIGN_SQL_TEST_CONTAINER,
}, () => {
  const container = process.env.CAMPAIGN_SQL_TEST_CONTAINER;
  if (!/^gymfeed-campaign-state-test(?:-[a-z0-9]+)?$/.test(container)) throw new Error("Refusing a non-test PostgreSQL container");
  const sql = (input) => execFileSync("docker", ["exec", "-i", container, "psql", "-X", "-U", "postgres", "-v", "ON_ERROR_STOP=1", "-Atq"],
    { input, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }).trim();
  sql(`create role anon; create role authenticated; create role service_role;
    create type public.marketing_content_status as enum ('planned','generating','generated','qa_failed','awaiting_approval','approved','scheduled','published','skipped','failed');
    create type public.marketing_content_type as enum ('video','image','carousel');
    create table public.marketing_content(id uuid primary key default gen_random_uuid(), content_key text unique not null,
      content_type marketing_content_type not null, status marketing_content_status not null default 'planned',
      topic text not null, concept text not null, hook text not null, decision jsonb not null default '{}',
      provider text, provider_task_id text, asset_urls text[] not null default '{}', thumbnail_url text, qa_score int,
      qa jsonb not null default '{}', failure_reason text, approved_by uuid, approved_at timestamptz,
      scheduled_at timestamptz, published_at timestamptz, created_at timestamptz default now(), updated_at timestamptz default now());`);
  sql(readFileSync(new URL("../../supabase/migrations/0032_marketing_campaign_batches.sql", import.meta.url), "utf8"));
  const quote = (value) => `'${String(value).replaceAll("'", "''")}'`;
  const rpc = (action, payload) => JSON.parse(sql(`select public.marketing_campaign_command(${quote(action)}, ${quote(JSON.stringify(payload))}::jsonb);`));
  const snapshot = rpc("create", { name: "Test campaign", start_date: "2026-10-01", days: 9, timezone: "Europe/Belgrade", request_key: "test-campaign" });
  const campaignId = snapshot.campaign.id;
  assert.equal(rpc("create", { name: "Test campaign", start_date: "2026-10-01", days: 9, timezone: "Europe/Belgrade", request_key: "test-campaign" }).campaign.id, campaignId);
  assert.throws(() => rpc("create", { name: "Changed", start_date: "2026-10-01", days: 9, timezone: "Europe/Belgrade", request_key: "test-campaign" }), /Command failed/);
  assert.throws(() => rpc("submit", { campaign_id: campaignId }), /Command failed/);
  sql(`insert into public.marketing_content(content_key,content_type,topic,concept,hook,decision)
    select 'test-' || day || '-' || kind, kind::marketing_content_type, 'Train', 'A real product action', 'Now what?',
      '{"content":{"topic":"Train","concept":"A real product action","hook":"Now what?"}}'::jsonb
    from generate_series(1,9) day cross join unnest(array['video','carousel']) kind;`);
  const contents = JSON.parse(sql("select jsonb_agg(to_jsonb(c) order by content_key) from public.marketing_content c;"));
  const idsFor = (day) => contents.filter((content) => content.content_key.startsWith(`test-${day}-`)).map((content) => content.id);
  assert.throws(() => rpc("assert_generation", { content_id: idsFor(1)[0] }), /Command failed/);
  for (let day = 1; day <= 9; day += 1) rpc("register_day", { campaign_id: campaignId, date: `2026-10-${String(day).padStart(2, "0")}`, content_ids: idsFor(day) });
  let state = rpc("submit", { campaign_id: campaignId });
  assert.equal(state.ideas.length, 18);
  assert.throws(() => rpc("start_batch", { campaign_id: campaignId, request_key: "batch-one" }), /Command failed/);
  const decide = (id, revision, decision, instructions = "", request_key = `${id}-${revision}-${decision}`) => rpc("decide_idea", {
    campaign_id: campaignId, content_id: id, revision, decision, instructions, request_key, reviewer: "test",
  });
  for (const item of state.ideas.slice(0, -1)) decide(item.content_id, 1, "approve");
  assert.throws(() => rpc("start_batch", { campaign_id: campaignId, request_key: "batch-one" }), /Command failed/);
  const last = state.ideas.at(-1);
  decide(last.content_id, 1, "approve");
  const first = rpc("start_batch", { campaign_id: campaignId, request_key: "batch-one" });
  assert.equal(first.content_ids.length, 14);
  assert.equal(first.batch.end_date, "2026-10-07");
  assert.equal(rpc("start_batch", { campaign_id: campaignId, request_key: "batch-one" }).batch.id, first.batch.id);
  assert.throws(() => rpc("start_batch", { campaign_id: campaignId, request_key: "batch-two" }), /Command failed/);
  assert.throws(() => rpc("assert_generation", { content_id: last.content_id }), /Command failed/);
  const target = first.content_ids[0];
  assert.equal(rpc("assert_generation", { content_id: target }).allowed, true);
  assert.throws(() => rpc("assert_publication", { content_id: target }), /Command failed/);
  // Direct edits cannot bypass the approved version hash.
  sql(`update public.marketing_content set decision=jsonb_set(decision,'{content,hook}','"Changed without approval"') where id=${quote(target)};`);
  assert.throws(() => rpc("assert_generation", { content_id: target }), /Command failed/);
  sql(`update public.marketing_content set decision=jsonb_set(decision,'{content,hook}','"Now what?"') where id=${quote(target)};`);
  decide(target, 1, "reject", "Show real Train use");
  assert.throws(() => rpc("assert_generation", { content_id: first.content_ids[1] }), /Command failed/);
  assert.throws(() => rpc("acquire_work", { content_id: first.content_ids[1], operation: "produce", request_key: "unapproved-race" }), /Command failed/);
  const claim = rpc("claim_revision", { campaign_id: campaignId, content_id: target, revision: 1 });
  assert.equal(claim.claimed, true);
  assert.equal(rpc("claim_revision", { campaign_id: campaignId, content_id: target, revision: 1 }).claimed, false);
  state = rpc("finish_revision", { campaign_id: campaignId, content_id: target, revision: 1, token: claim.token,
    plan: { topic: "Train", concept: "Open and start a real routine", hook: "Walk in with a plan" } });
  assert.equal(state.ideas.find((idea) => idea.content_id === target).revision, 2);
  assert.equal(state.ideas.filter((idea) => idea.idea_status === "approved").length, 17);
  assert.throws(() => decide(target, 1, "approve", "", "stale-new-key"), /Command failed/);
  decide(target, 2, "approve");
  assert.equal(rpc("assert_generation", { content_id: target }).idea_revision, 2);
  const work = rpc("acquire_work", { content_id: target, operation: "generate", request_key: "request-one" });
  assert.equal(work.acquired, true);
  assert.throws(() => decide(target, 2, "reject", "Concurrent edit", "reject-during-work"), /Command failed/);
  assert.equal(rpc("acquire_work", { content_id: target, operation: "generate", request_key: "request-two" }).acquired, false);
  rpc("finish_work", { content_id: target, token: work.token, state: "uncertain", error: "timeout" });
  assert.equal(rpc("acquire_work", { content_id: target, operation: "publish", request_key: "request-three" }).acquired, false);
  rpc("finish_work", { content_id: target, token: work.token, state: "completed", result: { provider_task_id: "known" } });
  assert.equal(rpc("acquire_work", { content_id: target, operation: "generate", request_key: "request-one" }).reused, true);
  sql(`update public.marketing_content set status='approved', approved_at=now() where id in (${first.content_ids.map(quote).join(",")});`);
  assert.equal(rpc("assert_publication", { content_id: target }).allowed, true);
  const second = rpc("start_batch", { campaign_id: campaignId, request_key: "batch-two" });
  assert.equal(second.content_ids.length, 4);
  assert.equal(second.batch.start_date, "2026-10-08");
  assert.equal(second.batch.end_date, "2026-10-09");
  sql(`update public.marketing_content set status='approved', approved_at=now() where id in (${second.content_ids.map(quote).join(",")});`);
  assert.equal(rpc("start_batch", { campaign_id: campaignId, request_key: "batch-three" }).complete, true);
  // The RPC is not callable by normal app accounts.
  assert.equal(sql("select has_function_privilege('authenticated','public.marketing_campaign_command(text,jsonb)','execute');"), "f");
});
