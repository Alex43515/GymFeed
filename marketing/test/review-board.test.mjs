import test from "node:test";
import assert from "node:assert/strict";
import { ReviewBoard, IDEA_HEADERS, CONTENT_HEADERS, contentPresentation, fingerprint } from "../src/providers/review-board.mjs";
import { CmoController } from "../src/cmo-controller.mjs";
import { buildApp } from "../src/app.mjs";

function board(content = [], ideas = []) {
  const queue = new ReviewBoard({ spreadsheetId: "test", auth: {} });
  queue.readBoard = async (name) => structuredClone(name === "Idea Review" ? ideas : content);
  queue.writeMany = async (name, _headers, updates) => {
    const rows = name === "Idea Review" ? ideas : content;
    for (const { rowNumber, values } of updates) Object.assign(rows.find((r) => r.rowNumber === rowNumber), values);
  };
  queue.writeFields = async (name, _headers, rowNumber, fields) => {
    const rows = name === "Idea Review" ? ideas : content;
    Object.assign(rows.find((row) => row.rowNumber === rowNumber), fields);
  };
  queue.appendBoard = async (name, _headers, rows) => (name === "Idea Review" ? ideas : content).push(...rows);
  return queue;
}
function contentRow(overrides = {}) {
  return { rowNumber: 24, "Content ID": "v", Revision: "2", Decision: "Pending", "Content type": "video", "Pipeline state": "qa_failed", "Updated at": "now", "Revision instructions": "", "QA score": "62", "AI QA score": "62", ...overrides };
}

test("review board puts actions, failures, scores and media first; planned date is G in Idea Review", () => {
  assert.deepEqual(CONTENT_HEADERS.slice(0, 6), ["Decision", "Current status", "Reason / next step", "QA score", "Preview", "Asset 1"]);
  assert.equal(IDEA_HEADERS[6], "Planned date");
  assert.ok(CONTENT_HEADERS.indexOf("Content ID") > 20);
});

test("a planned replacement reports blocked or intake rather than stale generating", () => {
  const content = { status: "planned", decision: { workflow: { stage: "blocked", message: "Required Drive video is missing" } } };
  assert.equal(contentPresentation(content).status, "Approved - Blocked");
  content.decision.workflow = { stage: "intake", message: "Checking Drive" };
  assert.equal(contentPresentation(content).status, "Pending");
});

test("blocked assembly never presents a stale generating database status as active work", () => {
  const view=contentPresentation({status:"generating",failure_reason:"InvalidMimeType",decision:{workflow:{stage:"blocked",message:"Audio upload failed: InvalidMimeType"}}});
  assert.equal(view.status,"Needs Review");
  assert.match(view.reason,/Audio upload failed/);
});

test("retrying unfinished media consumes Approve without authorizing publication", async () => {
  const rows = [contentRow({ Decision: "Approve", "Revision instructions": "Keep my revision", "Planned date": "2026-10-22" })];
  const queue = board(rows);
  assert.deepEqual(await queue.markContentGenerationRetry({ contentId: "v", revision: 2, instructions: "Keep my revision" }, "Checking Drive"), { marked: true });
  assert.equal(rows[0].Decision, "Pending");
  assert.equal(rows[0]["Current status"], "Pending");
  assert.equal(rows[0]["Revision instructions"], "Keep my revision");
  assert.equal(rows[0]["Planned date"], "2026-10-22");
  assert.equal(rows[0]["QA score"], "62");
  assert.deepEqual(await queue.markContentGenerationRetry({ contentId: "v", revision: 2 }, "Duplicate"), { marked: false });
});

test("changing QA to 90 submits a manual override even without changing decision", async () => {
  const rows = [contentRow({ "QA score": "90" })];
  const queue = board(rows);
  const [entry] = await queue.pendingDecisions();
  assert.equal(entry.decision, "Approve");
  assert.equal(entry.qaOverride, 90);
  assert.equal(entry.revision, 2);
  rows[0]["Processed decision fingerprint"] = entry.fingerprint;
  assert.deepEqual(await queue.pendingDecisions(), []);
  rows[0].Decision = "Reject";
  assert.equal((await queue.pendingDecisions())[0].decision, "Reject");
});

