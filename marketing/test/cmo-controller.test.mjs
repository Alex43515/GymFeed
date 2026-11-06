import test from "node:test";
import assert from "node:assert/strict";
import { CmoController, normalizeReview, ideaForSheet } from "../src/cmo-controller.mjs";
import { campaignSchedule } from "../src/campaign-schedule.mjs";
import { preflightAppCaptures } from "../src/app-captures.mjs";

test("an assembly exception records failed state and retains paid source clips", async () => {
  let content={id:"v",content_type:"video",content_key:"GF-test",status:"generating",decision:{content:{scenes:[]},generation:{scenes:[{scene_id:"one",asset_url:"paid.mp4"}]},campaign:{id:"c"}}};
  const cmo=new CmoController({campaigns:{status:async()=>({batches:[{id:"b",manifest:[{content_id:"v"}]}],ideas:[{content_id:"v",content}]}),assertGenerationAllowed:async()=>{}},
    repository:{contentById:async()=>structuredClone(content),updateContent:async(_id,patch)=>(content={...content,...structuredClone(patch)})},orchestrator:{humanReviewOnly:true}});
  cmo.sync=async()=>({});cmo.produceWithStoryRepair=async()=>{throw Error("audio/mpeg upload failed (415)");};
  await assert.rejects(cmo.produce("c","b"),/audio\/mpeg/);
  assert.equal(content.status,"failed");
  assert.equal(content.decision.generation.scenes[0].asset_url,"paid.mp4");
  assert.match(content.decision.workflow.message,/Generation stopped.*nothing is currently assembling/);
});

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

