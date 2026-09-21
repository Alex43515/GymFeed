import test from "node:test";
import assert from "node:assert/strict";
import {
  verifiedScreenshotCatalog,
  verifiedScreenshotManifest,
  verifiedScreenshotUrl,
} from "../src/product-brief.mjs";

test("verified screenshot catalog exposes only semantically classified marketing-safe captures", async () => {
  const manifest = await verifiedScreenshotManifest();
  const catalog = await verifiedScreenshotCatalog();

  assert.ok(manifest.length >= 10);
  assert.ok(!catalog.includes("curated/gymfeed-coach-hub.png"));
  assert.ok(catalog.includes("curated/gymfeed-nutrition-meal-plan.png"));
  assert.ok(catalog.includes("curated/gymfeed-scan-equipment-result.jpeg"));
  assert.ok(!catalog.includes("curated/gymfeed-profile.png"));
  assert.ok(manifest.every((entry) => entry.feature && entry.description && entry.approved_claims.length));

  const url = await verifiedScreenshotUrl("curated/gymfeed-nutrition-meal-plan.png");
  assert.match(url.pathname, /docs\/marketing\/screenshots\/curated\/gymfeed-nutrition-meal-plan\.png$/);
  await assert.rejects(() => verifiedScreenshotUrl("gymfeed_20260829_120110_328.png"), /Unverified GymFeed screenshot/);
});
