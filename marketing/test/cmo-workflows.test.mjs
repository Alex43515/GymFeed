import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const workflow = (filename) => JSON.parse(readFileSync(new URL(`../deploy/workflows/${filename}`, import.meta.url), "utf8"));
const main = workflow("00-main-cmo-orchestrator.json");
const dispatcher = workflow("05-google-sheet-approval.json");
const type = (flow, suffix) => flow.nodes.filter((node) => node.type === `n8n-nodes-base.${suffix}`);

function next(flow, name) {
  return (flow.connections[name]?.main ?? []).flat().map((edge) => edge.node);
}

function executeCode(node, input, overrides = {}) {
  let source = node.parameters.jsCode;
  for (const [key, value] of Object.entries(overrides)) {
    source = source.replace(new RegExp(`const ${key} = [^;]+;`), `const ${key} = ${JSON.stringify(value)};`);
  }
  const now = {
    setZone: (zone) => {
      assert.equal(zone, "America/New_York");
      return { plus: ({ days }) => {
        assert.equal(days, 7);
        return { toFormat: (format) => { assert.equal(format, "yyyy-MM-dd"); return "2026-09-27"; } };
      } };
    },
  };
  return new Function("$input", "$now", source)({ first: () => ({ json: input }) }, now);
}

test("CMO workflow retains its public identity and has no recurring generation trigger", () => {
  assert.equal(main.id, "GFMainCMOOrchestrator001");
  assert.equal(main.name, "GymFeed 00 - Main CMO Orchestrator");
  assert.equal(type(main, "manualTrigger").length, 1);
  assert.equal(type(main, "scheduleTrigger").length, 0);
  assert.equal(type(main, "executeWorkflowTrigger")[0].parameters.inputSource, "passthrough");
  const settings = type(main, "code")[0];
  const execute = type(main, "httpRequest")[0];
  assert.deepEqual(next(main, type(main, "manualTrigger")[0].name), [settings.name]);
  assert.deepEqual(next(main, settings.name), [execute.name]);
  assert.deepEqual(next(main, type(main, "executeWorkflowTrigger")[0].name), [execute.name]);
});

test("manual default only plans a 28-day campaign with a stable retry key", () => {
  const settings = type(main, "code")[0];
  const first = executeCode(settings, {})[0].json;
  assert.equal(first.action, "plan_campaign");
  assert.equal(first.days, 28);
  assert.equal(first.startDate, "2026-09-27");
  assert.equal(first.timezone, "America/New_York");
  assert.equal(first.requestKey, executeCode(settings, {})[0].json.requestKey);
  assert.equal(first.campaignId, undefined);
  assert.equal(first.batchId, undefined);
  assert.match(settings.parameters.jsCode, /fixed YYYY-MM-DD/);
});

test("manual batch actions require the existing campaign and batch identifiers", () => {
  const settings = type(main, "code")[0];
  assert.throws(() => executeCode(settings, {}, { action: "start_batch" }), /Set campaignId/);
  const start = executeCode(settings, {}, { action: "start_batch", campaignId: "campaign-1", batchNumber: 2 })[0].json;
  assert.deepEqual(start, { action: "start_batch", campaignId: "campaign-1", batchNumber: 2, requestKey: "campaign:campaign-1:batch:2" });
  for (const action of ["resume_batch", "release_batch"]) {
    assert.throws(() => executeCode(settings, {}, { action, campaignId: "campaign-1" }), /Set batchId/);
    assert.deepEqual(executeCode(settings, {}, { action, campaignId: "campaign-1", batchId: "batch-1" })[0].json,
      { action, campaignId: "campaign-1", batchId: "batch-1" });
  }
  assert.deepEqual(executeCode(settings, {}, { action: "status", campaignId: "campaign-1" })[0].json,
    { action: "status", campaignId: "campaign-1" });
});

