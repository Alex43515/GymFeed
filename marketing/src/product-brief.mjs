import { readFile, readdir } from "node:fs/promises";
import { extname } from "node:path";

const briefUrl = new URL("../../docs/GYMFEED_MARKETING_PRODUCT_BRIEF.md", import.meta.url);
const screenshotDirectoryUrl = new URL("../../docs/marketing/screenshots/", import.meta.url);
const screenshotManifestUrl = new URL("../../docs/marketing/screenshots/manifest.json", import.meta.url);
const referenceScreenshotDirectoryUrl = new URL("../../docs/marketing/reference-screens/", import.meta.url);
const imageExtensions = new Set([".png", ".jpg", ".jpeg", ".webp"]);

let briefPromise;
let screenshotManifestPromise;

export function loadProductBrief() {
  briefPromise ??= readFile(briefUrl, "utf8");
  return briefPromise;
}

export function loadScreenshotManifest() {
  screenshotManifestPromise ??= readFile(screenshotManifestUrl, "utf8").then((value) => JSON.parse(value));
  return screenshotManifestPromise;
}

export async function verifiedScreenshotManifest() {
  const manifest = await loadScreenshotManifest();
  return manifest.screenshots
    .filter((entry) => entry.marketing_safe === true)
    .map(({ filename, feature, title, description, approved_claims }) => ({
      filename,
      feature,
      title,
      description,
      approved_claims,
    }));
}

export async function verifiedScreenshotCatalog() {
  const manifest = await verifiedScreenshotManifest();
  return manifest.map((entry) => entry.filename).sort();
}

export async function verifiedScreenshotUrl(filename) {
  if (!filename) return null;
  const catalog = await verifiedScreenshotCatalog();
  if (!catalog.includes(filename)) throw new Error(`Unverified GymFeed screenshot: ${filename}`);
  return new URL(filename, screenshotDirectoryUrl);
}

export async function referenceScreenshotCatalog() {
  const entries = await readdir(referenceScreenshotDirectoryUrl, { withFileTypes: true });
  return entries
    .filter((entry) => entry.isFile() && imageExtensions.has(extname(entry.name).toLowerCase()))
    .map((entry) => entry.name)
    .sort();
}

export async function referenceScreenshotUrl(filename) {
  if (!filename) return null;
  const catalog = await referenceScreenshotCatalog();
  if (!catalog.includes(filename)) throw new Error(`Unknown GymFeed reference screen: ${filename}`);
  return new URL(filename, referenceScreenshotDirectoryUrl);
}
