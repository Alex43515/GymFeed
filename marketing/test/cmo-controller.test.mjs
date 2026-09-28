import test from "node:test";
import assert from "node:assert/strict";
import { CmoController, normalizeReview, ideaForSheet } from "../src/cmo-controller.mjs";
import { campaignSchedule } from "../src/campaign-schedule.mjs";
import { preflightAppCaptures } from "../src/app-captures.mjs";

test("review decisions normalize before branching and reject invalid/missing instructions", () => {
  assert.equal(normalizeReview({ decision: " reject ", revision: 1, instructions: "Show the actual app" }, "asset").decision, "Reject");
  assert.equal(normalizeReview({ decision: "Approve", version: 1, plannedDate: "2026-10-01" }, "idea").plannedDate, "2026-10-01");
  for (const decision of ["Pending", "", "publish"]) assert.throws(() => normalizeReview({ decision, revision: 1 }, "asset"));
  assert.throws(() => normalizeReview({ decision: "Reject", revision: 1, instructions: "" }, "asset"));
  assert.throws(() => normalizeReview({ decision: "Approve", revision: "1" }, "asset"));
  assert.throws(() => normalizeReview({ decision: "Approve", version: 1, plannedDate: "10/01/2026" }, "idea"), /YYYY-MM-DD/);
});

test("status is read-only and never syncs or generates", async () => {
  const cmo = new CmoController({ campaigns: { status: async () => ({ campaign: { id: "c" } }) } });
  cmo.sync = () => { throw new Error("unexpected write"); };
  assert.equal((await cmo.execute({ action: "status", campaignId: "c" })).campaign.id, "c");
});

test("planning registers each day and stops at idea review without any media", async () => {
  const calls = [];
  const campaign = { id: "c", status: "planning", start_date: "2026-10-01", days: 2 };
  const cmo = new CmoController({ config: {}, campaigns: {
    create: async () => ({ campaign }), status: async () => ({ campaign, ideas: [], batches: [] }),
    registerDay: async (input) => calls.push(input), submit: async () => { campaign.status = "idea_review"; },
  }, orchestrator: { runDaily: async (date, options) => { assert.equal(options.campaignId, "c"); return { content: [{ id: date.toISOString() + "v" }, { id: date.toISOString() + "i" }] }; } } });
  const result = await cmo.execute({ action: "plan_campaign", name: "October", startDate: "2026-10-01", days: 2, requestKey: "one" });
  assert.equal(calls.length, 2);
  assert.equal(calls[1].date, "2026-10-02");
  assert.equal(result.campaign.status, "idea_review");
});

test("all-complete start never produces another batch", async () => {
  const cmo = new CmoController({ campaigns: { startBatch: async () => ({ complete: true }) } });
  cmo.produce = () => { throw new Error("unexpected media"); };
  assert.equal((await cmo.execute({ action: "start_batch", campaignId: "c", requestKey: "last" })).complete, true);
});

test("sync refreshes review rows without planning or generation", async () => {
  const cmo = new CmoController({ campaigns: {} });
  cmo.sync = async (campaignId) => ({ campaign: { id: campaignId }, synced: true });
  assert.equal((await cmo.execute({ action: "sync", campaignId: "c" })).synced, true);
});

test("individual idea approvals dispatch without waiting for other campaign ideas", async () => {
  const cmo = new CmoController({
    approvalSheet: {
      configured: true,
      pendingIdeaDecisions: async () => [{ campaignId: "c", ideaId: "v", version: 1, decision: "Approve" }],
      pendingDecisions: async () => [],
    },
  });

  assert.deepEqual(await cmo.decisions(), {
    actions: [{ action: "idea_decision", entry: { campaignId: "c", ideaId: "v", version: 1, decision: "Approve" } }],
  });
});

test("failed QA approvals dispatch repair while stale assets are refreshed first", async () => {
  const blocked = [];
  const content = {
    id: "asset-1", status: "qa_failed", updated_at: "2026-09-26T13:00:00Z",
    qa_score: 69, failure_reason: "Product proof does not match the approved story",
    decision: { review_revision: 1, campaign: { id: "c" } },
  };
  const approvalSheet = {
    configured: true,
    pendingIdeaDecisions: async () => [],
    pendingDecisions: async () => [{
      contentId: "asset-1", revision: 1, decision: "Approve",
      currentStatus: "qa_failed", contentUpdatedAt: "2026-09-26T13:00:00Z",
    }],
    markContentDecision: async (_entry, result) => blocked.push(result),
  };
  const cmo = new CmoController({ approvalSheet, repository: { contentById: async () => content } });
  cmo.sync = async () => {};

  assert.equal((await cmo.decisions()).actions[0].action, "asset_decision");
  assert.deepEqual(blocked, []);

  content.status = "awaiting_approval";
  content.updated_at = "2026-09-26T14:00:00Z";
  assert.deepEqual(await cmo.decisions(), { actions: [] });

  approvalSheet.pendingDecisions = async () => [{
    contentId: "asset-1", revision: 1, decision: "Approve",
    currentStatus: "awaiting_approval", contentUpdatedAt: "2026-09-26T14:00:00Z",
  }];
  assert.equal((await cmo.decisions()).actions[0].action, "asset_decision");
});

