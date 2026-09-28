import { createHash } from "node:crypto";
import { execFile } from "node:child_process";
import { readFile, rename, writeFile } from "node:fs/promises";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";
import { basename, extname, resolve } from "node:path";
import { GoogleAuth } from "google-auth-library";
import sharp from "sharp";
import { resolveAppCapture } from "./app-captures.mjs";

const execFileAsync = promisify(execFile);
const defaultRoot = fileURLToPath(new URL("../../docs/marketing/app-captures/", import.meta.url));
const defaultScreenshotRoot = fileURLToPath(new URL("../../docs/marketing/screenshots/", import.meta.url));
const imageMimeByExtension = new Map([
  [".png", "image/png"],
  [".jpg", "image/jpeg"],
  [".jpeg", "image/jpeg"],
  [".webp", "image/webp"],
]);

function required(value, name) {
  if (typeof value !== "string" || !value.trim()) throw new Error(`${name} is required`);
  return value.trim();
}

export function driveFolderId(value) {
  const text = required(value, "Google Drive upload folder URL");
  const match = text.match(/\/folders\/([A-Za-z0-9_-]+)/);
  if (!match) throw new Error("Google Drive upload folder URL must contain a folder ID");
  return match[1];
}

export class CaptureIngestor {
  constructor({ credentialsPath, root = defaultRoot, screenshotRoot = defaultScreenshotRoot, clientFactory = null, probeDuration = null }) {
    this.credentialsPath = credentialsPath;
    this.root = root;
    this.screenshotRoot = screenshotRoot;
    this.clientFactory = clientFactory;
    this.probeDuration = probeDuration ?? (async (path) => {
      const { stdout } = await execFileAsync("ffprobe", ["-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", path]);
      return Number(stdout.trim());
    });
  }

  async driveClient() {
    if (this.clientFactory) return this.clientFactory();
    if (!this.credentialsPath) throw new Error("Google Drive credentials are not configured");
    const auth = new GoogleAuth({ keyFilename: this.credentialsPath, scopes: ["https://www.googleapis.com/auth/drive.readonly"] });
    return auth.getClient();
  }

  async download(driveFileId) {
    driveFileId = required(driveFileId, "driveFileId");
    const client = await this.driveClient();
    const url = `https://www.googleapis.com/drive/v3/files/${encodeURIComponent(driveFileId)}`;
    const metadata = await client.request({ url, params: { fields: "id,name,mimeType,size" } });
    if (Number(metadata.data.size ?? 0) > 500 * 1024 * 1024) throw new Error("Drive asset exceeds the 500 MB intake limit");
    const response = await client.request({ url, params: { alt: "media" }, responseType: "arraybuffer" });
    const buffer = Buffer.from(response.data);
    if (!buffer.length) throw new Error("Drive asset is empty");
    return { metadata: metadata.data, buffer };
  }

  async listFolder(folderUrl) {
    const folderId = driveFolderId(folderUrl);
    const client = await this.driveClient();
    const response = await client.request({
      url: "https://www.googleapis.com/drive/v3/files",
      params: {
        q: `'${folderId}' in parents and trashed = false`,
        fields: "files(id,name,mimeType,size,modifiedTime)",
        orderBy: "modifiedTime desc",
        pageSize: 1000,
        supportsAllDrives: true,
        includeItemsFromAllDrives: true,
      },
    });
    return response.data.files ?? [];
  }

  async importApprovedPlan({ driveFolderUrl, plan }) {
    if (!plan || typeof plan !== "object") throw new Error("Approved content plan is required for Drive intake");
    const captureScenes = (plan.scenes ?? []).filter((scene) => scene.asset_type === "app_capture" && String(scene.capture_ref ?? "").startsWith("requested:"));
    const screenshotRefs = [...new Set([
      ...(plan.screenshot_refs ?? []),
      ...(plan.scenes ?? []).map((scene) => scene.screenshot_ref).filter(Boolean),
      ...(plan.slides ?? []).map((slide) => slide.screenshot_ref).filter(Boolean),
    ])];
    if (!captureScenes.length && !screenshotRefs.length) return { captures: [], images: [] };

    const files = await this.listFolder(driveFolderUrl);
    const findFile = (filename, mimeType) => files.find((file) => file.mimeType === mimeType
      && (file.name === filename || `${file.name}${extname(filename)}` === filename));
    const captures = [];
    const seenCaptures = new Set();
    for (const scene of captureScenes) {
      if (seenCaptures.has(scene.capture_ref)) continue;
      seenCaptures.add(scene.capture_ref);
      const filename = `${scene.capture_ref.slice("requested:".length)}.mp4`;
      const file = findFile(filename, "video/mp4");
      if (!file) throw new Error(`Required Drive video is missing: ${filename}`);
      captures.push(await this.import({
        driveFileId: file.id,
        captureRef: scene.capture_ref,
        filename,
        feature: plan.product_feature ?? plan.product_features?.[0] ?? scene.scene_id ?? "GymFeed app capture",
        description: scene.continuity_notes ?? scene.action ?? `Approved app capture ${scene.capture_ref}`,
        recordedInteractions: [scene.action ?? scene.purpose ?? `show ${scene.capture_ref}`],
      }));
    }

    const images = [];
    for (const screenshotRef of screenshotRefs) {
      const filename = basename(screenshotRef);
      const mimeType = imageMimeByExtension.get(extname(filename).toLowerCase());
      const file = mimeType ? findFile(filename, mimeType) : null;
      // Approved screenshots already in the local manifest remain valid. When a
      // Drive copy exists, refresh it before generation so the worker uses it.
      if (file) images.push({ driveFileId: file.id, screenshotRef });
    }
    return { captures, images: await this.importScreenshots(images) };
  }

