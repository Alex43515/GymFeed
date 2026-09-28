import test from "node:test";
import assert from "node:assert/strict";
import { buildApp } from "../src/app.mjs";

const config = {
  MARKETING_INTERNAL_TOKEN: "internal-token",
  MARKETING_APPROVAL_TOKEN: "approval-token",
  GOOGLE_DRIVE_ASSET_UPLOAD_URL: "https://drive.google.com/drive/folders/test-folder",
};

function fakeOrchestrator() {
  return new Proxy({}, {
    get: (_target, property) => async (...args) => ({ method: String(property), args }),
  });
}

test("health is public and internal routes require the worker token", async (t) => {
  const app = buildApp({ config, orchestrator: fakeOrchestrator(), logger: false });
  t.after(() => app.close());
  assert.equal((await app.inject({ method: "GET", url: "/health" })).statusCode, 200);
  assert.equal((await app.inject({ method: "POST", url: "/v1/runs/daily" })).statusCode, 401);
  const response = await app.inject({
    method: "POST",
    url: "/v1/runs/daily",
    headers: { "x-marketing-token": config.MARKETING_INTERNAL_TOKEN },
  });
  assert.equal(response.statusCode, 200);
  assert.equal(response.json().method, "runDaily");

  const batch = await app.inject({
    method: "POST",
    url: "/v1/runs/daily-batch",
    headers: { "x-marketing-token": config.MARKETING_INTERNAL_TOKEN },
    payload: { start_date: "2026-09-18", days: 3, revision: 2 },
  });
  assert.equal(batch.statusCode, 200);
  assert.equal(batch.json().method, "runDailyBatch");
  assert.equal(batch.json().args[1].days, 3);

  const sheetSync = await app.inject({
    method: "POST",
    url: "/v1/reviews/sync",
    headers: { "x-marketing-token": config.MARKETING_INTERNAL_TOKEN },
  });
  assert.equal(sheetSync.statusCode, 200);
  assert.equal(sheetSync.json().method, "syncApprovalSheet");

  const processContent = await app.inject({
    method: "POST",
    url: "/v1/content/campaign-content-1/process",
    headers: { "x-marketing-token": config.MARKETING_INTERNAL_TOKEN },
  });
  assert.equal(processContent.statusCode, 200);
  assert.equal(processContent.json().method, "processContentToReview");
  assert.deepEqual(processContent.json().args, ["campaign-content-1"]);

  const claimed = await app.inject({
    method: "POST",
    url: "/v1/reviews/claim",
    headers: { "x-marketing-token": config.MARKETING_INTERNAL_TOKEN },
  });
  assert.equal(claimed.statusCode, 200);
  assert.equal(claimed.json().method, "claimApprovalSheetDecisions");

  const prepared = await app.inject({
    method: "POST",
    url: "/v1/reviews/prepare",
    headers: { "x-marketing-token": config.MARKETING_INTERNAL_TOKEN },
    payload: { reviewId: "review-1", rowNumber: 2 },
  });
  assert.equal(prepared.statusCode, 200);
  assert.equal(prepared.json().method, "prepareClaimedReview");
  assert.deepEqual(prepared.json().args, [{ reviewId: "review-1", rowNumber: 2 }]);
});

test("approval uses a separate token", async (t) => {
  const app = buildApp({ config, orchestrator: fakeOrchestrator(), logger: false });
  t.after(() => app.close());
  const wrong = await app.inject({
    method: "POST",
    url: "/v1/content/abc/approve",
    headers: { "x-marketing-token": config.MARKETING_INTERNAL_TOKEN },
  });
  assert.equal(wrong.statusCode, 401);
  const approved = await app.inject({
    method: "POST",
    url: "/v1/content/abc/approve",
    headers: { "x-marketing-approval-token": config.MARKETING_APPROVAL_TOKEN },
  });
  assert.equal(approved.statusCode, 200);
  assert.equal(approved.json().method, "approveContent");
});

test("automatic idea approval records an Approved - Blocked reason when Drive intake fails", async (t) => {
  const updates = [];
  const acknowledgments = [];
  const content = { id: "video-1", status: "planned", decision: { content: { scenes: [] }, campaign: { id: "campaign-1" } } };
  const cmo = {
    ideaDecision: async () => ({ action: "idea_reviewed" }),
    repository: {
      contentById: async () => structuredClone(content),
      updateContent: async (_id, patch) => { updates.push(patch); return { ...content, ...patch }; },
    },
    approvalSheet: { markIdeaDecision: async (_entry, message) => acknowledgments.push(message) },
    sync: async () => ({ campaign: { id: "campaign-1" } }),
    campaigns: {},
  };
  const app = buildApp({
    config,
    orchestrator: fakeOrchestrator(),
    cmo,
    captureIngestor: { importApprovedPlan: async () => { throw new Error("Required Drive video is missing: proof.mp4"); } },
    logger: false,
  });
  t.after(() => app.close());
  const response = await app.inject({
    method: "POST",
    url: "/v1/cmo/approve-import-and-start",
    headers: { "x-marketing-token": config.MARKETING_INTERNAL_TOKEN },
    payload: { action: "idea_decision", entry: { ideaId: "video-1", campaignId: "campaign-1", version: 1, decision: "Approve" } },
  });
  assert.equal(response.statusCode, 200);
  assert.equal(response.json().action, "idea_approved_blocked");
  assert.equal(response.json().blocked, true);
  assert.equal(updates[0].decision.campaign.production_blocked, true);
  assert.match(acknowledgments[0], /Approved - Blocked.*proof\.mp4/);
});

