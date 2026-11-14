import test from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { canRetryStudioJob, StudioJobs } from "../src/studio-jobs.mjs";
import { classifyStudioError, redact } from "../src/studio-errors.mjs";
import { hookSimilarity, assertFreshHooks, creativeIntelligence, attributionSummary } from "../src/creative-intelligence.mjs";
import { buildAiDecisionContext } from "../src/brain.mjs";
import { buildApp } from "../src/app.mjs";
import { registerStudioRoutes } from "../src/studio-api.mjs";
import { MarketingOrchestrator } from "../src/orchestrator.mjs";

function memoryClient() {
  const tables = { marketing_studio_jobs: [], marketing_studio_events: [] };
  const client = { tables,
    rpc: async () => {
      const row = tables.marketing_studio_jobs.find(j => ["queued","retry_wait"].includes(j.status) && Date.parse(j.next_run_at) <= Date.now());
      if (!row) return { data: null };
      Object.assign(row, { status: "running", attempts: row.attempts + 1, lock_token: randomUUID() });
      return { data: structuredClone(row) };
    },
    from(table) {
      const filters = []; let mode = "read", patch;
      const query = { select(){return query;},eq(k,v){filters.push(r=>r[k]===v);return query;},in(k,v){filters.push(r=>v.includes(r[k]));return query;},
        insert(p){mode="insert";patch=p;return query;},update(p){mode="update";patch=p;return query;},
        async single(){
          if (mode === "insert") {
            if (patch.request_key && tables[table].some(r=>r.request_key===patch.request_key)) return {error:{code:"23505"}};
            const row = { id:randomUUID(),status:"queued",attempts:0,max_attempts:3,next_run_at:new Date().toISOString(),...patch };
            tables[table].push(row); return {data:structuredClone(row)};
          }
          const row=tables[table].find(r=>filters.every(f=>f(r)));
          if (!row) return {data:null};
          if(mode==="update")Object.assign(row,patch);
          return {data:structuredClone(row)};
        },maybeSingle(){return query.single();},
      };return query;
    },
  };return client;
}
const setup = execute => { const client=memoryClient();return {client,jobs:new StudioJobs({repository:{client},execute,heartbeatMs:100000})}; };

