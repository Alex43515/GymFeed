import test from "node:test";
import assert from "node:assert/strict";
import { APPROVAL_SHEET_HEADERS, IDEA_REVIEW_HEADERS, GoogleSheetsApprovalQueue } from "../src/providers/google-sheets.mjs";

function row(headers, values) {
  const result = Array(headers.length).fill("");
  for (const [key, value] of Object.entries(values)) result[headers.indexOf(key)] = value;
  return result;
}

function col(letter) {
  return [...letter].reduce((total, char) => total * 26 + char.charCodeAt(0) - 64, 0) - 1;
}

function mockQueue({ content = [], ideas = [] } = {}) {
  const queue = new GoogleSheetsApprovalQueue({ spreadsheetId: "test", auth: {} });
  const writes = [];
  queue.readRows = async () => structuredClone(content);
  queue.readIdeaRows = async () => structuredClone(ideas);
  queue.updateRange = async (range, values, sheetName = "Content Review") => {
    writes.push({ range, values, sheetName });
    const [, startColumn, rowNumber] = range.match(/^([A-Z]+)(\d+):[A-Z]+\d+$/);
    const rows = sheetName === "Idea Review" ? ideas : content;
    values.forEach((value, offset) => {
      const index = Number(rowNumber) - 2 + offset;
      rows[index] ??= [];
      value.forEach((cell, cellIndex) => { rows[index][col(startColumn) + cellIndex] = cell; });
    });
  };
  queue.updateRanges = async (updates, sheetName = "Content Review") => {
    for (const update of updates) await queue.updateRange(update.range, update.values, sheetName);
  };
  queue.appendRows = async (values, sheetName = "Content Review") => {
    (sheetName === "Idea Review" ? ideas : content).push(...structuredClone(values));
  };
  return { queue, writes, content, ideas };
}

function idea(version = 1) {
  return {
    id: "idea-1", campaign_id: "campaign-1", version, status: "pending_idea_approval",
    content_type: "video", planned_date: "2026-10-01", approved_version: null,
    brief: {
      title: "Walk in with a plan", hook: "What am I training today?", audience: "Returning lifters",
      feature: "Train", objective: "Start a workout", description: "Uncertainty, real product use, action",
      generation_prompt: "VIDEO SCENE hook\nWalk into the gym, then cut to verified product proof.",
      storyboard: [{ second: 0, action: "Member arrives" }, { second: 4, action: "Open real Train routine" }],
      dialogue: "Today has a plan.", caption: "Get started with GymFeed", cta: "Open Train",
      evidence: [{ url: "https://example.test/report", metric: "10 saves / 100 views", observed_at: "2026-09-20" }],
      rationale: "A testable hypothesis, not a promise of virality",
      production_requirements: {
        brief: ["Record requested:train-demo showing the routine opening and first completed set."],
        captures: ["requested:train-demo"], screenshots: ["curated/gymfeed-train-routine.png"],
        upload_folder_url: "https://drive.google.com/drive/folders/test",
        estimated_video_cost_usd_per_attempt: 2,
      },
    },
  };
}

test("content sync never overwrites failed-item reviewer decisions, instructions, or acknowledgments", async () => {
  const { queue, writes, content } = mockQueue({ content: [row(APPROVAL_SHEET_HEADERS, {
    "Content ID": "video-1", "Content type": "video", Revision: 2,
    "Video decision": "Reject", "Video instructions": "Show a real workout instead of standing still",
    "Carousel decision": "Pending", "Carousel instructions": "Do not erase even the unused pair",
    "Processing result": "Queued", "Processed at": "2026-09-20T00:00:00Z",
  })] });
  await queue.syncContent([{
    id: "video-1", content_type: "video", status: "qa_failed", failure_reason: "Poor story match",
    decision: { review_revision: 2, review_instructions: "Old instructions" },
  }]);
  assert.equal(content[0][0], "Reject");
  assert.equal(content[0][1], "Show a real workout instead of standing still");
  assert.equal(content[0][3], "Do not erase even the unused pair");
  assert.equal(content[0][22], "Queued");
  assert.deepEqual(writes.map((entry) => entry.range), ["E2:V2", "Y2:Z2"]);
  assert.equal((await queue.pendingDecisions())[0].instructions, "Show a real workout instead of standing still");
});

test("new content revisions replace the same row and reset it to pending", async () => {
  const { queue, content } = mockQueue({ content: [row(APPROVAL_SHEET_HEADERS, {
    "Content ID": "video-1", "Content type": "video", Revision: 1, "Video decision": "Approve",
  })] });
  const result = await queue.syncContent([{
    id: "video-1", content_type: "video", status: "awaiting_approval", decision: { review_revision: 2 },
  }]);
  assert.deepEqual(result, { updated: 1, appended: 0 });
  assert.equal(content.length, 1);
  assert.equal(content[0][0], "Pending");
  assert.equal(content[0][APPROVAL_SHEET_HEADERS.indexOf("Revision")], 2);
  assert.match(content[0][APPROVAL_SHEET_HEADERS.indexOf("Processing result")], /Rejected revision 1/);
  assert.deepEqual(await queue.pendingDecisions(), []);
});

