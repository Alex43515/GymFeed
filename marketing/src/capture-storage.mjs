import { execFile } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdtemp, rm, rmdir, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import { resolveAppCapture } from "./app-captures.mjs";

const run = promisify(execFile);
export const CAPTURE_BUCKET = "marketing-captures";
export const UPLOAD_LIMIT = 50 * 1024 * 1024;
const refPattern = /^requested:([a-z0-9-]+)$/;
const sha256 = buffer => createHash("sha256").update(buffer).digest("hex");
const statusError = (message, statusCode) => Object.assign(new Error(message), { statusCode });

export function requestedCaptures(plan) {
  return [...new Set((plan?.scenes ?? [])
    .filter(scene => scene.asset_type === "app_capture" && refPattern.test(scene.capture_ref))
    .map(scene => scene.capture_ref))];
}

export async function probeMp4(buffer) {
  const dir = await mkdtemp(join(tmpdir(), "gymfeed-video-"));
  const path = join(dir, "source.mp4");
  try {
    await writeFile(path, buffer);
    const { stdout } = await run("ffprobe", ["-v", "error", "-select_streams", "v:0",
      "-show_entries", "stream=width,height:format=duration,format_name:format_tags=major_brand", "-of", "json", path], { timeout: 15000 });
    const { streams, format } = JSON.parse(stdout);
    const duration = Number(format?.duration);
    if (!streams?.[0] || !format?.format_name?.split(",").includes("mp4") ||
      !format.tags?.major_brand || format.tags.major_brand.trim() === "qt" || !(duration > 0)) throw new Error("Invalid MP4");
    return { duration, width: streams[0].width, height: streams[0].height };
  } catch (error) {
    if (error.code === "ENOENT") throw error;
    throw statusError("Fajl mora da bude čitljiv MP4 video.", 400);
  } finally {
    await rm(path, { force: true });
    await rmdir(dir);
  }
}

export class CaptureStorage {
  constructor(storage) {
    this.bucket = storage.from(CAPTURE_BUCKET);
  }

  async info(ref) {
    const name = refPattern.exec(ref)?.[1];
    if (!name) return null;
    const filename = name + ".mp4";
    const { data, error } = await this.bucket.info(filename);
    if (error) {
      if ([error.status, error.statusCode].some(code => Number(code) === 404)) return null;
      throw new Error("Supabase snimci: " + error.message);
    }
    const entry = data.metadata?.capture;
    if (!entry?.verified || !entry.recordedInteractions?.length || !(entry.durationSeconds > 0) ||
      !/^[a-f0-9]{64}$/.test(entry.sha256 ?? "")) throw new Error("Missing verification metadata for app recording: " + ref);
    return { id: ref, filename, sha256: entry.sha256, duration_seconds: entry.durationSeconds,
      recorded_interactions: entry.recordedInteractions, feature: entry.feature, verified: true, marketing_safe: true };
  }

  async save(ref, buffer, { feature, actions }) {
    const hash = sha256(buffer);
    const existing = await this.info(ref);
    if (existing?.sha256 === hash) return existing;
    if (existing) throw statusError("Za ovu ideju već postoji drugi verifikovan snimak.", 409);
    const { duration } = await probeMp4(buffer);
    const filename = refPattern.exec(ref)[1] + ".mp4";
    const { error } = await this.bucket.upload(filename, buffer, { contentType: "video/mp4",
      upsert: false, metadata: { capture: { verified: true, sha256: hash, durationSeconds: duration, feature, recordedInteractions: actions } } });
    if (error) {
      const concurrent = await this.info(ref);
      if (concurrent?.sha256 === hash) return concurrent;
      if (concurrent) throw statusError("Za ovu ideju već postoji drugi verifikovan snimak.", 409);
      throw new Error("Supabase upload: " + error.message);
    }
    return this.info(ref);
  }

  async resolve(ref) {
    const entry = await this.info(ref);
    if (!entry) return resolveAppCapture(ref);
    const { data, error } = await this.bucket.download(entry.filename);
    if (error) throw new Error("Supabase snimci: " + error.message);
    const buffer = Buffer.from(await data.arrayBuffer());
    if (sha256(buffer) !== entry.sha256) throw new Error("App recording changed after verification: " + ref);
    return { ...entry, buffer };
  }
}