test("credentials are removed recursively while provider reasons survive", () => {
  const secret="fal-secret-value-123456789";
  const result=redact({message:`Provider failed: ${secret} https://a.test/?token=abcd`,authorization:secret,nested:[`Bearer ${secret}`]},[secret]);
  assert.equal(JSON.stringify(result).includes(secret),false);
  assert.match(result.message,/Provider failed/);
  assert.equal(result.authorization,"[redacted]");
});
test("temporary read failures retry, ambiguous chargeable failures require reconciliation", () => {
  assert.equal(classifyStudioError(new Error("fetch failed"),{safeToRetry:true}).retryable,true);
  assert.equal(classifyStudioError(new Error("fetch failed")).retryable,false);
  assert.equal(classifyStudioError(new Error("fal content_policy_violation")).category,"moderation");
  assert.equal(classifyStudioError(new Error("Required Drive video is missing: source.mp4")).category,"missing_asset");
  assert.equal(classifyStudioError(new Error("Budget limit reached")).category,"budget");
});
test("stable request keys prevent double enqueue",async()=>{
  const {jobs,client}=setup(async()=>({done:true}));
  const one=await jobs.enqueue({kind:"sync",requestKey:"same-key",payload:{}});
  const two=await jobs.enqueue({kind:"sync",requestKey:"same-key",payload:{}});
  assert.equal(one.id,two.id);assert.equal(client.tables.marketing_studio_jobs.length,1);
});
test("two simultaneous ticks execute a job exactly once",async()=>{
  let release;let calls=0;
  const wait=new Promise(r=>{release=r;});
  const {jobs,client}=setup(async()=>{calls++;await wait;return {done:true};});
  await jobs.enqueue({kind:"sync",requestKey:"concurrent",payload:{}});
  const first=jobs.tick();assert.deepEqual(await jobs.tick(),{busy:true});
  release();await first;assert.equal(calls,1);assert.equal(client.tables.marketing_studio_jobs[0].status,"succeeded");
});
test("safe backoff retains failure evidence and increments attempts",async()=>{
  let calls=0;
  const {jobs,client}=setup(async()=>{if(!calls++)throw new Error("fetch failed");return {done:true};});
  await jobs.enqueue({kind:"sync",requestKey:"retry-safe",payload:{}});await jobs.tick();
  const row=client.tables.marketing_studio_jobs[0];assert.equal(row.status,"retry_wait");assert.equal(row.attempts,1);
  assert.ok(Date.parse(row.next_run_at)>Date.now());
  row.next_run_at=new Date(0).toISOString();await jobs.tick();
  assert.equal(row.status,"succeeded");assert.equal(row.attempts,2);
  assert.ok(client.tables.marketing_studio_events.some(e=>e.stage==="retry_wait"&&e.detail.attempt===1));
});
test("a lost provider response cannot be manually replayed",async()=>{
  const {jobs,client}=setup(async()=>{throw new Error("Provider request timed out");});
  const row=await jobs.enqueue({kind:"idea_approve",requestKey:"unknown-outcome",payload:{}});await jobs.tick();
  assert.equal(client.tables.marketing_studio_jobs[0].status,"needs_attention");
  await assert.rejects(jobs.retry(row.id),/Reconciliation required/);
});
test("resuming an interrupted campaign keeps its request key and recovery cutoff", async () => {
  const { jobs, client } = setup(async () => ({ done: true }));
  const job = await jobs.enqueue({ kind: "plan_campaign", requestKey: "original-campaign", payload: { days: 7 } });
  const interruptedAt = "2026-11-05T19:47:40.234Z";
  Object.assign(client.tables.marketing_studio_jobs[0], {
    status: "needs_attention", attempts: 1, updated_at: interruptedAt,
    error: { code: "WORKER_INTERRUPTED", category: "interrupted", retryable: false },
  });
  const resumed = await jobs.retry(job.id);
  assert.equal(resumed.status, "queued");
  assert.equal(resumed.request_key, job.request_key);
  assert.deepEqual(resumed.payload, { days: 7, resumeBefore: interruptedAt });
  assert.equal(client.tables.marketing_studio_jobs.length, 1);
  await assert.rejects(jobs.retry(job.id), /Only stopped jobs/);
});
test("campaign timeouts can resume from the saved checkpoint with an explicit retry", async () => {
  const { jobs, client } = setup(async () => { throw new Error("Request timed out."); });
  const job = await jobs.enqueue({ kind: "plan_campaign", requestKey: "campaign-timeout", payload: { days: 7 } });
  await jobs.tick();
  const stopped = client.tables.marketing_studio_jobs[0];
  assert.equal(stopped.status, "needs_attention");
  assert.equal(stopped.error.retryable, false);
  assert.equal(canRetryStudioJob(stopped), true);
  assert.equal(canRetryStudioJob({ ...stopped, kind: "idea_approve" }), false);
  const stoppedAt = stopped.updated_at;
  const resumed = await jobs.retry(job.id);
  assert.equal(resumed.request_key, job.request_key);
  assert.deepEqual(resumed.payload, { days: 7, resumeBefore: stoppedAt });
});
test("moderation failures require review, not a retry button",async()=>{
  const {jobs}=setup(async()=>{throw new Error("content_policy_violation");});
  const row=await jobs.enqueue({kind:"idea_approve",requestKey:"moderation",payload:{}});await jobs.tick();
  await assert.rejects(jobs.retry(row.id),/Review or revise/);
});
test("only queued work can be cancelled",async()=>{
  const {jobs,client}=setup(async()=>({done:true}));
  const queued=await jobs.enqueue({kind:"sync",requestKey:"cancel",payload:{}});await jobs.cancel(queued.id);
  assert.equal(client.tables.marketing_studio_jobs[0].status,"cancelled");
  await assert.rejects(jobs.cancel(queued.id),/Only queued/);
});
test("novelty catches older hooks and ignores superficial word order",()=>{
  const hook="My gym notes made perfect sense yesterday";
  assert.ok(hookSimilarity(hook,"Yesterday my gym notes made perfect sense")>.9);
  const memory=Array.from({length:25},(_,i)=>({id:`old-${i}`,content_type:"video",hook:i===24?hook:`Distinct ${i}`}));
  assert.throws(()=>assertFreshHooks({video:{hook},instagram:{hook:"Different meal preparation"},post:{hook:"A different evening"}},memory),/old-24/);
});
test("archive separates variants, unavailable attribution and market performance",()=>{
  const rows=Array.from({length:150},(_,i)=>({id:`master-${i}`,content_type:"video",decision:{content:{hook:`Idea number ${i}`,creative_treatment:{format_family:"creator_ugc"}}}}));
  rows.unshift({master_content_id:"master-1",content_type:"video"});
  const context=buildAiDecisionContext({content:rows});
  assert.equal(context.recent_content.length,21);assert.equal(context.creative_memory.length,60);
  assert.equal(context.creative_intelligence.sample_size,150);
  assert.equal(creativeIntelligence(rows).measurement.attributable_events,0);
  assert.match(creativeIntelligence(rows).measurement.limitations[0],/cannot identify a winning/);
});
test("attribution groups observed identifiers without inventing conversion rates or dropping costs",()=>{
  const events=[{event_name:"signup",properties:{utm_content:"GF-1"}},{event_name:"activation",content_id:"GF-1"},{event_name:"signup"}];
  const summary=attributionSummary(events);
  assert.equal(summary.unattributed_rows,1);assert.deepEqual(summary.content[0].event_counts,{signup:1,activation:1});
  assert.equal(summary.content[0].conversion_rate,undefined);
  const large=buildAiDecisionContext({events_30d:events,costs:[{provider:"fal",status:"settled",actual_cost_usd:2}],content:Array.from({length:150},()=>({decision:{content:{concept:"Very long creative history ".repeat(300)}}}))});
  const prefix=JSON.stringify(large).slice(0,5000);
  assert.match(prefix,/"usd":2/);assert.match(prefix,/GF-1/);
});
test("Studio endpoints inherit worker authentication and reject malformed operations",async()=>{
  const client=memoryClient();
  const config={MARKETING_INTERNAL_TOKEN:"test-internal-token",MARKETING_APPROVAL_TOKEN:"test-approval-token",FAL_KEY:"private-fal-value-123456789"};
  const app=buildApp({config,orchestrator:{},logger:false});
  registerStudioRoutes(app,{config,cmo:{},repository:{client},orchestrator:{},captureIngestor:{}});
  app.get("/v1/studio/test-failure",async()=>{throw new Error(`Provider rejected ${config.FAL_KEY}`);});
  const denied=await app.inject({method:"POST",url:"/v1/studio/jobs",payload:{}});assert.equal(denied.statusCode,401);
  const invalid=await app.inject({method:"POST",url:"/v1/studio/jobs",headers:{"x-marketing-token":config.MARKETING_INTERNAL_TOKEN},payload:{kind:"idea_approve",payload:{revision:1}}});
  assert.equal(invalid.statusCode,400);
  const valid=await app.inject({method:"POST",url:"/v1/studio/jobs",headers:{"x-marketing-token":config.MARKETING_INTERNAL_TOKEN,"idempotency-key":"api-test"},payload:{kind:"weekly_review"}});
  assert.equal(valid.statusCode,202);assert.equal(valid.json().status,"queued");
  assert.equal(valid.body.includes(config.MARKETING_INTERNAL_TOKEN),false);
  const failed=await app.inject({method:"GET",url:"/v1/studio/test-failure",headers:{"x-marketing-token":config.MARKETING_INTERNAL_TOKEN}});
  assert.equal(failed.statusCode,500);assert.equal(failed.body.includes(config.FAL_KEY),false);
  assert.match(failed.json().message,/Provider rejected/);assert.ok(failed.json().requestId);
  await app.close();
});

