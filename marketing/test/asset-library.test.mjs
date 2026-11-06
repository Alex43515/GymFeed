import test from "node:test";
import assert from "node:assert/strict";
import { buildShotList, libraryCatalog, libraryCoverage } from "../src/asset-library.mjs";
import { validateCaptureRequests } from "../src/brain.mjs";

const library = [
  { id: "requested:train-open-start-active", feature: "train", description: "Open routine and start", duration_seconds: 32, recorded_interactions: ["Start workout"] },
  { id: "requested:scan-food", feature: "nutrition_scan", description: "Scan a meal", duration_seconds: 12, recorded_interactions: ["Scan"] },
];
const usedIn = (ref, date) => ({ decision: { campaign: { date }, content: { scenes: [{ asset_type: "app_capture", capture_ref: ref }, { asset_type: "app_capture", capture_ref: ref }] } } });

test("library catalog reports how often and how recently each recording was used", () => {
  const catalog = libraryCatalog(library, [usedIn("requested:train-open-start-active", "2026-10-08"), usedIn("requested:train-open-start-active", "2026-10-10")]);
  assert.deepEqual(catalog.map((item) => [item.id, item.times_used, item.last_used]), [
    ["requested:train-open-start-active", 2, "2026-10-10"],
    ["requested:scan-food", 0, null],
  ]);
  assert.deepEqual(libraryCoverage(library, [{ feature: "train" }, { feature: "events" }]), {
    train: { recordings: 1, screenshots: 1 },
    nutrition_scan: { recordings: 1, screenshots: 0 },
    events: { recordings: 0, screenshots: 1 },
  });
});

test("daily plans reuse the library and justify at most one new recording", () => {
  const scene = (ref) => ({ asset_type: "app_capture", capture_ref: ref });
  const request = (ref) => ({ capture_ref: ref, feature: "events", shot_instructions: "Open Events, join the Saturday run, show the joined state", target_duration_seconds: 10, why_library_insufficient: "No library recording shows Events at all" });
  assert.doesNotThrow(() => validateCaptureRequests({ scenes: [scene("requested:train-open-start-active")], capture_requests: [] }, library));
  assert.doesNotThrow(() => validateCaptureRequests({ scenes: [scene("requested:events-join")], capture_requests: [request("requested:events-join")] }, library));
  assert.throws(() => validateCaptureRequests({ scenes: [scene("requested:events-join")], capture_requests: [] }, library), /capture_requests entry/);
  assert.throws(() => validateCaptureRequests({ scenes: [scene("requested:events-join"), scene("requested:coach-ask")],
    capture_requests: [request("requested:events-join"), request("requested:coach-ask")] }, library), /at most one new recording/);
});

test("shot list consolidates missing recordings for the next seven days", () => {
  const idea = (date, ref, status = "pending", contentStatus = "planned") => ({
    publication_date: date, idea_status: status,
    content: { status: contentStatus, decision: { content: { review_brief: { title: `Idea ${date}` }, scenes: [{ asset_type: "app_capture", capture_ref: ref, source_start_seconds: 1, duration_seconds: 4, source_duration_seconds: 8 }],
      capture_requests: [{ capture_ref: ref, feature: "events", shot_instructions: "Join an event", target_duration_seconds: 10, why_library_insufficient: "No Events footage" }] } } },
  });
  const rows = buildShotList([
    idea("2026-10-12", "requested:events-join"),
    idea("2026-10-11", "requested:events-join"),
    idea("2026-10-11", "requested:train-open-start-active"),
    idea("2026-10-13", "requested:coach-ask", "rejected"),
    idea("2026-10-30", "requested:far-future"),
    idea("2026-10-12", "requested:already-live", "approved", "scheduled"),
  ], library, { today: "2026-10-10", uploadFolderUrl: "https://drive.example/folder" });
  assert.deepEqual(rows.map((row) => [row["Capture ref"], row.Status, row["Needed by"]]), [
    ["requested:events-join", "Missing - record and upload", "2026-10-11"],
    ["requested:train-open-start-active", "In library", "2026-10-11"],
  ]);
  assert.equal(rows[0]["Upload as"], "events-join.mp4");
  assert.equal(rows[0]["What to record"], "Join an event");
});