test("content sync cannot clobber instructions typed after its initial read", async () => {
  const { queue, content } = mockQueue({ content: [row(APPROVAL_SHEET_HEADERS, {
    "Content ID": "video-1", "Content type": "video", Revision: 1,
    "Video decision": "Pending", "Video instructions": "",
  })] });
  queue.readRows = async () => {
    const snapshot = structuredClone(content);
    content[0][0] = "Reject";
    content[0][1] = "A concurrent human edit";
    return snapshot;
  };
  await queue.syncContent([{ id: "video-1", content_type: "video", status: "failed", decision: {} }]);
  assert.equal(content[0][0], "Reject");
  assert.equal(content[0][1], "A concurrent human edit");
});

test("idea rows expose the full brief separately from finished-content review", async () => {
  const { queue, ideas, content } = mockQueue();
  assert.deepEqual(await queue.syncIdeas([idea()]), { updated: 0, appended: 1 });
  assert.equal(content.length, 0);
  assert.equal(ideas[0].length, IDEA_REVIEW_HEADERS.length);
  assert.equal(ideas[0][0], "Pending");
  assert.equal(ideas[0][IDEA_REVIEW_HEADERS.indexOf("Title")], "Walk in with a plan");
  assert.match(ideas[0][IDEA_REVIEW_HEADERS.indexOf("Generation prompt")], /VIDEO SCENE hook/);
  assert.match(ideas[0][IDEA_REVIEW_HEADERS.indexOf("Storyboard / slide outline")], /Open real Train routine/);
  assert.match(ideas[0][IDEA_REVIEW_HEADERS.indexOf("Evidence and metrics")], /observed_at/);
  const requirements = ideas[0][IDEA_REVIEW_HEADERS.indexOf("Production requirements")];
  assert.match(requirements, /^ACTION REQUIRED FROM YOU BEFORE GENERATION/);
  assert.match(requirements, /requested:train-demo/);
  assert.match(requirements, /UPLOAD WITH THIS EXACT FILE NAME: train-demo\.mp4/);
  assert.match(requirements, /https:\/\/drive\.google\.com\/drive\/folders\/test/);
  assert.match(requirements, /Generation is blocked/);
  assert.match(requirements, /GymFeed image: curated\/gymfeed-train-routine\.png/);
  assert.match(requirements, /Estimated generated-video cost per attempt: \$2/);
  assert.equal(ideas[0][IDEA_REVIEW_HEADERS.indexOf("Idea ID")], "idea-1");
});

test("idea sync preserves human inputs and acknowledgments even when the idea fails", async () => {
  const { queue, ideas, writes } = mockQueue();
  await queue.syncIdeas([idea()]);
  ideas[0][0] = "Reject";
  ideas[0][1] = "Use equipment scanning instead";
  const entry = (await queue.pendingIdeaDecisions())[0];
  assert.equal(entry.ideaId, "idea-1");
  assert.equal(entry.campaignId, "campaign-1");
  assert.equal(entry.version, 1);
  assert.equal(entry.plannedDate, "2026-10-01");
  assert.equal((await queue.markIdeaDecision(entry, "Revision queued")).marked, true);
  writes.length = 0;
  await queue.syncIdeas([{ ...idea(), status: "revision_failed" }]);
  assert.equal(ideas[0][0], "Reject");
  assert.equal(ideas[0][1], "Use equipment scanning instead");
  assert.equal(ideas[0][IDEA_REVIEW_HEADERS.indexOf("Processing result")], "Revision queued");
  assert.deepEqual(writes.map((entry) => entry.range), ["C2:C2", "E2:V2", "Y2:Z2"]);
  assert.deepEqual(await queue.pendingIdeaDecisions(), []);
  ideas[0][1] = "Use the equipment scanner result recording";
  assert.equal((await queue.pendingIdeaDecisions()).length, 1);
});

