import { createHash } from "node:crypto";
import { readFile, rename, rm, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { resolve } from "node:path";
import { extractVideoContactSheet } from "./extract-video-frame.mjs";
import { libraryCatalog } from "./asset-library.mjs";

const defaultRoot = fileURLToPath(new URL("../../docs/marketing/app-captures/", import.meta.url));

export const LIBRARY_HEADERS = [
  "Verify", "Status", "File", "Feature", "Description", "Recorded interactions", "Duration (s)",
  "Privacy notes", "AI says usable", "Times used", "Last used", "Capture ID", "Drive file ID", "Result",
];
export const LIBRARY_EDITABLE = ["Verify", "Feature", "Description", "Recorded interactions"];
export const LIBRARY_CHOICES = ["Pending", "Verify", "Reject"];

export function librarySlug(name, taken = new Set()) {
  const base = String(name ?? "").replace(/\.[^.]+$/, "").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "").slice(0, 60) || "recording";
  let slug = base;
  for (let n = 2; taken.has(`library:${slug}`); n += 1) slug = `${base}-${n}`;
  return slug;
}

async function readJson(path, fallback) {
  try { return JSON.parse(await readFile(path, "utf8")); }
  catch (error) { if (error.code === "ENOENT") return fallback; throw error; }
}

async function writeJson(path, value) {
  await writeFile(`${path}.incoming`, `${JSON.stringify(value, null, 2)}\n`);
  await rename(`${path}.incoming`, path);
}

// Unsolicited recordings dropped into the Drive upload folder. Each one gets an
// AI-drafted description, and enters the verified library only after the owner
// marks it Verify in the Library tab.
export class LibraryInbox {
  constructor({ ingestor, brain, repository, config, root = defaultRoot, contactSheet = extractVideoContactSheet, maxNewPerRun = 3 }) {
    Object.assign(this, { ingestor, brain, repository, config, root, contactSheet, maxNewPerRun });
    this.inboxPath = resolve(root, "library-inbox.json");
    this.manifestPath = resolve(root, "manifest.json");
  }

  get configured() {
    return Boolean(this.config.GOOGLE_DRIVE_ASSET_UPLOAD_URL && this.ingestor && this.brain);
  }

  async state() {
    const [inbox, manifest] = await Promise.all([readJson(this.inboxPath, { version: 1, items: [] }), readJson(this.manifestPath, { version: 1, captures: [] })]);
    return { inbox, manifest };
  }

  async applyDecisions(sheetRows) {
    const { inbox, manifest } = await this.state();
    const results = [];
    for (const row of sheetRows) {
      const item = inbox.items.find((candidate) => candidate.id === row["Capture ID"] && candidate.status === "pending");
      const choice = String(row.Verify ?? "").trim();
      if (!item || !["Verify", "Reject"].includes(choice)) continue;
      if (choice === "Reject") {
        await rm(resolve(this.root, item.filename), { force: true });
        Object.assign(item, { status: "rejected", decided_at: new Date().toISOString() });
        results.push({ id: item.id, status: "rejected" });
        continue;
      }
      const buffer = await readFile(resolve(this.root, item.filename));
      if (createHash("sha256").update(buffer).digest("hex") !== item.sha256) throw new Error(`Library recording ${item.id} changed after its AI description`);
      const interactions = String(row["Recorded interactions"] ?? "").split("\n").map((line) => line.trim()).filter(Boolean);
      const entry = {
        id: item.id,
        filename: item.filename,
        feature: String(row.Feature ?? "").trim() || item.ai.feature,
        description: String(row.Description ?? "").trim() || item.ai.description,
        duration_seconds: item.duration_seconds,
        recorded_interactions: interactions.length ? interactions : item.ai.recorded_interactions,
        verified: true,
        marketing_safe: true,
        sha256: item.sha256,
        drive_file_id: item.drive_file_id,
        source: "library_inbox",
        verified_at: new Date().toISOString(),
      };
      manifest.captures = [...(manifest.captures ?? []).filter((capture) => capture.id !== entry.id), entry];
      Object.assign(item, { status: "verified", decided_at: entry.verified_at });
      results.push({ id: item.id, status: "verified" });
    }
    if (results.length) {
      await writeJson(this.manifestPath, manifest);
      await writeJson(this.inboxPath, inbox);
    }
    return results;
  }