test("parallel item starts in one campaign are isolated by content ID", async () => {
  const started = [];
  const cmo = new CmoController({ campaigns: {
    startItem: async ({ contentId }) => { started.push(contentId); return { batch: { id: `batch-${contentId}` } }; },
  } });
  cmo.produce = async (_campaignId, batchId) => ({ batchId });

  const [first, second] = await Promise.all([
    cmo.execute({ action: "start_item", campaignId: "c", contentId: "a", requestKey: "item-a" }),
    cmo.execute({ action: "start_item", campaignId: "c", contentId: "b", requestKey: "item-b" }),
  ]);

  assert.deepEqual(started.sort(), ["a", "b"]);
  assert.equal(first.batchId, "batch-a");
  assert.equal(second.batchId, "batch-b");
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

test("decision polling exposes interrupted generation without retrying it", async () => {
  const calls = [];
  const cmo = new CmoController({
    repository: {
      reconcileInterruptedGeneration: async (startedAt) => {
        calls.push(["reconcile", startedAt]);
        return { content_ids: ["v"], campaign_ids: ["c"] };
      },
    },
    approvalSheet: {
      configured: true,
      markInterruptedIdea: async (contentId, message) => calls.push(["mark-interrupted", contentId, message]),
      pendingIdeaDecisions: async () => [],
      pendingDecisions: async () => [],
    },
  });
  cmo.sync = async (campaignId) => calls.push(["sync", campaignId]);

  assert.deepEqual(await cmo.decisions(), { actions: [] });
  assert.equal(calls[0][0], "reconcile");
  assert.match(calls[0][1], /^\d{4}-\d{2}-\d{2}T/);
  assert.equal(calls[1][0], "mark-interrupted");
  assert.equal(calls[1][1], "v");
  assert.match(calls[1][2], /Select Approve again/);
  assert.deepEqual(calls[2], ["sync", "c"]);
});

test("polling recovers old interrupted revisions using their claim token", async () => {
  const recovered = [];
  const cmo = new CmoController({
    repository: { interruptedIdeaRevisions: async () => [{ campaign_id: "c", content_id: "v", revision: 1, revision_token: "token" }] },
    campaigns: { failIdeaRevision: async (claim) => recovered.push(claim) },
    approvalSheet: { configured: true, pendingIdeaDecisions: async () => [], pendingDecisions: async () => [] },
  });
  cmo.sync = async () => {};
  await cmo.decisions();
  assert.equal(recovered[0].token, "token");
  assert.match(recovered[0].error, /instructions are queued/);
});

test("duplicate rejection while revision is running does not issue another decision", async () => {
  const cmo = new CmoController({ campaigns: {
    status: async () => ({ ideas: [{ content_id: "v", revision: 1, idea_status: "revising" }] }),
    decideIdea: async () => { throw new Error("must not issue a duplicate decision"); },
  } });
  const result = await cmo.ideaDecision({ campaignId: "c", ideaId: "v", version: 1, decision: "Reject", instructions: "Change the story", plannedDate: "2026-11-02" });
  assert.equal(result.action, "revision_in_progress");
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
  let approved = false;
  const cmo = new CmoController({
    campaigns: {
      rescheduleIdea: async (input) => { calls.push({ reschedule: input }); },
      status: async () => ({ ideas: [{
        content_id: "v", revision: 2, idea_status: approved ? "approved" : "pending",
        approved_revision: approved ? 2 : null, approved_plan_hash: approved ? "plan" : null,
        approved_at: approved ? "2026-10-03T18:35:00Z" : null, updated_at: "2026-10-03T18:31:00Z",
      }] }),
      decideIdea: async (input) => { calls.push({ decision: input }); approved = true; return { approved: true }; },
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
  assert.equal(calls[1].decision.requestKey, "idea:v:2:f:2026-10-03T18:31:00Z");
  assert.deepEqual(calls[2], { campaignId: "c", contentId: "v", requestKey: "item:v:2:2026-10-03T18:35:00Z" });
  assert.equal(result.production.batchId, "one-item-batch");
  assert.match(calls[3].message, /generation started/i);
});

test("a Content Review approval for a capture-blocked replacement dispatches intake, not publication", async () => {
  const entry = { contentId: "v", revision: 2, decision: "Approve", currentStatus: "planned", contentUpdatedAt: "old" };
  const retry = { ideaId: "v", campaignId: "c", version: 2, decision: "Approve" };
  const cmo = new CmoController({
    repository: { contentById: async () => ({ id: "v", status: "planned", updated_at: "new", asset_urls: [], decision: {
      review_revision: 2, campaign: { id: "c", production_blocked: true, production_block_kind: "capture" },
    } }) },
    approvalSheet: { configured: true, pendingIdeaDecisions: async () => [], pendingDecisions: async () => [entry], ideaApprovalForContent: async () => ({ ...retry }) },
  });
  const result = await cmo.decisions();
  assert.equal(result.actions.length, 1);
  assert.equal(result.actions[0].action, "idea_decision");
  assert.equal(result.actions[0].entry.ideaId, "v");
  assert.deepEqual(result.actions[0].entry.sourceContentReview, entry);
});

test("blocked and intake replacements remain visible to Content Review sync", async () => {
  const contents = ["blocked", "intake"].map((stage) => ({ id: stage, status: "planned", decision: { review_revision: 2, workflow: { stage } } }));
  let synced;
  const cmo = new CmoController({
    repository: {},
    campaigns: { status: async () => ({ ideas: contents.map((content) => ({ content })) }) },
    approvalSheet: { configured: true, syncContent: async (items) => { synced = items; }, syncIdeas: async () => {} },
  });
  // This test exercises selection, not full idea-card construction.
  for (const content of contents) content.decision.content = { scenes: [] };
  await cmo.sync("c");
  assert.deepEqual(synced, contents);
});

test("approving a revised idea with an unchanged planned date skips the locked reschedule", async () => {
  const calls = [];
  let approved = false;
  const cmo = new CmoController({
    campaigns: {
      rescheduleIdea: async (input) => { calls.push({ reschedule: input }); },
      status: async () => ({ ideas: [{
        content_id: "v", revision: 2, idea_status: approved ? "approved" : "pending",
        approved_revision: approved ? 2 : null, approved_plan_hash: approved ? "plan" : null,
        approved_at: approved ? "2026-10-03T18:35:00Z" : null, updated_at: "2026-10-03T18:31:00Z",
      }] }),
      decideIdea: async (input) => { calls.push({ decision: input }); approved = true; return { approved: true }; },
      startItem: async (input) => { calls.push({ start: input }); return { batch: { id: "replacement-batch" } }; },
    },
    approvalSheet: { markIdeaDecision: async () => {} },
  });
  cmo.produce = async () => ({ pending: false });
  cmo.sync = async () => ({ campaign: { id: "c" } });

  await cmo.ideaDecision({
    campaignId: "c", ideaId: "v", version: 2, decision: "Approve", instructions: "",
    fingerprint: "f", plannedDate: "2026-10-03", storedPlannedDate: "2026-10-03",
  });

  assert.equal(calls.some((call) => call.reschedule), false);
  assert.equal(calls[0].decision.revision, 2);
  assert.equal(calls[1].start.requestKey, "item:v:2:2026-10-03T18:35:00Z");
});

test("re-approving a reset idea uses the reset state as a new decision cycle", async () => {
  const calls = [];
  let approved = false;
  const cmo = new CmoController({
    campaigns: {
      status: async () => ({ ideas: [{
        content_id: "v", revision: 1, idea_status: approved ? "approved" : "pending",
        approved_revision: approved ? 1 : null, approved_plan_hash: approved ? "plan" : null,
        approved_at: approved ? "2026-10-03T18:35:39Z" : null,
        updated_at: "2026-10-03T18:31:42Z",
      }] }),
      decideIdea: async (input) => { calls.push(input); approved = true; return { idea_status: "approved" }; },
    },
    approvalSheet: { markIdeaDecision: async () => {} },
  });
  cmo.sync = async () => ({ campaign: { id: "c" } });

  const result = await cmo.ideaDecision({
    campaignId: "c", ideaId: "v", version: 1, decision: "Approve", instructions: "",
    fingerprint: "same-sheet-fingerprint", plannedDate: "2026-10-04", storedPlannedDate: "2026-10-04",
  }, { deferProduction: true });

  assert.equal(calls[0].requestKey, "idea:v:1:same-sheet-fingerprint:2026-10-03T18:31:42Z");
  assert.equal(result.approvalCycle, "2026-10-03T18:35:39Z");
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
  cmo.progress = async (_contentId, stage, message) => calls.push({ stage, progressMessage: message });
  cmo.produce = async (campaignId, batchId) => ({ campaignId, batchId });
  cmo.sync = async () => ({ campaign: { id: "c" } });
  const result = await cmo.assetDecision({ contentId: "v", revision: 1, decision: "reject", instructions: "Demonstrate Train" });
  assert.equal(result.action, "asset_replaced_pending_review");
  assert.equal(result.revision, 2);
  assert.equal(calls.filter((call) => call.decision === "reject").length, 1);
  assert.equal(calls.filter((call) => call.decision === "approve").length, 1);
  assert.match(calls.find((call) => call.message)?.message, /Astra is rewriting/);
  assert.match(calls.find((call) => /replacement revision/i.test(call.message ?? ""))?.message, /being generated/);
  assert.deepEqual(calls.filter((call) => call.stage).map((call) => call.stage), ["revising", "generating"]);
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

test("capture preflight requires a recording but fits an imperfect window instead of blocking", async () => {
  await assert.rejects(preflightAppCaptures({ production_version: 2, scenes: [] }), /requires a verified/);
  await assert.doesNotReject(preflightAppCaptures({ scenes: [{ asset_type: "app_capture", capture_ref: "train", source_start_seconds: 2, duration_seconds: 4 }] }, async () => ({ duration_seconds: 3 })));
  await assert.rejects(preflightAppCaptures({ scenes: [{ asset_type: "app_capture", capture_ref: "missing", duration_seconds: 4 }] }, async () => { throw new Error("Missing verified app recording: missing"); }), /Missing verified/);
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

test("idea board shows the real revision failure instead of leaving the row rejected", () => {
  const item = ideaForSheet({
    revision: 1, idea_status: "rejected", revision_error: "openai provider budget exceeded", publication_date: "2026-10-01",
    content: {
      id: "v", status: "planned", content_type: "video",
      decision: { content: { topic: "Nutrition", scenes: [] }, research: {}, campaign: { id: "c" } },
    },
  });
  assert.equal(item.status, "Revision Failed");
  assert.match(item.progress_message, /openai provider budget exceeded/);
  assert.match(item.progress_message, /instructions were saved/);
});

test("a completed revision does not display an error from its previous attempt", () => {
  const row = ideaForSheet({ revision: 2, idea_status: "pending", revision_error: null,
    content: { id: "v", content_type: "video", status: "planned", decision: {
      content: { topic: "Story", scenes: [] },
      workflow: { stage: "blocked", message: "Revision failed: previous attempt" },
    } },
  });
  assert.match(row.progress_message, /ready for review/);
  assert.equal(row.status, "Pending");
});

test("idea board sends completed low-QA media to Content Review instead of implying generation stopped", () => {
  const row = ideaForSheet({
    campaign_id: "c", revision: 1, idea_status: "approved", approved_revision: 1,
    content: {
      id: "v", status: "qa_failed", content_type: "video", asset_urls: ["review.mp4"],
      decision: { content: { scenes: [] }, campaign: { id: "c" } },
    },
  });
  assert.equal(row.status, "Ready in Content Review");
});