test("new media on the same revision clears an early approval and requires fresh review", async () => {
  const { queue, content, writes } = mockQueue({ content: [row(APPROVAL_SHEET_HEADERS, {
    "Content ID": "carousel-1", "Content type": "carousel", Revision: 1,
    "Carousel decision": "Approve", "Current status": "qa_failed",
    "Processing result": "Approved too early", "Updated at": "2026-09-26T12:00:00Z",
  })] });

  await queue.syncContent([{
    id: "carousel-1", content_type: "carousel", status: "awaiting_approval",
    asset_urls: ["https://assets.test/slide-1.png"], thumbnail_url: "https://assets.test/slide-1.png",
    updated_at: "2026-09-26T13:00:00Z", decision: { review_revision: 1 },
  }]);

  assert.equal(content[0][APPROVAL_SHEET_HEADERS.indexOf("Carousel decision")], "Pending");
  assert.equal(content[0][APPROVAL_SHEET_HEADERS.indexOf("Current status")], "awaiting_approval");
  assert.match(content[0][APPROVAL_SHEET_HEADERS.indexOf("Processing result")], /previous decision was cleared/);
  assert.deepEqual(writes.map((entry) => entry.range), ["A2:Z2"]);
  assert.deepEqual(await queue.pendingDecisions(), []);
});

test("sheet value updates are sent in one Google batch request", async () => {
  const queue = new GoogleSheetsApprovalQueue({ spreadsheetId: "test", auth: {} });
  const requests = [];
  queue.request = async (path, options) => { requests.push({ path, options }); return {}; };

  await queue.updateRanges([
    { range: "E2:V2", values: [["preview"]] },
    { range: "Y2:Z2", values: [["content-id", "updated-at"]] },
  ]);

  assert.equal(requests.length, 1);
  assert.equal(requests[0].path, "/values:batchUpdate");
  assert.deepEqual(requests[0].options.body.data.map((item) => item.range), [
    "'Content Review'!E2:V2", "'Content Review'!Y2:Z2",
  ]);
});

test("planned date is reviewer-owned, survives sync, and participates in decision identity", async () => {
  const { queue, ideas } = mockQueue();
  await queue.syncIdeas([idea()]);
  const plannedDateColumn = IDEA_REVIEW_HEADERS.indexOf("Planned date");
  ideas[0][plannedDateColumn] = "2026-10-09";
  ideas[0][IDEA_REVIEW_HEADERS.indexOf("Idea decision")] = "Approve";

  await queue.syncIdeas([{ ...idea(), planned_date: "2026-10-01", status: "sync_refresh" }]);
  assert.equal(ideas[0][plannedDateColumn], "2026-10-09");
  const first = (await queue.pendingIdeaDecisions())[0];
  assert.equal(first.plannedDate, "2026-10-09");
  assert.equal((await queue.markIdeaDecision(first, "Processed")).marked, true);

  ideas[0][plannedDateColumn] = "2026-10-10";
  const changed = (await queue.pendingIdeaDecisions())[0];
  assert.equal(changed.plannedDate, "2026-10-10");
  assert.notEqual(changed.fingerprint, first.fingerprint);
});

test("a revised idea replaces the same row and only its pending decision can run", async () => {
  const { queue, ideas } = mockQueue();
  await queue.syncIdeas([idea()]);
  ideas[0][0] = "Approve";
  ideas[0][IDEA_REVIEW_HEADERS.indexOf("Planned date")] = "2026-10-09";
  const oldEntry = (await queue.pendingIdeaDecisions())[0];
  await queue.syncIdeas([{ ...idea(2), instructions: "Change only this concept" }]);
  assert.equal(ideas.length, 1);
  assert.equal(ideas[0][0], "Pending");
  assert.equal(ideas[0][IDEA_REVIEW_HEADERS.indexOf("Planned date")], "2026-10-09");
  assert.equal(ideas[0][IDEA_REVIEW_HEADERS.indexOf("Version")], 2);
  assert.match(ideas[0][IDEA_REVIEW_HEADERS.indexOf("Processing result")], /Revised version 2 is pending/);
  assert.deepEqual(await queue.pendingIdeaDecisions(), []);
  assert.equal((await queue.markIdeaDecision(oldEntry, "Stale approval")).marked, false);
  ideas[0][0] = "Reject";
  ideas[0][1] = "Change only this concept";
  const pending = await queue.pendingIdeaDecisions();
  assert.equal(pending.length, 1);
  assert.equal(pending[0].version, 2);
  assert.equal(pending[0].rowNumber, 2);
});

test("idea acknowledgment never clears a reviewer edit made after dispatch", async () => {
  const { queue, ideas, writes } = mockQueue();
  await queue.syncIdeas([idea()]);
  ideas[0][0] = "Reject";
  ideas[0][1] = "Original instruction";
  const entry = (await queue.pendingIdeaDecisions())[0];
  ideas[0][1] = "New instruction typed after dispatcher read";
  writes.length = 0;
  assert.equal((await queue.markIdeaDecision(entry, "Processed old instruction")).marked, false);
  assert.equal(writes.length, 0);
  assert.equal((await queue.pendingIdeaDecisions())[0].instructions, "New instruction typed after dispatcher read");
});

