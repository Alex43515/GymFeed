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
      storyboard: [{ second: 0, action: "Member arrives" }, { second: 4, action: "Open real Train routine" }],
      dialogue: "Today has a plan.", caption: "Get started with GymFeed", cta: "Open Train",
      evidence: [{ url: "https://example.test/report", metric: "10 saves / 100 views", observed_at: "2026-09-20" }],
      rationale: "A testable hypothesis, not a promise of virality",
      production_requirements: { assets: ["train-demo.mp4"], estimated_cost_usd: 2 },
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

test("new content revisions append pending rows and obsolete revision approvals cannot be replayed", async () => {
  const { queue, content } = mockQueue({ content: [row(APPROVAL_SHEET_HEADERS, {
    "Content ID": "video-1", "Content type": "video", Revision: 1, "Video decision": "Approve",
  })] });
  const result = await queue.syncContent([{
    id: "video-1", content_type: "video", status: "awaiting_approval", decision: { review_revision: 2 },
  }]);
  assert.deepEqual(result, { updated: 0, appended: 1 });
  assert.equal(content[0][0], "Approve");
  assert.equal(content[1][0], "Pending");
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
  assert.equal(ideas[0][7], "Walk in with a plan");
  assert.match(ideas[0][13], /Open real Train routine/);
  assert.match(ideas[0][17], /observed_at/);
  assert.match(ideas[0][19], /estimated_cost_usd/);
  assert.equal(ideas[0][23], "idea-1");
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
  assert.equal((await queue.markIdeaDecision(entry, "Revision queued")).marked, true);
  writes.length = 0;
  await queue.syncIdeas([{ ...idea(), status: "revision_failed" }]);
  assert.equal(ideas[0][0], "Reject");
  assert.equal(ideas[0][1], "Use equipment scanning instead");
  assert.equal(ideas[0][21], "Revision queued");
  assert.deepEqual(writes.map((entry) => entry.range), ["C2:U2", "X2:Y2"]);
  assert.deepEqual(await queue.pendingIdeaDecisions(), []);
  ideas[0][1] = "Use the equipment scanner result recording";
  assert.equal((await queue.pendingIdeaDecisions()).length, 1);
});

test("only the latest idea version can produce a pending decision", async () => {
  const { queue, ideas } = mockQueue();
  await queue.syncIdeas([idea()]);
  ideas[0][0] = "Approve";
  const oldEntry = (await queue.pendingIdeaDecisions())[0];
  await queue.syncIdeas([idea(2)]);
  assert.equal(ideas[0][0], "Approve");
  assert.equal(ideas[1][0], "Pending");
  assert.deepEqual(await queue.pendingIdeaDecisions(), []);
  assert.equal((await queue.markIdeaDecision(oldEntry, "Stale approval")).marked, false);
  ideas[1][0] = "Reject";
  ideas[1][1] = "Change only this concept";
  const pending = await queue.pendingIdeaDecisions();
  assert.equal(pending.length, 1);
  assert.equal(pending[0].version, 2);
  assert.equal(pending[0].rowNumber, 3);
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

test("idea sync rejects missing or invalid identity versions", async () => {
  const { queue } = mockQueue();
  await assert.rejects(queue.syncIdeas([{ ...idea(), version: 0 }]), /positive integer version/);
  await assert.rejects(queue.syncIdeas([{ ...idea(), id: "" }]), /stable id/);
});
