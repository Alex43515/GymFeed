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
  assert.match(result.reason, /Video ready for review/);
  assert.equal(result.reason.match(/s01: towel changes/g)?.length, 1);
  assert.equal(result.reason.match(/s05: fake UI/g)?.length, 1);
});