test("automatic idea approval imports assets before starting exactly one item", async (t) => {
  const calls = [];
  const content = { id: "video-1", status: "planned", decision: { content: { scenes: [] }, campaign: { id: "campaign-1" } } };
  const cmo = {
    ideaDecision: async (_entry, options) => { calls.push({ approval: options }); return { action: "idea_reviewed" }; },
    repository: {
      contentById: async () => structuredClone(content),
      updateContent: async (_id, patch) => { calls.push({ update: patch }); return { ...content, ...patch }; },
    },
    approvalSheet: { markIdeaDecision: async (_entry, message) => calls.push({ message }) },
    sync: async () => ({ campaign: { id: "campaign-1" } }),
    execute: async (payload) => { calls.push({ execute: payload }); return { action: "batch_ready_for_asset_review" }; },
    campaigns: {},
  };
  const app = buildApp({
    config,
    orchestrator: fakeOrchestrator(),
    cmo,
    captureIngestor: { importApprovedPlan: async () => ({ captures: [{ sha256: "abc" }], images: [{ sha256: "def" }] }) },
    logger: false,
  });
  t.after(() => app.close());
  const response = await app.inject({
    method: "POST",
    url: "/v1/cmo/approve-import-and-start",
    headers: { "x-marketing-token": config.MARKETING_INTERNAL_TOKEN },
    payload: { action: "idea_decision", entry: { ideaId: "video-1", campaignId: "campaign-1", version: 2, decision: "Approve" } },
  });
  assert.equal(response.statusCode, 200);
  assert.equal(response.json().action, "idea_approved_generated");
  assert.deepEqual(calls[0], { approval: { deferProduction: true, acknowledge: false } });
  assert.equal(calls.find((call) => call.execute).execute.action, "start_item");
  assert.equal(calls.find((call) => call.execute).execute.contentId, "video-1");
  assert.match(calls.find((call) => call.message).message, /Drive assets verified/);
});

test("automatic idea approval returns a reviewable result when generated media fails QA", async (t) => {
  const messages = [];
  const content = { id: "carousel-1", status: "planned", decision: { content: { slides: [] }, campaign: { id: "campaign-1" } } };
  const cmo = {
    ideaDecision: async () => ({ action: "idea_reviewed" }),
    repository: {
      contentById: async () => structuredClone(content),
      updateContent: async (_id, patch) => ({ ...content, ...patch }),
    },
    approvalSheet: { markIdeaDecision: async (_entry, message) => messages.push(message) },
    sync: async () => ({ campaign: { id: "campaign-1" } }),
    execute: async () => ({ action: "item_qa_failed_pending_content_review", reason: "Replace pseudo UI" }),
    campaigns: {},
  };
  const app = buildApp({
    config,
    orchestrator: fakeOrchestrator(),
    cmo,
    captureIngestor: { importApprovedPlan: async () => ({ captures: [], images: [] }) },
    logger: false,
  });
  t.after(() => app.close());

  const response = await app.inject({
    method: "POST",
    url: "/v1/cmo/approve-import-and-start",
    headers: { "x-marketing-token": config.MARKETING_INTERNAL_TOKEN },
    payload: { action: "idea_decision", entry: { ideaId: "carousel-1", campaignId: "campaign-1", version: 1, decision: "Approve" } },
  });

  assert.equal(response.statusCode, 200);
  assert.equal(response.json().action, "idea_approved_qa_failed");
  assert.equal(response.json().qa_failed, true);
  assert.match(messages[0], /needs Content Review revision.*Replace pseudo UI/);
});

test("automatic idea approval records production failures as Approved - Blocked", async (t) => {
  const updates = [];
  const messages = [];
  const content = { id: "video-budget", status: "generating", decision: { content: { scenes: [] }, campaign: { id: "campaign-1" } } };
  const cmo = {
    ideaDecision: async () => ({ action: "idea_reviewed" }),
    repository: {
      contentById: async () => structuredClone(content),
      updateContent: async (_id, patch) => { updates.push(patch); return { ...content, ...patch }; },
    },
    approvalSheet: { markIdeaDecision: async (_entry, message) => messages.push(message) },
    sync: async () => ({ campaign: { id: "campaign-1" } }),
    execute: async () => { throw new Error("fal provider budget exceeded"); },
    campaigns: {},
  };
  const app = buildApp({
    config,
    orchestrator: fakeOrchestrator(),
    cmo,
    captureIngestor: { importApprovedPlan: async () => ({ captures: [{ sha256: "abc" }], images: [] }) },
    logger: false,
  });
  t.after(() => app.close());

  const response = await app.inject({
    method: "POST",
    url: "/v1/cmo/approve-import-and-start",
    headers: { "x-marketing-token": config.MARKETING_INTERNAL_TOKEN },
    payload: { action: "idea_decision", entry: { ideaId: content.id, campaignId: "campaign-1", version: 1, decision: "Approve" } },
  });

  assert.equal(response.statusCode, 200);
  assert.equal(response.json().action, "idea_approved_blocked");
  assert.match(messages[0], /Approved - Blocked.*budget exceeded/);
  assert.equal(updates.at(-1).decision.campaign.production_blocked, true);
});