test("failed QA resets approval and displays the reason on the same row", async () => {
  const rows = [contentRow({ Decision: "Approve", "Pipeline state": "generating", "Asset 1": "" })];
  await board(rows).syncContent([{ id: "v", status: "qa_failed", content_type: "video", qa_score: 62, failure_reason: "Wrong app screen", asset_urls: ["video.mp4"], decision: { review_revision: 2, campaign: { date: "2026-10-01" } } }]);
  assert.equal(rows.length, 1);
  assert.equal(rows[0].rowNumber, 24);
  assert.equal(rows[0].Decision, "Needs Review");
  assert.match(rows[0]["Reason / next step"], /Wrong app screen/);
  assert.equal(rows[0]["Buffer status"], "Not submitted");
});

test("concurrent content syncs keep one row per content revision", async () => {
  const rows = [];
  const queue = board(rows);
  const content = { id: "v", status: "generating", content_type: "video", asset_urls: [], decision: { review_revision: 1 } };

  await Promise.all([queue.syncContent([content]), queue.syncContent([content])]);

  assert.equal(rows.length, 1);
  assert.equal(rows[0]["Content ID"], "v");
  assert.equal(rows[0].Revision, 1);
});

test("sync preserves a manual QA edit until the reviewed media changes", async () => {
  const rows = [contentRow({ "QA score": "90", "Asset 1": "a.mp4" })];
  const queue = board(rows);
  const content = { id: "v", status: "qa_failed", content_type: "video", qa_score: 62, asset_urls: ["a.mp4"], decision: { review_revision: 2 } };
  await queue.syncContent([content]);
  assert.equal(rows[0]["QA score"], "90");
  await queue.syncContent([{ ...content, asset_urls: ["b.mp4"] }]);
  assert.equal(rows[0]["QA score"], 62);
  assert.equal(rows[0].Decision, "Needs Review");
});

test("blocked upload retries automatically but failed paid production does not loop", async () => {
  const entry = { ideaId: "v", version: 1, decision: "Approve", instructions: "", plannedDate: "2026-10-01" };
  const rows = [{ rowNumber: 24, "Idea ID": "v", "Campaign ID": "c", Version: "1", "Idea decision": "Approve", "Revision instructions": "", "Planned date": "2026-10-01", "Current status": "Approved - Blocked", "Block kind": "capture", "Processed decision fingerprint": fingerprint(entry) }];
  const queue = board([], rows);
  assert.equal((await queue.pendingIdeaDecisions()).length, 1);
  rows[0]["Block kind"] = "production";
  assert.equal((await queue.pendingIdeaDecisions()).length, 0);
});

test("interrupted generation clears the consumed idea approval", async () => {
  const rows = [{
    rowNumber: 33, "Idea ID": "v", "Campaign ID": "c", Version: "1", "Idea decision": "Approve",
    "Revision instructions": "", "Planned date": "2026-10-04", "Current status": "Needs Review",
    "Processed decision fingerprint": "old",
  }];
  const queue = board([], rows);

  await queue.markInterruptedIdea("v", "Generation failed; nothing is currently generating.", "now");

  assert.equal(rows[0]["Idea decision"], "Pending");
  assert.equal(rows[0]["Current status"], "Pending");
  assert.equal(rows[0]["Processed decision fingerprint"], "");
  assert.match(rows[0]["Reason / next step"], /nothing is currently generating/);
  assert.deepEqual(await queue.pendingIdeaDecisions(), []);
});

test("idea status points to the exact Content Review row", async () => {
  const content = [{ rowNumber: 34, "Content ID": "v" }];
  const ideas = [{ rowNumber: 33, "Idea ID": "v", Version: "1", "Planned date": "2026-10-04" }];
  await board(content, ideas).syncIdeas([{
    id: "v", version: 1, status: "Ready in Content Review", planned_date: "2026-10-04",
    campaign_id: "c", content_type: "carousel", brief: {},
  }]);
  assert.equal(ideas[0]["Current status"], "Ready in Content Review - row 34");
});

test("a ready idea with a Content Review row does not restart production", async () => {
  const rows = [{
    rowNumber: 33, "Idea ID": "v", "Campaign ID": "c", Version: "1", "Approved version": "1",
    "Idea decision": "Approve", "Revision instructions": "", "Planned date": "2026-10-04",
    "Stored planned date": "2026-10-04", "Current status": "Ready in Content Review - row 34",
    "Processed decision fingerprint": "",
  }];

  assert.deepEqual(await board([], rows).pendingIdeaDecisions(), []);
});

