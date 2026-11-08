// The verified app-capture manifest is the reusable asset library. Every
// recording the owner uploads for a request stays in it, so planning sees what
// already exists, how often it was used, and which features still lack footage.

function planOf(content) {
  return content?.decision?.content ?? content?.content ?? {};
}

function dateOf(content) {
  return content?.decision?.campaign?.date ?? String(content?.created_at ?? content?.updated_at ?? "").slice(0, 10);
}

export function captureUsage(contents = []) {
  const usage = new Map();
  for (const content of contents) {
    const refs = new Set((planOf(content).scenes ?? [])
      .filter((scene) => scene.asset_type === "app_capture" && scene.capture_ref)
      .map((scene) => scene.capture_ref));
    for (const ref of refs) {
      const entry = usage.get(ref) ?? { times_used: 0, last_used: "" };
      entry.times_used += 1;
      const date = dateOf(content);
      if (date > entry.last_used) entry.last_used = date;
      usage.set(ref, entry);
    }
  }
  return usage;
}

export function libraryCatalog(captures = [], contents = []) {
  const usage = captureUsage(contents);
  return captures.map((capture) => ({
    id: capture.id,
    feature: capture.feature,
    description: String(capture.description ?? "").slice(0, 500),
    duration_seconds: capture.duration_seconds,
    recorded_interactions: (capture.recorded_interactions ?? []).slice(0, 8),
    times_used: usage.get(capture.id)?.times_used ?? 0,
    last_used: usage.get(capture.id)?.last_used || null,
  }));
}

export function libraryCoverage(captures = [], screenshots = []) {
  const coverage = {};
  for (const capture of captures) {
    const feature = String(capture.feature ?? "unknown");
    (coverage[feature] ??= { recordings: 0, screenshots: 0 }).recordings += 1;
  }
  for (const screenshot of screenshots) {
    const feature = String(screenshot.feature ?? "unknown");
    (coverage[feature] ??= { recordings: 0, screenshots: 0 }).screenshots += 1;
  }
  return coverage;
}

export const SHOT_LIST_HEADERS = [
  "Status", "Upload as", "Needed by", "GymFeed feature", "What to record", "Target length (s)",
  "Why a new recording", "Idea", "Idea status", "Drive folder", "Capture ref",
];

// One consolidated recording list for the coming week, so the owner can record
// everything in one sitting instead of reacting to each blocked idea.
export function buildShotList(ideas = [], captures = [], { today = new Date().toISOString().slice(0, 10), days = 7, uploadFolderUrl = "" } = {}) {
  const verified = new Set(captures.map((capture) => capture.id));
  const end = new Date(`${today}T12:00:00Z`);
  end.setUTCDate(end.getUTCDate() + days - 1);
  const endKey = end.toISOString().slice(0, 10);
  const rows = new Map();
  for (const idea of ideas) {
    const date = String(idea.publication_date ?? "");
    if (!date || date < today || date > endKey || idea.idea_status === "rejected") continue;
    const content = idea.content ?? {};
    if (["scheduled", "published", "approved"].includes(content.status)) continue;
    const plan = planOf(content);
    const requests = new Map((plan.capture_requests ?? []).map((request) => [request.capture_ref, request]));
    for (const scene of plan.scenes ?? []) {
      const ref = scene.capture_ref;
      if (scene.asset_type !== "app_capture" || !String(ref ?? "").startsWith("requested:")) continue;
      const existing = rows.get(ref);
      if (existing && existing["Needed by"] <= date) continue;
      const request = requests.get(ref) ?? {};
      const minimumLength = Number(scene.source_start_seconds ?? 0) + Number(scene.duration_seconds ?? 0);
      rows.set(ref, {
        Status: verified.has(ref) ? "In library" : "Missing - record and upload",
        "Upload as": `${ref.slice("requested:".length)}.mp4`,
        "Needed by": date,
        "GymFeed feature": request.feature ?? plan.product_feature ?? "",
        "What to record": request.shot_instructions ?? scene.action ?? scene.purpose ?? "",
        "Target length (s)": request.target_duration_seconds ?? Math.ceil(Math.max(minimumLength, Number(scene.source_duration_seconds ?? 0))),
        "Why a new recording": request.why_library_insufficient ?? "",
        Idea: plan.review_brief?.title ?? plan.topic ?? content.topic ?? "",
        "Idea status": idea.idea_status ?? "",
        "Drive folder": uploadFolderUrl,
        "Capture ref": ref,
      });
    }
  }
  return [...rows.values()].sort((a, b) => (a.Status === b.Status ? 0 : a.Status.startsWith("Missing") ? -1 : 1)
    || a["Needed by"].localeCompare(b["Needed by"]));
}
