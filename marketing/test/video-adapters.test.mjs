import test from "node:test";
import assert from "node:assert/strict";
import { FalMediaProvider } from "../src/providers/fal.mjs";

function provider(family) {
  return new FalMediaProvider({ apiKey: "test", client: { config() {} },
    videoModel: `${family}/text-to-video`, referenceVideoModel: `${family}/reference-to-video`, videoResolution: "1080p" });
}

test("Wan binds multiple cast references and uses its audio and numeric duration fields", () => {
  const task = provider("alibaba/wan-3.0").prepareTask({ prompt: "<IMAGE_REF_0> speaks to <IMAGE_REF_1>", durationSeconds: 4.2,
    generateAudio: true, referenceImageUrls: ["first", "second"] });
  assert.equal(task.model, "alibaba/wan-3.0/reference-to-video");
  assert.equal(task.durationSeconds, 5);
  assert.equal(task.input.duration, 5);
  assert.equal(task.input.audio, true);
  assert.equal(task.input.prompt, "Image 1 speaks to Image 2");
  assert.equal(task.input.generate_audio, undefined);
  assert.deepEqual(task.input.reference_image_urls, ["first", "second"]);
  assert.equal(task.input.image_urls, undefined);
});

test("Seedance rewrites ordered cast tokens and keeps the entire requested cut", () => {
  const task = provider("bytedance/seedance-2.0").prepareTask({ prompt: "<IMAGE_REF_0> replies to Image 2", durationSeconds: 3,
    generateAudio: true, referenceImageUrls: ["first", "second"] });
  assert.equal(task.input.prompt, "@Image1 replies to @Image2");
  assert.equal(task.input.duration, "4");
  assert.equal(task.input.generate_audio, true);
  assert.deepEqual(task.input.image_urls, ["first", "second"]);
});