test("idea acknowledgment refuses a row that was moved by sorting", async () => {
  const { queue, ideas, writes } = mockQueue();
  await queue.syncIdeas([idea(), { ...idea(), id: "idea-2" }]);
  ideas[0][0] = "Approve";
  const entry = (await queue.pendingIdeaDecisions())[0];
  ideas.reverse();
  writes.length = 0;
  assert.equal((await queue.markIdeaDecision(entry, "Processed")).marked, false);
  assert.equal(writes.length, 0);
});

test("idea initialization refuses unfamiliar existing headers", async () => {
  const queue = new GoogleSheetsApprovalQueue({ spreadsheetId: "test", auth: {} });
  const writes = [];
  queue.request = async (path, options) => {
    if (options) writes.push(options);
    return path.startsWith("?fields=")
      ? { sheets: [{ properties: { title: "Idea Review", sheetId: 3 } }] }
      : { values: [["Unrelated existing data"]] };
  };
  await assert.rejects(queue.ensureIdeaSheet(), /Refusing to overwrite unfamiliar columns/);
  assert.equal(writes.length, 0);
});

test("an asset-rejection plan revision stays approved in Idea Review while final media returns to review", async () => {
  const { queue, ideas } = mockQueue();
  await queue.syncIdeas([idea()]);
  await queue.syncIdeas([{
    ...idea(2), status: "approved", approved_version: 2,
    instructions: "Replace the rejected final asset with clearer product proof",
  }]);
  assert.equal(ideas.length, 1);
  assert.equal(ideas[0][IDEA_REVIEW_HEADERS.indexOf("Idea decision")], "Approve");
  assert.match(ideas[0][IDEA_REVIEW_HEADERS.indexOf("Processing result")], /approved for replacement production/);
  assert.deepEqual(await queue.pendingIdeaDecisions(), []);
});

test("approved production blocks stay visible with their reason and are retried", async () => {
  const { queue, ideas } = mockQueue();
  await queue.syncIdeas([{
    ...idea(),
    status: "Approved - Blocked",
    approved_version: 1,
    production_block_reason: "Required Drive video is missing: train-demo.mp4",
  }]);
  assert.equal(ideas[0][IDEA_REVIEW_HEADERS.indexOf("Idea decision")], "Approve");
  assert.equal(ideas[0][IDEA_REVIEW_HEADERS.indexOf("Current status")], "Approved - Blocked");
  assert.match(ideas[0][IDEA_REVIEW_HEADERS.indexOf("Processing result")], /train-demo\.mp4/);
  const first = (await queue.pendingIdeaDecisions())[0];
  assert.equal(first.decision, "Approve");
  await queue.markIdeaDecision(first, "Approved - Blocked: still waiting");
  assert.equal((await queue.pendingIdeaDecisions()).length, 1);
});

test("legacy idea sheet expands to AA and migrates rows without losing the fingerprint", async () => {
  const legacyHeaders = IDEA_REVIEW_HEADERS.filter((header) => header !== "Generation prompt");
  const legacyRow = row(legacyHeaders, {
    "Idea decision": "Reject", Version: 2, "Idea ID": "idea-legacy",
    "Processed decision fingerprint": "fingerprint-legacy",
  });
  const queue = new GoogleSheetsApprovalQueue({ spreadsheetId: "test", auth: {} });
  const batches = [];
  const writes = [];
  queue.request = async (path, options) => {
    if (path.startsWith("?fields=")) return { sheets: [{ properties: { title: "Idea Review", sheetId: 3, gridProperties: { columnCount: 26 } } }] };
    if (path.includes("A1%3AAA1")) return { values: [legacyHeaders] };
    if (path.includes("A2%3AZ1000")) return { values: [legacyRow] };
    if (path === ":batchUpdate") { batches.push(options.body); return {}; }
    throw new Error(`Unexpected request ${path}`);
  };
  queue.updateRange = async (range, values, sheetName) => { writes.push({ range, values, sheetName }); };

  await queue.ensureIdeaSheet();

  assert.deepEqual(batches[0].requests, [{ appendDimension: { sheetId: 3, dimension: "COLUMNS", length: 1 } }]);
  const migrated = writes.find((write) => write.range === "A2:AA2").values[0];
  assert.equal(migrated[IDEA_REVIEW_HEADERS.indexOf("Idea decision")], "Reject");
  assert.equal(migrated[IDEA_REVIEW_HEADERS.indexOf("Generation prompt")], "");
  assert.equal(migrated[IDEA_REVIEW_HEADERS.indexOf("Processed decision fingerprint")], "fingerprint-legacy");
  assert.deepEqual(writes.find((write) => write.range === "A1:AA1").values[0], IDEA_REVIEW_HEADERS);
});

test("idea sync rejects missing or invalid identity versions", async () => {
  const { queue } = mockQueue();
  await assert.rejects(queue.syncIdeas([{ ...idea(), version: 0 }]), /positive integer version/);
  await assert.rejects(queue.syncIdeas([{ ...idea(), id: "" }]), /stable id/);
});
