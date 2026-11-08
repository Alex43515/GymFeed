import test from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, readFile, writeFile, access } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { LibraryInbox, librarySlug } from "../src/library-inbox.mjs";
import { appCaptureCatalog, resolveAppCapture } from "../src/app-captures.mjs";

async function setup(files) {
  const root = await mkdtemp(join(tmpdir(), "gymfeed-library-"));
  await writeFile(join(root, "manifest.json"), JSON.stringify({ version: 1, captures: [
    { id: "requested:train-open", filename: "train-open.mp4", drive_file_id: "known", verified: true, marketing_safe: true, feature: "train", duration_seconds: 5, recorded_interactions: ["x"] },
  ] }));
  const costs = [];
  const inbox = new LibraryInbox({
    root,
    config: { GOOGLE_DRIVE_ASSET_UPLOAD_URL: "https://drive.google.com/drive/folders/abc", OPENAI_ESTIMATED_QA_COST_USD: 0.05 },
    ingestor: {
      listFolder: async () => files,
      download: async (id) => ({ buffer: Buffer.from(`video-${id}`) }),
      probeDuration: async () => 12.5,
    },
    contactSheet: async () => Buffer.from("jpeg"),
    brain: { describeLibraryCapture: async ({ filename }) => ({ costUsd: 0.01, responseId: "r1", data: {
      feature: "events", title: filename, description: "Events tab, joining the Saturday group run",
      recorded_interactions: ["0.0-4.0s: Events list", "4.0-9.0s: Join tapped, joined state shown"], privacy_concerns: [], usable_for_marketing: true,
    } }) },
    repository: { reserveCost: async () => "res", settleCost: async (...args) => costs.push(args), releaseCost: async () => {} },
  });
  return { root, inbox, costs };
}

test("library slugs are readable and unique", () => {
  assert.equal(librarySlug("My Events Join!.mp4"), "my-events-join");
  assert.equal(librarySlug("events.mp4", new Set(["library:events"])), "events-2");
});

test("unsolicited Drive recordings get an AI draft but stay out of the library until verified", async () => {
  const { root, inbox, costs } = await setup([
    { id: "known", name: "train-open.mp4", mimeType: "video/mp4" },
    { id: "req", name: "coach-ask.mp4", mimeType: "video/mp4" },
    { id: "photo", name: "gym.jpg", mimeType: "image/jpeg" },
    { id: "new1", name: "Events Join.mp4", mimeType: "video/mp4" },
  ]);
  const scanned = await inbox.scan({ requestedFilenames: new Set(["coach-ask.mp4"]) });
  assert.deepEqual(scanned.added.map((item) => [item.id, item.status]), [["library:events-join", "pending"]]);
  assert.equal(costs.length, 1);
  assert.deepEqual((await appCaptureCatalog(root)).map((c) => c.id), ["requested:train-open"]);

  const rows = await inbox.rows();
  assert.equal(rows[0].Status, "Waiting for your check");
  assert.equal(rows[0].Feature, "events");

  // A second scan never re-describes the same Drive file.
  assert.equal((await inbox.scan({ requestedFilenames: new Set(["coach-ask.mp4"]) })).added.length, 0);

  const decided = await inbox.applyDecisions([{ "Capture ID": "library:events-join", Verify: "Verify", Feature: "events", Description: "Owner-corrected description of joining an event", "Recorded interactions": "0-4s: Events list\n4-9s: Joined" }]);
  assert.deepEqual(decided, [{ id: "library:events-join", status: "verified" }]);
  const capture = await resolveAppCapture("library:events-join", root);
  assert.equal(capture.description, "Owner-corrected description of joining an event");
  assert.deepEqual(capture.recorded_interactions, ["0-4s: Events list", "4-9s: Joined"]);
  assert.equal(capture.duration_seconds, 12.5);
});

test("rejected library recordings are removed and never offered again", async () => {
  const { root, inbox } = await setup([{ id: "new2", name: "blurry.mp4", mimeType: "video/mp4" }]);
  await inbox.scan();
  await inbox.applyDecisions([{ "Capture ID": "library:blurry", Verify: "Reject" }]);
  await assert.rejects(access(join(root, "library-blurry.mp4")));
  assert.equal((await inbox.scan()).added.length, 0);
  const state = JSON.parse(await readFile(join(root, "library-inbox.json"), "utf8"));
  assert.equal(state.items[0].status, "rejected");
  assert.equal((await appCaptureCatalog(root)).length, 1);
});