  async scan({ requestedFilenames = new Set() } = {}) {
    const { inbox, manifest } = await this.state();
    const knownDriveIds = new Set([...(manifest.captures ?? []).map((c) => c.drive_file_id), ...inbox.items.map((i) => i.drive_file_id)].filter(Boolean));
    const knownNames = new Set([...(manifest.captures ?? []).flatMap((c) => [c.filename, c.source_filename]), ...requestedFilenames].filter(Boolean));
    const files = (await this.ingestor.listFolder(this.config.GOOGLE_DRIVE_ASSET_UPLOAD_URL))
      .filter((file) => file.mimeType === "video/mp4" && !knownDriveIds.has(file.id) && !knownNames.has(file.name) && !knownNames.has(`${file.name}.mp4`));
    const added = [];
    for (const file of files.slice(0, this.maxNewPerRun)) {
      const taken = new Set([...(manifest.captures ?? []).map((c) => c.id), ...inbox.items.map((i) => i.id)]);
      const slug = librarySlug(file.name, taken);
      const item = { id: `library:${slug}`, filename: `library-${slug}.mp4`, drive_file_id: file.id, drive_name: file.name, status: "pending", added_at: new Date().toISOString() };
      inbox.items.push(item);
      try {
        await this.describe(item);
      } catch (error) {
        Object.assign(item, { status: "error", error: error.message.slice(0, 500) });
        await rm(resolve(this.root, item.filename), { force: true });
      }
      await writeJson(this.inboxPath, inbox);
      added.push(item);
    }
    return { added, remaining: Math.max(0, files.length - this.maxNewPerRun) };
  }

  async describe(item) {
    const { buffer } = await this.ingestor.download(item.drive_file_id);
    const target = resolve(this.root, item.filename);
    await writeFile(target, buffer);
    const duration = Number(await this.ingestor.probeDuration(target));
    if (!Number.isFinite(duration) || duration <= 0) throw new Error("Unable to determine recording duration");
    const frames = 24;
    const contactSheet = await this.contactSheet(buffer, duration, frames);
    const reservation = await this.repository.reserveCost("openai", this.config.OPENAI_ESTIMATED_QA_COST_USD ?? 0.05, { metadata: { operation: "library-describe", drive_file_id: item.drive_file_id } });
    let result;
    try {
      result = await this.brain.describeLibraryCapture({ filename: item.drive_name, durationSeconds: duration, frames, contactSheet });
    } catch (error) {
      if (error.openaiCostUsd != null) await this.repository.settleCost(reservation, error.openaiCostUsd, null);
      else await this.repository.releaseCost(reservation);
      throw error;
    }
    await this.repository.settleCost(reservation, result.costUsd, result.responseId);
    Object.assign(item, { duration_seconds: duration, sha256: createHash("sha256").update(buffer).digest("hex"), ai: result.data });
  }

  async rows(sheetRows = [], contents = []) {
    const { inbox, manifest } = await this.state();
    const previous = new Map(sheetRows.map((row) => [row["Capture ID"], row]));
    const usage = new Map(libraryCatalog(manifest.captures ?? [], contents).map((item) => [item.id, item]));
    const pending = inbox.items.filter((item) => item.status === "pending").map((item) => {
      const old = previous.get(item.id) ?? {};
      return {
        Verify: LIBRARY_CHOICES.includes(old.Verify) ? old.Verify : "Pending",
        Status: "Waiting for your check",
        File: item.drive_name,
        Feature: old.Feature || item.ai.feature,
        Description: old.Description || item.ai.description,
        "Recorded interactions": old["Recorded interactions"] || item.ai.recorded_interactions.join("\n"),
        "Duration (s)": item.duration_seconds?.toFixed(1),
        "Privacy notes": item.ai.privacy_concerns.join("\n") || "None seen",
        "AI says usable": item.ai.usable_for_marketing ? "Yes" : "No",
        "Capture ID": item.id, "Drive file ID": item.drive_file_id,
        Result: "Check the description against the video, edit it if needed, then set Verify or Reject.",
      };
    });
    const errors = inbox.items.filter((item) => item.status === "error").map((item) => ({
      Verify: "", Status: "Could not process", File: item.drive_name, "Capture ID": item.id, "Drive file ID": item.drive_file_id, Result: item.error,
    }));
    const library = (manifest.captures ?? []).filter((c) => c.verified && c.marketing_safe).map((capture) => ({
      Verify: "", Status: "In library", File: capture.source_filename ?? capture.filename, Feature: capture.feature, Description: capture.description,
      "Recorded interactions": (capture.recorded_interactions ?? []).join("\n"), "Duration (s)": Number(capture.duration_seconds).toFixed(1),
      "Times used": usage.get(capture.id)?.times_used ?? 0, "Last used": usage.get(capture.id)?.last_used ?? "",
      "Capture ID": capture.id, "Drive file ID": capture.drive_file_id ?? "",
    }));
    return [...pending, ...errors, ...library];
  }
}