test("Studio reports the current publication job and reviewed revision without returning the job payload", async t => {
  const client = memoryClient();
  const config = { MARKETING_INTERNAL_TOKEN: "test-internal-token" };
  const app = buildApp({ config, orchestrator: {}, logger: false });
  t.after(() => app.close());
  registerStudioRoutes(app, { config, cmo: {}, repository: { client }, orchestrator: {} });
  const headers = { "x-marketing-token": config.MARKETING_INTERNAL_TOKEN, "idempotency-key": "test-publish-status" };
  const queued = await app.inject({ method: "POST", url: "/v1/studio/jobs", headers,
    payload: { kind: "asset_approve", contentId: randomUUID(), payload: { revision: 3, instructions: "private review notes" } } });
  assert.equal(queued.statusCode, 202);
  const url = `/v1/studio/jobs/${queued.json().id}`;
  assert.equal((await app.inject({ url })).statusCode, 401);
  assert.equal((await app.inject({ url, headers })).json().status, "queued");
  Object.assign(client.tables.marketing_studio_jobs[0], { status: "failed", attempts: 1, error: { message: "Buffer rejected the post" } });
  const stopped = (await app.inject({ url, headers })).json();
  assert.equal(stopped.revision, 3);
  assert.equal(stopped.status, "failed");
  assert.equal(stopped.error.message, "Buffer rejected the post");
  assert.equal(stopped.canRetry, true);
  assert.equal(stopped.payload, undefined);
});