test("CMO waits synchronously for its action with six-hour HTTP timeout and no automatic request retries", () => {
  const requests = type(main, "httpRequest");
  assert.equal(requests.length, 1);
  const request = requests[0];
  assert.equal(request.parameters.url, "http://marketing-worker:3000/v1/cmo/execute");
  assert.equal(request.parameters.method, "POST");
  assert.equal(request.parameters.jsonBody, "={{ $json }}");
  assert.equal(request.parameters.options.timeout, 6 * 60 * 60 * 1000);
  assert.ok(main.settings.executionTimeout * 1000 > request.parameters.options.timeout);
  assert.notEqual(request.retryOnFail, true);
  assert.notEqual(request.continueOnFail, true);
  assert.equal(request.parameters.headerParameters.parameters[0].value, "={{ $env.MARKETING_INTERNAL_TOKEN }}");
});

test("Sheet dispatcher runs every five minutes or manually and waits for the existing main CMO", () => {
  assert.equal(dispatcher.id, "GFReviewSheet001");
  assert.equal(dispatcher.name, "GymFeed 05 - Google Sheet Decision Dispatcher");
  const schedule = type(dispatcher, "scheduleTrigger")[0];
  const manual = type(dispatcher, "manualTrigger")[0];
  const read = type(dispatcher, "httpRequest")[0];
  const split = type(dispatcher, "code")[0];
  const execute = type(dispatcher, "executeWorkflow")[0];
  assert.deepEqual(schedule.parameters.rule.interval, [{ field: "minutes", minutesInterval: 5 }]);
  assert.equal(read.parameters.url, "http://marketing-worker:3000/v1/cmo/decisions");
  assert.deepEqual(next(dispatcher, schedule.name), [read.name]);
  assert.deepEqual(next(dispatcher, manual.name), [read.name]);
  assert.deepEqual(next(dispatcher, read.name), [split.name]);
  assert.deepEqual(next(dispatcher, split.name), [execute.name]);
  assert.equal(execute.parameters.workflowId.value, main.id);
  assert.equal(execute.parameters.mode, "each");
  assert.equal(execute.parameters.options.waitForSubWorkflow, true);
});

test("dispatcher forwards exact idea/asset decisions but cannot auto-plan, start or release batches", () => {
  const split = type(dispatcher, "code")[0];
  const actions = [
    { action: "idea_decision", entry: { ideaId: "idea-1", version: 2, decision: "Reject", instructions: "Show real product use" } },
    { action: "asset_decision", entry: { contentId: "video-1", revision: 3, decision: "Approve" } },
  ];
  assert.deepEqual(executeCode(split, { actions }).map((entry) => entry.json), actions);
  assert.deepEqual(executeCode(split, { actions: [] }), []);
  assert.throws(() => executeCode(split, {}), /actions array/);
  for (const action of ["plan_campaign", "start_batch", "release_batch"]) {
    assert.throws(() => executeCode(split, { actions: [{ action, entry: {} }] }), /only explicit/);
  }
});

test("workflow references resolve and no workflow embeds secrets or old immediate-generation endpoints", () => {
  for (const flow of [main, dispatcher]) {
    const names = new Set(flow.nodes.map((node) => node.name));
    assert.equal(names.size, flow.nodes.length);
    assert.equal(new Set(flow.nodes.map((node) => node.id)).size, flow.nodes.length);
    for (const [source] of Object.entries(flow.connections)) {
      assert.ok(names.has(source), `Missing source ${source}`);
      for (const target of next(flow, source)) assert.ok(names.has(target), `Missing target ${target}`);
    }
    assert.ok(type(flow, "stickyNote").length > 0);
    for (const request of type(flow, "httpRequest")) {
      assert.match(request.parameters.url, /\/v1\/cmo\/(execute|decisions)$/);
      assert.equal(request.parameters.headerParameters.parameters[0].value, "={{ $env.MARKETING_INTERNAL_TOKEN }}");
    }
  }
});
