import test from "node:test";
import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdtemp, mkdir, readFile, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { tmpdir } from "node:os";
import sharp from "sharp";
import { CaptureIngestor, driveFolderId } from "../src/capture-ingest.mjs";

function fakeClient(files, folderFiles = []) {
  return {
    async request({ url, params }) {
      if (url.endsWith("/files") && params.q) return { data: { files: folderFiles } };
      const id = decodeURIComponent(url.split("/").at(-1));
      const file = files[id];
      if (!file) throw new Error(`Missing test Drive file ${id}`);
      if (params.alt === "media") return { data: file.buffer };
      return { data: { id, name: file.name, mimeType: file.mimeType, size: String(file.buffer.length) } };
    },
  };
}

test("Drive re-import preserves a verified privacy derivative and rejects changed or tampered files", async () => {
  const root = await mkdtemp(join(tmpdir(), "gymfeed-private-capture-"));
  const source = Buffer.from("original recording");
  const sanitized = Buffer.from("privacy-cleared recording");
  const hash = (buffer) => createHash("sha256").update(buffer).digest("hex");
  const entry = { id: "requested:proof", filename: "proof-private.mp4", source_sha256: hash(source), sha256: hash(sanitized), verified: true, marketing_safe: true, duration_seconds: 9, recorded_interactions: ["Start workout"] };
  const manifest = JSON.stringify({ version: 1, captures: [entry] });
  await writeFile(join(root, "manifest.json"), manifest);
  await writeFile(join(root, entry.filename), sanitized);
  const files = { video: { name: "proof.mp4", mimeType: "video/mp4", buffer: source } };
  const ingestor = new CaptureIngestor({ root, clientFactory: async () => fakeClient(files), probeDuration: async () => { throw new Error("Must reuse verified derivative"); } });
  const input = { driveFileId: "video", captureRef: entry.id, filename: "proof.mp4", feature: "train", description: "Train", recordedInteractions: ["Start workout"] };
  assert.deepEqual(await ingestor.import(input), entry);
  assert.equal(await readFile(join(root, "manifest.json"), "utf8"), manifest);
  files.video.buffer = Buffer.from("changed source");
  await assert.rejects(ingestor.import(input), /privacy verification is required/);
  files.video.buffer = source;
  await writeFile(join(root, entry.filename), Buffer.from("tampered derivative"));
  await assert.rejects(ingestor.import(input), /changed after verification/);
  assert.equal(await readFile(join(root, "manifest.json"), "utf8"), manifest);
});

test("automatic plan intake resolves exact approved assets from the Drive folder", async () => {
  assert.equal(driveFolderId("https://drive.google.com/drive/folders/folder_123"), "folder_123");
  const temp = await mkdtemp(join(tmpdir(), "gymfeed-plan-intake-"));
  const captureRoot = join(temp, "captures");
  const screenshotRoot = join(temp, "screenshots");
  await mkdir(captureRoot, { recursive: true });
  await mkdir(join(screenshotRoot, "curated"), { recursive: true });
  await writeFile(join(captureRoot, "manifest.json"), JSON.stringify({ version: 1, captures: [] }));
  await writeFile(join(screenshotRoot, "manifest.json"), JSON.stringify({
    version: 1, screenshots: [{ filename: "curated/proof.png", marketing_safe: true }],
  }));
  const png = await sharp({ create: { width: 20, height: 30, channels: 3, background: "#00ff66" } }).png().toBuffer();
  const files = {
    video: { name: "native-proof.mp4", mimeType: "video/mp4", buffer: Buffer.from("video") },
    image: { name: "proof.png", mimeType: "image/png", buffer: png },
  };
  const listed = Object.entries(files).map(([id, file]) => ({ id, name: file.name, mimeType: file.mimeType, size: file.buffer.length }));
  const ingestor = new CaptureIngestor({
    root: captureRoot,
    screenshotRoot,
    clientFactory: async () => fakeClient(files, listed),
    probeDuration: async () => 8.5,
  });
  const imported = await ingestor.importApprovedPlan({
    driveFolderUrl: "https://drive.google.com/drive/folders/folder_123",
    plan: {
      product_features: ["scan_equipment"],
      screenshot_refs: ["curated/proof.png"],
      scenes: [{ scene_id: "native", asset_type: "app_capture", capture_ref: "requested:native-proof", action: "capture equipment photo" }],
    },
  });
  assert.equal(imported.captures[0].filename, "native-proof.mp4");
  assert.equal(imported.images[0].screenshot_ref, "curated/proof.png");
});