test("production failure resets the idea row for one explicit retry", async () => {
  const ideas = [{
    rowNumber: 39, "Idea ID": "v", "Campaign ID": "c", Version: "1", "Idea decision": "Approve",
    "Revision instructions": "", "Planned date": "2026-10-06", "Stored planned date": "2026-10-06",
    "Current status": "Needs Review", "Approved version": "1", "Processed decision fingerprint": "old",
  }];
  const queue = board([], ideas);
  await queue.markIdeaRetryRequired({ ideaId: "v", version: 1 }, "Generation failed: fal.ai 504. Select Approve again to retry.", "now");
  assert.equal(ideas[0]["Idea decision"], "Pending");
  assert.equal(ideas[0]["Current status"], "Retry Required");
  assert.equal(ideas[0]["Processed decision fingerprint"], "");

  ideas[0]["Idea decision"] = "Approve";
  assert.equal((await queue.pendingIdeaDecisions())[0].ideaId, "v");
});

test("idea decisions carry the stored planned date so unchanged dates do not reschedule", async () => {
  const rows = [{
    rowNumber: 31, "Idea ID": "v", "Campaign ID": "c", Version: "2", "Idea decision": "Approve",
    "Revision instructions": "", "Planned date": "2026-10-03", "Stored planned date": "2026-10-03",
    "Current status": "Pending", "Processed decision fingerprint": "",
  }];
  const queue = board([], rows);
  const [entry] = await queue.pendingIdeaDecisions();
  assert.equal(entry.plannedDate, "2026-10-03");
  assert.equal(entry.storedPlannedDate, "2026-10-03");
});

test("partial Buffer submission is shown as blocked rather than scheduled", () => {
  const result = contentPresentation({ status: "approved", publications: [{ platform: "instagram", provider_request_id: "post1", status: "scheduled" }, { platform: "tiktok", error: "Channel disconnected", status: "failed" }] });
  assert.equal(result.status, "Approved - Blocked");
  assert.match(result.reason, /tiktok: Channel disconnected/);
  assert.match(result.bufferPosts, /post1/);
});

test("manual Workflow 06 checks only existing approved entries and isolates each failure", async (t) => {
  const entries = ["one", "two"].map((id) => ({ ideaId: id, campaignId: "c", decision: "Approve", version: 1 }));
  const seen = [];
  const app = buildApp({ logger: false, config: { MARKETING_INTERNAL_TOKEN: "secret" }, orchestrator: {}, captureIngestor: {}, cmo: {
    approvalSheet: { pendingIdeaDecisions: async () => entries, markIdeaDecision: async () => {} },
    ideaDecision: async (entry) => { seen.push(entry.ideaId); throw new Error("Missing capture"); },
  } });
  t.after(() => app.close());
  const response = await app.inject({ method: "POST", url: "/v1/cmo/approve-import-and-start", headers: { "x-marketing-token": "secret" }, payload: {} });
  assert.equal(response.statusCode, 200);
  assert.deepEqual(seen, ["one", "two"]);
  assert.equal(response.json().results.length, 2);
  assert.ok(response.json().results.every((r) => r.blocked));
});

test("manual override retains AI audit and cannot approve a missing or stale asset", async () => {
  let content = { id: "v", status: "qa_failed", updated_at: "now", qa_score: 62, qa: { publish: false, summary: "Wrong screen" }, asset_urls: ["a.mp4"], decision: { review_revision: 2, campaign: { id: "c" } } };
  const cmo = new CmoController({ repository: {
    contentById: async () => structuredClone(content),
    updateContent: async (_id, patch) => (content = { ...content, ...patch }),
    createContentReview: async () => ({ reused: true, review: { status: "processed", decision: "approve" } }),
  }, orchestrator: { approveContent: async () => { content.status = "approved"; } } });
  cmo.releaseItem = async () => ({ scheduled: true });
  const entry = { contentId: "v", revision: 2, decision: "Approve", qaOverride: 90, contentUpdatedAt: "now" };
  await cmo.assetDecision(entry);
  assert.equal(content.qa_score, 90);
  assert.equal(content.qa.human_override.original_score, 62);
  assert.equal(content.qa.human_override.original_review.publish, false);
  await assert.rejects(cmo.assetDecision({ ...entry, contentUpdatedAt: "old" }), /Media changed/);
  content.asset_urls = [];
  await assert.rejects(cmo.assetDecision(entry), /completed asset/);
});

