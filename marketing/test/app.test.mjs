import test from "node:test";
import assert from "node:assert/strict";
import { buildApp } from "../src/app.mjs";

const config = {
  MARKETING_INTERNAL_TOKEN: "internal-token",
  MARKETING_APPROVAL_TOKEN: "approval-token",
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
