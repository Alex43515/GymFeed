import test from "node:test";
import assert from "node:assert/strict";
import { CmoController } from "../src/cmo-controller.mjs";

function fixture({ failEveryTime = false, providerFailure = false, attempts = 0 } = {}) {
  let content = { id: "v", status: "planned", asset_urls: [], decision: { campaign: { idea_revision: 1 }, workflow: { story_repair_attempt: attempts } } };
  const calls = [];
  let productions = 0;
  const cmo = new CmoController({
    repository: { contentById: async () => content },
    campaigns: {
      withWork: async (_id, operation, fn) => { assert.equal(operation, "produce"); return fn(); },
      decideIdea: async (input) => calls.push(input),
      startItem: async (input) => { calls.push({ start: input }); return {}; },
    },
    orchestrator: { processContentToReview: async () => {
      productions++;
      if (providerFailure) throw new Error("Provider timed out; outcome unknown");
      if (content.decision.workflow.story_preview_authorized_fingerprint) {
        content = { ...content, status: "qa_failed", asset_urls: ["review.mp4"] };
        return { content };
      }
      if (productions === 1 || failEveryTime) {
        content = { ...content, status: "failed", failure_reason: "Creative story QA failed before media generation: clarify routine ownership", decision: { ...content.decision, story_review: { fingerprint: "story-v3", accept: false } } };
        const error = new Error(content.failure_reason); error.safeToRetry = true; error.storyQaFailed = true; throw error;
      }
      content = { ...content, status: "awaiting_approval" }; return { content };
    } },
  });
  cmo.progress = async (_id, stage, _message, extra = {}) => { content.decision.workflow = { ...content.decision.workflow, ...extra, stage }; };
  cmo.reviseIdea = async (_campaign, _id, revision) => {
    calls.push({ revise: revision });
    content = { ...content, status: "planned", failure_reason: null, decision: { ...content.decision, campaign: { idea_revision: revision + 1 } } };
  };
  return { cmo, calls, productions: () => productions };
}

test("known pre-media story rejection repairs the same item then stops at final review", async () => {
  const f = fixture();
  const result = await f.cmo.produceWithStoryRepair("c", "v");
  assert.equal(result.content.status, "awaiting_approval");
  assert.equal(f.productions(), 2);
  assert.deepEqual(f.calls.filter((c) => c.decision).map((c) => [c.contentId, c.revision, c.decision]), [["v", 1, "reject"], ["v", 2, "approve"]]);
  assert.equal(f.calls.at(-1).start.contentId, "v");
});

test("after two story repairs the same idea produces a review-only video with QA findings", async () => {
  const f = fixture({ failEveryTime: true });
  const result = await f.cmo.produceWithStoryRepair("c", "v");
  assert.equal(result.content.status, "qa_failed");
  assert.deepEqual(result.content.asset_urls, ["review.mp4"]);
  assert.equal(f.productions(), 4);
  assert.equal(f.calls.filter((c) => c.revise).length, 2);
  const resumed = fixture({ attempts: 2 });
  assert.equal((await resumed.cmo.produceWithStoryRepair("c", "v")).content.status, "qa_failed");
  assert.equal(resumed.calls.length, 0);
});

test("an unavailable story QA budget skips revisions and produces a review-only video", async () => {
  const f = fixture();
  const original = f.cmo.orchestrator.processContentToReview;
  f.cmo.orchestrator.processContentToReview = async (...args) => {
    const output = await original(...args).catch((error) => {
      if (error.storyQaFailed) {
        const review = f.cmo.repository.contentById().then((item) => { item.decision.story_review.review_status = "budget_blocked"; });
        return review.then(() => { throw error; });
      }
      throw error;
    });
    return output;
  };
  const result = await f.cmo.produceWithStoryRepair("c", "v");
  assert.equal(result.content.status, "qa_failed");
  assert.equal(f.calls.length, 0);
  assert.equal(f.productions(), 2);
});

test("ambiguous provider failure is never treated as a script rewrite request", async () => {
  const f = fixture({ providerFailure: true });
  await assert.rejects(() => f.cmo.produceWithStoryRepair("c", "v"), /outcome unknown/);
  assert.equal(f.calls.length, 0); assert.equal(f.productions(), 1);
});
