import { readFile, realpath } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { resolve, relative, isAbsolute } from "node:path";
import { createHash } from "node:crypto";

const directory = fileURLToPath(new URL("../../docs/marketing/app-captures/", import.meta.url));

export async function appCaptureCatalog(root = directory) {
  let manifest;
  try { manifest = JSON.parse(await readFile(resolve(root, "manifest.json"), "utf8")); }
  catch (error) { if (error.code === "ENOENT") return []; throw error; }
  return (manifest.captures ?? []).filter((item) => item.marketing_safe === true && item.verified === true);
}

export async function resolveAppCapture(ref, root = directory) {
  const catalog = await appCaptureCatalog(root);
  const entry = catalog.find((item) => item.id === ref);
  if (!entry) throw new Error(`Missing verified app recording: ${ref}. Register a clean demo recording in docs/marketing/app-captures/manifest.json`);
  if (!entry.recorded_interactions?.length || !(entry.duration_seconds > 0) || !/^[a-f0-9]{64}$/i.test(entry.sha256 ?? "")) {
    throw new Error(`Incomplete verification metadata for app recording: ${ref}`);
  }
  const base = await realpath(root);
  const path = await realpath(resolve(base, entry.filename));
  const within = relative(base, path);
  if (!within || within.startsWith("..") || isAbsolute(within)) throw new Error("App recording must remain inside its approved directory");
  const buffer = await readFile(path);
  if (createHash("sha256").update(buffer).digest("hex") !== entry.sha256.toLowerCase()) throw new Error(`App recording changed after verification: ${ref}`);
  return { ...entry, path, buffer };
}

export async function preflightAppCaptures(plan, resolver = resolveAppCapture) {
  if (plan.production_version === 2 && !(plan.scenes ?? []).some((scene) => scene.asset_type === "app_capture")) {
    throw new Error("Product-use video requires a verified app recording before generation");
  }
  for (const scene of plan.scenes ?? []) {
    if (scene.asset_type !== "app_capture") continue;
    const capture = await resolver(scene.capture_ref);
    const start = scene.source_start_seconds ?? 0;
    if (start < 0 || start + scene.duration_seconds > capture.duration_seconds + 0.05) throw new Error(`App recording ${scene.capture_ref} is too short for scene ${scene.scene_id}`);
  }
}