test("approving one idea starts production for only that item", async () => {
  const calls = [];
  const cmo = new CmoController({
    campaigns: {
      rescheduleIdea: async (input) => { calls.push({ reschedule: input }); },
      decideIdea: async () => ({ approved: true }),
      startItem: async (input) => { calls.push(input); return { batch: { id: "one-item-batch" } }; },
    },
    approvalSheet: { markIdeaDecision: async (_entry, message) => calls.push({ message }) },
  });
  cmo.produce = async (campaignId, batchId) => ({ campaignId, batchId });
  cmo.sync = async () => ({ campaign: { id: "c" } });
  const result = await cmo.ideaDecision({
    campaignId: "c", ideaId: "v", version: 2, decision: "Approve", instructions: "", fingerprint: "f", plannedDate: "2026-10-09",
  });
  assert.deepEqual(calls[0], { reschedule: { campaignId: "c", contentId: "v", revision: 2, date: "2026-10-09" } });
  assert.deepEqual(calls[1], { campaignId: "c", contentId: "v", requestKey: "item:v:2" });
  assert.equal(result.production.batchId, "one-item-batch");
  assert.match(calls[2].message, /generation started/i);
});

test("whole-batch preflight catches missing capture before first carousel or video generation", async () => {
  let produced = 0;
  const cmo = new CmoController({ campaigns: {
    status: async () => ({ batches: [{ id: "b", manifest: [{ content_id: "i" }, { content_id: "v" }] }], ideas: [
      { content_id: "i", content: { id: "i", content_type: "carousel", decision: { content: {} } } },
      { content_id: "v", content: { id: "v", content_type: "video", decision: { content: { production_version: 2, scenes: [{ scene_id: "proof", asset_type: "app_capture", capture_ref: "requested:train", duration_seconds: 4 }] } } } },
    ] }), assertGenerationAllowed: async () => true,
  }, orchestrator: { appCaptureResolver: async () => { throw new Error("Missing verified app recording"); }, processContentToReview: async () => { produced++; } } });
  await assert.rejects(cmo.produce("c", "b"), /Missing verified/);
  assert.equal(produced, 0);
});

test("asset rejection revises, re-approves, and regenerates only the rejected item", async () => {
  const calls = [];
  const content = { id: "v", status: "awaiting_approval", decision: { review_revision: 1, campaign: { id: "c", batch_id: "b", idea_revision: 1 } } };
  let ideaStatus = "approved";
  let ideaRevision = 1;
  const cmo = new CmoController({ config: {}, repository: {
    contentById: async () => content,
    createContentReview: async () => ({ review: { id: "r", status: "pending" }, reused: false }),
    finishContentReview: async (_id, status, payload) => calls.push({ finish: status, payload }),
  }, campaigns: {
    decideIdea: async (input) => { calls.push(input); ideaStatus = input.decision === "reject" ? "rejected" : "approved"; },
    status: async () => ({ campaign: { id: "c" }, batches: [], ideas: [{ content_id: "v", idea_status: ideaStatus, revision: ideaRevision, content }] }),
    startItem: async (input) => { calls.push(input); return { batch: { id: "b" } }; },
  }, approvalSheet: {
    markContentDecision: async (_entry, message) => calls.push({ message }),
  }, orchestrator: { approveContent: () => { throw new Error("unexpected approval"); } } });
  cmo.reviseIdea = async () => {
    ideaRevision = 2;
    ideaStatus = "pending";
    content.status = "planned";
    content.decision.review_revision = 2;
    content.decision.campaign.idea_revision = 2;
  };
  cmo.produce = async (campaignId, batchId) => ({ campaignId, batchId });
  cmo.sync = async () => ({ campaign: { id: "c" } });
  const result = await cmo.assetDecision({ contentId: "v", revision: 1, decision: "reject", instructions: "Demonstrate Train" });
  assert.equal(result.action, "asset_replaced_pending_review");
  assert.equal(result.revision, 2);
  assert.equal(calls.filter((call) => call.decision === "reject").length, 1);
  assert.equal(calls.filter((call) => call.decision === "approve").length, 1);
  assert.match(calls.find((call) => call.message)?.message, /replacement is being generated/);
});