test("automatic plan intake gives a reviewable block reason when required Drive video is missing", async () => {
  const ingestor = new CaptureIngestor({ clientFactory: async () => fakeClient({}, []) });
  await assert.rejects(ingestor.importApprovedPlan({
    driveFolderUrl: "https://drive.google.com/drive/folders/folder_123",
    plan: { scenes: [{ asset_type: "app_capture", capture_ref: "requested:missing", action: "show result" }] },
  }), /Required Drive video is missing: missing\.mp4/);
});

test("Drive intake persists and verifies the approved video and screenshots", async () => {
  const temp = await mkdtemp(join(tmpdir(), "gymfeed-capture-"));
  const captureRoot = join(temp, "captures");
  const screenshotRoot = join(temp, "screenshots");
  await mkdir(captureRoot, { recursive: true });
  await mkdir(join(screenshotRoot, "curated"), { recursive: true });
  await writeFile(join(captureRoot, "manifest.json"), JSON.stringify({ version: 1, captures: [] }));
  await writeFile(join(screenshotRoot, "manifest.json"), JSON.stringify({
    version: 1,
    screenshots: [{ filename: "curated/proof.png", feature: "train", marketing_safe: true }],
  }));
  const png = await sharp({ create: { width: 32, height: 48, channels: 3, background: "#00ff66" } }).png().toBuffer();
  const video = Buffer.from("test-mp4-bytes");
  const client = fakeClient({
    video: { name: "proof.mp4", mimeType: "video/mp4", buffer: video },
    image: { name: "proof.png", mimeType: "image/png", buffer: png },
  });
  const ingestor = new CaptureIngestor({
    root: captureRoot,
    screenshotRoot,
    clientFactory: async () => client,
    probeDuration: async () => 9.25,
  });

  const capture = await ingestor.import({
    driveFileId: "video",
    captureRef: "requested:proof",
    filename: "proof.mp4",
    feature: "Train",
    description: "Native Train proof",
    recordedInteractions: ["tap Start workout"],
  });
  const images = await ingestor.importScreenshots([{ driveFileId: "image", screenshotRef: "curated/proof.png" }]);

  assert.equal(capture.duration_seconds, 9.25);
  assert.equal(images[0].width, 32);
  assert.equal(images[0].height, 48);
  assert.deepEqual(await readFile(join(captureRoot, "proof.mp4")), video);
  assert.deepEqual(await readFile(join(screenshotRoot, "curated", "proof.png")), png);
  const screenshotManifest = JSON.parse(await readFile(join(screenshotRoot, "manifest.json"), "utf8"));
  assert.equal(screenshotManifest.screenshots[0].filename, "curated/proof.png");
  assert.equal(screenshotManifest.screenshots[0].drive_filename, "proof.png");
  assert.equal(screenshotManifest.screenshots[0].drive_file_id, "image");
  assert.match(screenshotManifest.screenshots[0].sha256, /^[a-f0-9]{64}$/);
});

test("Drive intake rejects unapproved or mismatched screenshots", async () => {
  const temp = await mkdtemp(join(tmpdir(), "gymfeed-capture-"));
  const captureRoot = join(temp, "captures");
  const screenshotRoot = join(temp, "screenshots");
  await mkdir(captureRoot, { recursive: true });
  await mkdir(join(screenshotRoot, "curated"), { recursive: true });
  await writeFile(join(screenshotRoot, "manifest.json"), JSON.stringify({
    version: 1,
    screenshots: [{ filename: "curated/private.png", marketing_safe: false }],
  }));
  const ingestor = new CaptureIngestor({ root: captureRoot, screenshotRoot, clientFactory: async () => fakeClient({}) });
  await assert.rejects(
    ingestor.importScreenshots([{ driveFileId: "private", screenshotRef: "curated/private.png" }]),
    /not approved/,
  );
  await assert.rejects(
    ingestor.importScreenshots([{ driveFileId: "outside", screenshotRef: "..\/outside.png" }]),
    /curated/,
  );
});