test("explicit approval of a low-QA completed video preserves its original score and audit", async () => {
  let content = { id: "v", status: "qa_failed", updated_at: "now", qa_score: 63, failure_reason: "s05: generated UI", qa: { publish: false, critical_issues: ["s05: generated UI"] }, asset_urls: ["review.mp4"], decision: { review_revision: 1, campaign: { id: "c" } } };
  const cmo = new CmoController({ repository: {
    contentById: async () => structuredClone(content),
    updateContent: async (_id, patch) => (content = { ...content, ...patch }),
    createContentReview: async () => ({ reused: true, review: { status: "processed", decision: "approve" } }),
  }, orchestrator: { approveContent: async () => { content.status = "approved"; } } });
  cmo.releaseItem = async () => ({ scheduled: true });
  await cmo.assetDecision({ contentId: "v", revision: 1, decision: "Approve", contentUpdatedAt: "now" });
  assert.equal(content.qa_score, 63);
  assert.equal(content.qa.human_override.original_score, 63);
  assert.equal(content.qa.human_override.original_reason, "s05: generated UI");
  assert.equal(content.qa.human_override.original_review.publish, false);
  assert.equal(content.status, "approved");
});

test("explicit approval publishes a completed failed asset without AI repair", async () => {
  let content = { id: "v", status: "failed", updated_at: "now", failure_reason: "AI disliked continuity", qa: { publish: false }, asset_urls: ["review.mp4"], decision: { review_revision: 1, campaign: { id: "c" } } };
  const cmo = new CmoController({ repository: {
    contentById: async () => structuredClone(content),
    updateContent: async (_id, patch) => (content = { ...content, ...patch }),
    createContentReview: async () => ({ reused: true, review: { status: "processed", decision: "approve" } }),
  }, orchestrator: { approveContent: async () => { content.status = "approved"; } } });
  cmo.releaseItem = async () => ({ scheduled: true });
  cmo.repairAndApprove = async () => assert.fail("human approval must not start AI repair");

  await cmo.assetDecision({ contentId: "v", revision: 1, decision: "Approve", contentUpdatedAt: "now" });
  assert.equal(content.status, "approved");
  assert.equal(content.qa.human_override.original_reason, "AI disliked continuity");
});

test("release of one approved item requires actual Buffer post confirmation", async () => {
  const cmo = new CmoController({ repository: { publicationByContent: async () => [{ platform: "instagram", error: "Rejected media", provider_request_id: null }] }, campaigns: {
    assertPublicationAllowed: async () => true, withWork: async (_id, _op, fn) => fn(),
  }, orchestrator: { publishContent: async () => ({}) } });
  const stages = [];
  cmo.progress = async (_id, stage) => stages.push(stage);
  await assert.rejects(cmo.releaseItem("c", "v"), /Rejected media/);
  assert.deepEqual(stages, ["publishing", "blocked"]);
});

test("automatic QA repair is bounded and preserves human story instructions", async () => {
  let content = { id: "v", status: "failed", failure_reason: "Scene QA failed after maximum attempts: S4", decision: { review_revision: 1 } };
  const cmo = new CmoController({ repository: { contentById: async () => content }, approvalSheet: { markContentDecision: async () => {} } });
  const revisions = [];
  cmo.progress = async () => {};
  cmo.assetDecision = async (entry) => {
    revisions.push(entry);
    content = { ...content, decision: { review_revision: content.decision.review_revision + 1 } };
    return { blocked: true };
  };
  const result = await cmo.repairAndApprove({ contentId: "v", revision: 1, decision: "Approve" }, content);
  assert.equal(result.blocked, true);
  assert.equal(revisions.length, 2);
  assert.ok(revisions.every((e) => /people and dialogue/.test(e.instructions)));
});

test("repair progress is visible even while the old asset still has failed QA", () => {
  const result = contentPresentation({ status: "qa_failed", failure_reason: "Old failure", decision: { workflow: { stage: "repairing", message: "Automatic QA repair 1/2 is running." } } });
  assert.equal(result.status, "Repairing");
  assert.match(result.reason, /1\/2/);
});

test("reviewer rejection shows plan revision progress instead of stale QA instructions", () => {
  const result = contentPresentation({ status: "qa_failed", failure_reason: "Old failure", decision: { workflow: { stage: "revising", message: "Astra is rewriting the intro from the reviewer's instructions." } } });
  assert.equal(result.status, "Revising plan");
  assert.match(result.reason, /rewriting the intro/);
  assert.doesNotMatch(result.reason, /ACTION REQUIRED/);
});

test("old fingerprints do not restart an approved idea whose asset needs review", async () => {
  const rows = [{ rowNumber: 30, "Idea ID": "v", "Campaign ID": "c", Version: "1", "Approved version": "1", "Idea decision": "Approve", "Revision instructions": "", "Planned date": "2026-10-02", "Stored planned date": "2026-10-02", "Current status": "Needs Review", "Processed decision fingerprint": "legacy" }];
  assert.deepEqual(await board([], rows).pendingIdeaDecisions(), []);
});