test("Studio schedules an approved carousel again without regenerating it or changing its original publication", async t => {
  const client = memoryClient();
  const content = {
    id: randomUUID(), status: "published", content_key: "GF-TEST", content_type: "carousel",
    asset_urls: ["https://example.com/one.jpg", "https://example.com/two.jpg"],
    decision: { content: { title: "GymFeed carousel", caption: "Original caption", hashtags: ["#GymFeed"] }, review_revision: 2 },
  };
  const original = structuredClone(content);
  const repository = { client, contentById: async () => content, brandConfig: async () => ({ enabled: true }),
    publicationByContent: async () => [] };
  const config = { MARKETING_INTERNAL_TOKEN: "test-internal-token", BUFFER_API_KEY: "test-buffer-key",
    BUFFER_INSTAGRAM_CHANNEL_ID: "ig", BUFFER_TIKTOK_CHANNEL_ID: "tt", BUFFER_YOUTUBE_CHANNEL_ID: "yt",
    GYMFEED_LANDING_URL: "https://gymfeed.io" };
  const posts = [];
  const publisher = { publish: async input => {
    posts.push(input);
    if (input.platform === "tiktok") throw new Error("Connection closed");
    return { id: "buffer-post-id", schedulingType: "automatic" };
  } };
  const orchestrator = new MarketingOrchestrator({ config, repository, publisher });
  const app = buildApp({ config, orchestrator, logger: false });
  t.after(() => app.close());
  const jobs = registerStudioRoutes(app, { config, repository, orchestrator });
  const schedule = (platforms, scheduledTime) => app.inject({
    method: "POST", url: `/v1/studio/content/${content.id}/schedule`,
    headers: { "x-marketing-token": config.MARKETING_INTERNAL_TOKEN }, payload: { platforms, scheduledTime },
  });
  const future = new Date(Date.now() + 86_400_000).toISOString();
  assert.equal((await schedule(["instagram", "youtube"], future)).statusCode, 400);
  assert.equal((await schedule(["instagram"], new Date().toISOString())).statusCode, 400);
  content.status = "awaiting_approval";
  assert.equal((await schedule(["instagram"], future)).statusCode, 400);
  content.status = "published";
  assert.equal(client.tables.marketing_studio_jobs.length, 0);
  const request = await schedule(["instagram", "tiktok"], future);
  assert.equal(request.statusCode, 202);
  assert.equal((await schedule(["instagram", "tiktok"], future)).json().scheduled[0].id, request.json().scheduled[0].id);
  assert.equal(client.tables.marketing_studio_jobs.length, 2);
  await jobs.tick();
  await jobs.tick();
  const [instagram, tiktok] = client.tables.marketing_studio_jobs;
  assert.equal(instagram.status, "succeeded");
  assert.equal(instagram.result.postId, "buffer-post-id");
  assert.deepEqual(posts[0].mediaUrls, original.asset_urls);
  assert.match(posts[0].text, /Original caption/);
  assert.equal(posts[0].scheduledTime, future);
  assert.equal(tiktok.status, "needs_attention");
  assert.equal(canRetryStudioJob(tiktok), false);
  assert.equal((await schedule(["tiktok"], future)).json().scheduled[0].id, tiktok.id);
  assert.equal(posts.length, 2);
  assert.deepEqual(content, original);
  const later = new Date(Date.now() + 2 * 86_400_000).toISOString();
  assert.equal((await schedule(["instagram"], later)).statusCode, 202);
  assert.equal(client.tables.marketing_studio_jobs.length, 3);
});
