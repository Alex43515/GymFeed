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