test("a controlled QA failure updates review state without failing the n8n request", async () => {
  const failed = { id: "i", content_type: "carousel", status: "qa_failed", failure_reason: "Replace pseudo UI", decision: { campaign: { id: "c" } } };
  const state = {
    campaign: { id: "c" },
    batches: [{ id: "b", manifest: [{ content_id: "i" }] }],
    ideas: [{ content_id: "i", content: { id: "i", content_type: "carousel", status: "planned", decision: { content: {} } } }],
  };
  const cmo = new CmoController({ repository: {
    contentById: async () => failed,
    updateContent: async (_id, patch) => Object.assign(failed, patch),
  }, campaigns: {
    status: async () => state,
    assertGenerationAllowed: async () => true,
    withWork: async () => ({ skipped: false, pending: false, passed: false, content: failed }),
  }, orchestrator: { processContentToReview: async () => { throw new Error("withWork should own execution"); } } });
  cmo.sync = async () => state;

  const result = await cmo.produce("c", "b");

  assert.equal(result.action, "item_qa_failed_pending_content_review");
  assert.equal(result.reason, "Replace pseudo UI");
  assert.equal(result.contentId, "i");
});

test("processed approval retries batch release without repeating approval", async () => {
  let released = 0;
  const cmo = new CmoController({ repository: {
    contentById: async () => ({ id: "v", decision: { campaign: { id: "c", batch_id: "b" } } }),
    createContentReview: async () => ({ reused: true, review: { status: "processed", decision: "approve", result: {} } }),
  } });
  cmo.releaseItem = async () => { released++; return {}; };
  await cmo.assetDecision({ contentId: "v", revision: 1, decision: "Approve" });
  assert.equal(released, 1);
});

test("release waits for every finished asset, not merely approved ideas", async () => {
  const cmo = new CmoController({ campaigns: { status: async () => ({ batches: [{ id: "b", manifest: [{ content_id: "a" }, { content_id: "b" }] }], ideas: [{ content_id: "a", content: { status: "approved" } }, { content_id: "b", content: { status: "awaiting_approval" } }] }) } });
  cmo.release = () => { throw new Error("premature Buffer submission"); };
  assert.equal((await cmo.releaseIfReady("c", "b")).pending, true);
});

test("campaign schedule uses campaign timezone across daylight saving, not workstation clock", () => {
  assert.equal(campaignSchedule("2026-10-01", "America/New_York", 18), "2026-10-01T22:00:00.000Z");
  assert.equal(campaignSchedule("2026-12-01", "America/New_York", 18), "2026-12-01T23:00:00.000Z");
  assert.equal(campaignSchedule("2026-10-01", "Europe/Belgrade", 12), "2026-10-01T10:00:00.000Z");
});

test("capture preflight never permits a short recording or screenshot-only V2 video", async () => {
  await assert.rejects(preflightAppCaptures({ production_version: 2, scenes: [] }), /requires a verified/);
  await assert.rejects(preflightAppCaptures({ scenes: [{ asset_type: "app_capture", capture_ref: "train", source_start_seconds: 2, duration_seconds: 4 }] }, async () => ({ duration_seconds: 3 })), /too short/);
});

test("idea board exposes the exact production prompt, source gaps, and cost components", () => {
  const idea = ideaForSheet({ revision: 1, publication_date: "2026-10-01", content: { id: "v", content_type: "video", decision: { content: { topic: "Train", hook: "Now what?", concept: "Open the plan", scenes: [{ scene_id: "proof", asset_type: "app_capture", capture_ref: "train-open", source_start_seconds: 1, duration_seconds: 2, overlay_text: "Start today's routine" }] }, research: { trends: [], gaps: ["No attributed conversions"] } } } });
  assert.deepEqual(idea.brief.evidence.gaps, ["No attributed conversions"]);
  assert.deepEqual(idea.brief.evidence.trends, []);
  assert.match(idea.brief.generation_prompt, /Use verified recording train-open/);
  assert.match(idea.brief.generation_prompt, /Do not generate or simulate/);
});

test("idea board carries the approved revision into blocked review rows", () => {
  const item = ideaForSheet({
    revision: 2, approved_revision: 2, idea_status: "approved", publication_date: "2026-10-01",
    content: {
      id: "v", content_type: "video",
      decision: {
        content: { topic: "Scan food", scenes: [] }, research: {},
        campaign: { id: "c", production_block_reason: "Required Drive video is missing: proof.mp4" },
      },
    },
  });
  assert.equal(item.status, "Approved - Blocked");
  assert.equal(item.approved_version, 2);
});
