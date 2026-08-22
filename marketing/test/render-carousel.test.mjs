import test from "node:test";
import assert from "node:assert/strict";
import sharp from "sharp";
import { renderCarouselSlide } from "../src/render-carousel.mjs";

test("carousel renderer creates the required Instagram dimensions", async () => {
  const background = await sharp({
    create: { width: 320, height: 400, channels: 3, background: "#34505f" },
  }).png().toBuffer();
  const output = await renderCarouselSlide({
    background,
    headline: "Train with a plan",
    body: "A useful GymFeed test slide.",
    index: 0,
    total: 3,
  });
  const metadata = await sharp(output).metadata();
  assert.equal(metadata.width, 1080);
  assert.equal(metadata.height, 1350);
  assert.equal(metadata.format, "png");
});
