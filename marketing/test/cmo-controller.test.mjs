import test from "node:test";
import assert from "node:assert/strict";
import { CmoController, normalizeReview, ideaForSheet } from "../src/cmo-controller.mjs";
import { campaignSchedule } from "../src/campaign-schedule.mjs";
import { preflightAppCaptures } from "../src/app-captures.mjs";

test("review decisions normalize before branching and reject invalid/missing instructions", () => {
  assert.equal(normalizeReview({ decision: " reject ", revision: 1, instructions: "Show the actual app" }, "asset").decision, "Reject");
  for (const decision of ["Pending", "", "publish"]) assert.throws(() => normalizeReview({ decision, revision: 1 }, "asset"));
  assert.throws(() => normalizeReview({ decision: "Reject", revision: 1, instructions: "" }, "asset"));
  assert.throws(() => normalizeReview({ decision: "Approve", revision: "1" }, "asset"));
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

test("lowercase asset rejection never enters approval or Buffer", async () => {
  let revised = 0;
  const content = { id: "v", decision: { review_revision: 1, campaign: { id: "c", idea_revision: 1 } } };
  const cmo = new CmoController({ config: {}, repository: {
    contentById: async () => content,
    createContentReview: async () => ({ review: { id: "r", status: "pending" }, reused: false }),
    finishContentReview: async () => {},
  }, campaigns: { decideIdea: async () => {} }, approvalSheet: { markContentDecision: async () => {} }, orchestrator: { approveContent: () => { throw new Error("unexpected approval"); } } });
  cmo.reviseIdea = async () => { revised++; };
  cmo.sync = async () => {};
  const result = await cmo.assetDecision({ contentId: "v", revision: 1, decision: "reject", instructions: "Demonstrate Train" });
  assert.equal(result.action, "revised_idea_requires_approval");
  assert.equal(revised, 1);
});

test("processed approval retries batch release without repeating approval", async () => {
  let released = 0;
  const cmo = new CmoController({ repository: {
    contentById: async () => ({ id: "v", decision: { campaign: { id: "c", batch_id: "b" } } }),
    createContentReview: async () => ({ reused: true, review: { status: "processed", decision: "approve", result: {} } }),
  } });
  cmo.releaseIfReady = async () => { released++; return {}; };
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

test("idea board exposes source gaps and cost components without inventing conversion evidence", () => {
  const idea = ideaForSheet({ revision: 1, publication_date: "2026-10-01", content: { id: "v", content_type: "video", decision: { content: { topic: "Train", hook: "Now what?", concept: "Open the plan", scenes: [] }, research: { trends: [], gaps: ["No attributed conversions"] } } } });
  assert.deepEqual(idea.brief.evidence.gaps, ["No attributed conversions"]);
  assert.deepEqual(idea.brief.evidence.trends, []);
});