  async import({ driveFileId, captureRef, filename, feature, description, recordedInteractions }) {
    driveFileId = required(driveFileId, "driveFileId");
    captureRef = required(captureRef, "captureRef");
    filename = required(filename, "filename");
    if (!captureRef.startsWith("requested:")) throw new Error("captureRef must start with requested:");
    if (basename(filename) !== filename || !filename.toLowerCase().endsWith(".mp4")) throw new Error("filename must be a plain .mp4 file name");
    if (`${captureRef.slice("requested:".length)}.mp4` !== filename) throw new Error("filename must exactly match captureRef");
    if (!Array.isArray(recordedInteractions) || !recordedInteractions.length || recordedInteractions.some((item) => typeof item !== "string" || !item.trim())) {
      throw new Error("recordedInteractions must contain at least one description");
    }
    const { metadata, buffer } = await this.download(driveFileId);
    if (metadata.mimeType !== "video/mp4") throw new Error(`Drive file must be video/mp4, received ${metadata.mimeType}`);
    const driveName = String(metadata.name ?? "");
    if (driveName !== filename && `${driveName}.mp4` !== filename) throw new Error(`Drive file name must be ${filename}`);
    const manifestPath = resolve(this.root, "manifest.json");
    const manifest = JSON.parse(await readFile(manifestPath, "utf8"));
    const previous = (manifest.captures ?? []).find((item) => item.id === captureRef);
    if (previous?.source_sha256) {
      // Re-importing the same source must not discard its verified privacy edit.
      if (createHash("sha256").update(buffer).digest("hex") !== previous.source_sha256) {
        throw new Error(`Recording ${captureRef} changed; privacy verification is required before replacing its sanitized copy`);
      }
      await resolveAppCapture(captureRef, this.root);
      return previous;
    }
    const target = resolve(this.root, filename);
    const temporary = `${target}.incoming`;
    await writeFile(temporary, buffer);
    const duration = Number(await this.probeDuration(temporary));
    if (!Number.isFinite(duration) || duration <= 0) throw new Error("Unable to determine recording duration");
    await rename(temporary, target);

    const entry = {
      id: captureRef,
      filename,
      feature: required(feature, "feature"),
      description: required(description, "description"),
      duration_seconds: duration,
      recorded_interactions: recordedInteractions.map((item) => item.trim()),
      verified: true,
      marketing_safe: true,
      sha256: createHash("sha256").update(buffer).digest("hex"),
      drive_file_id: driveFileId,
    };
    const index = (manifest.captures ?? []).findIndex((item) => item.id === captureRef);
    if (index >= 0) manifest.captures[index] = entry;
    else (manifest.captures ??= []).push(entry);
    await writeFile(`${manifestPath}.incoming`, `${JSON.stringify(manifest, null, 2)}\n`);
    await rename(`${manifestPath}.incoming`, manifestPath);
    return entry;
  }

  async importScreenshots(images = []) {
    if (!Array.isArray(images)) throw new Error("images must be an array");
    if (!images.length) return [];
    const manifestPath = resolve(this.screenshotRoot, "manifest.json");
    const manifest = JSON.parse(await readFile(manifestPath, "utf8"));
    const imported = [];

    for (const image of images) {
      const driveFileId = required(image.driveFileId, "image.driveFileId");
      const screenshotRef = required(image.screenshotRef, "image.screenshotRef");
      const filename = basename(screenshotRef);
      if (screenshotRef !== `curated/${filename}`) throw new Error("screenshotRef must use a plain curated/ filename");
      const expectedMime = imageMimeByExtension.get(extname(filename).toLowerCase());
      if (!expectedMime) throw new Error(`Unsupported screenshot extension: ${filename}`);
      const entry = (manifest.screenshots ?? []).find((candidate) => candidate.filename === screenshotRef);
      if (!entry || entry.marketing_safe !== true) throw new Error(`Screenshot is not approved in the current-build manifest: ${screenshotRef}`);

      const { metadata, buffer } = await this.download(driveFileId);
      if (metadata.mimeType !== expectedMime) throw new Error(`Drive screenshot ${filename} must be ${expectedMime}, received ${metadata.mimeType}`);
      const driveName = String(metadata.name ?? "");
      if (driveName !== filename && `${driveName}${extname(filename)}` !== filename) throw new Error(`Drive file name must be ${filename}`);
      const dimensions = await sharp(buffer).metadata();
      if (!dimensions.width || !dimensions.height) throw new Error(`Drive screenshot is not a readable image: ${filename}`);

      const target = resolve(this.screenshotRoot, screenshotRef);
      await writeFile(`${target}.incoming`, buffer);
      await rename(`${target}.incoming`, target);
      const result = {
        screenshot_ref: screenshotRef,
        filename: screenshotRef,
        drive_filename: filename,
        width: dimensions.width,
        height: dimensions.height,
        sha256: createHash("sha256").update(buffer).digest("hex"),
        drive_file_id: driveFileId,
      };
      Object.assign(entry, result);
      imported.push(result);
    }

    await writeFile(`${manifestPath}.incoming`, `${JSON.stringify(manifest, null, 2)}\n`);
    await rename(`${manifestPath}.incoming`, manifestPath);
    return imported;
  }
}