test("an explicit approval retries a blocked Buffer attempt without automatically looping", async () => {
  const rows = [contentRow({ Decision: "Approve", "Pipeline state": "approved", "QA score": "90", "Processing result": "ERROR: Buffer rejected the request" })];
  const queue = board(rows);
  const [entry] = await queue.pendingDecisions();
  rows[0]["Processed decision fingerprint"] = entry.fingerprint;
  rows[0].Decision = "Needs Review";
  assert.deepEqual(await queue.pendingDecisions(), []);
  rows[0].Decision = "Approve";
  assert.equal((await queue.pendingDecisions()).length, 1);
  rows[0]["Processing result"] = "Needs Review: automatic repair failed";
  assert.equal((await queue.pendingDecisions()).length, 1);
});

test("an automatically repaired and scheduled revision shows the completed approval", async () => {
  const rows = [contentRow({ Decision: "Pending", "Asset 1": "a.mp4" })];
  await board(rows).syncContent([{ id: "v", status: "scheduled", qa_score: 86, asset_urls: ["a.mp4"], decision: { review_revision: 2 }, publications: [{ platform: "instagram", provider_request_id: "confirmed", status: "scheduled" }] }]);
  assert.equal(rows[0].Decision, "Approve");
  assert.equal(rows[0]["Current status"], "Scheduled");
  assert.equal(contentPresentation({ status: "planned", decision: { workflow: { stage: "generating", message: "Generating now" } } }).status, "Generating");
});

test("failed scenes show the actual defects rather than only an attempt-limit message", () => {
  const result = contentPresentation({ status: "failed", failure_reason: "Scene QA failed after maximum attempts", decision: { generation: { scenes: [
    { scene_id: "S1", qa: { accept: false, defects: ["Unexpected walk at the cut"] } },
    { scene_id: "S4", qa: { accept: false, defects: ["Required approach is missing"] } },
  ] } } });
  assert.match(result.reason, /S1: Unexpected walk/);
  assert.match(result.reason, /S4: Required approach/);
});

test("a low-QA video presents each scene defect once beside the finished asset", () => {
  const item = { status: "qa_failed", asset_urls: ["review.mp4"], qa: { critical_issues: ["s01: towel changes", "s05: fake UI"] }, decision: { generation: { scenes: [{ scene_id: "s01", qa: { accept: false, defects: ["towel changes"] } }, { scene_id: "s05", qa: { accept: false, defects: ["fake UI"] } }] } } };
  const result = contentPresentation(item);
  assert.equal(result.status, "Needs Review");
  assert.match(result.reason, /ACTION REQUIRED: Review Asset 1/);
  assert.equal(result.reason.match(/s01: towel changes/g)?.length, 1);
  assert.equal(result.reason.match(/s05: fake UI/g)?.length, 1);
});

test("platform video variants are named clearly in Content Review", () => {
  const result = contentPresentation({
    status: "awaiting_approval",
    content_type: "video",
    asset_urls: ["instagram.mp4", "tiktok.mp4", "youtube.mp4"],
    decision: { generation: { platform_variants: { instagram: {}, tiktok: {}, youtube: {} } } },
  });
  assert.match(result.reason, /Assets 1-3 \(Instagram Reel, TikTok, YouTube Short\)/);
});

test("new review rows are written from column A after the last used row, never via append", async () => {
  const queue = new ReviewBoard({ spreadsheetId: "test", auth: {} });
  const calls = [];
  queue.request = async (path, options = {}) => {
    calls.push({ path: decodeURIComponent(path), method: options.method ?? "GET", body: options.body });
    return options.method ? {} : { values: [["Decision"], ["Pending"], [], ["Approve"]] };
  };
  await queue.appendBoard("Content Review", CONTENT_HEADERS, [{ "Content ID": "a" }, { "Content ID": "b" }]);
  const write = calls.find((call) => call.method === "PUT");
  assert.match(write.path, /'Content Review'!A5:AF6\?valueInputOption=RAW$/);
  assert.equal(write.body.values[0][CONTENT_HEADERS.indexOf("Content ID")], "a");
  assert.ok(!calls.some((call) => call.path.includes(":append")));
});

test("overlapping content syncs are serialized so a new item is appended once", async () => {
  const content = [];
  const queue = board(content);
  const item = { id: "new", status: "awaiting_approval", content_type: "image", asset_urls: ["https://a/1.png"], decision: { review_revision: 1, content: {} } };
  await Promise.all([queue.syncContent([item]), queue.syncContent([item])]);
  assert.equal(content.filter((row) => row["Content ID"] === "new").length, 1);
});
