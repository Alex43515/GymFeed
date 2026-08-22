import test from "node:test";
import assert from "node:assert/strict";
import { BytePlusVideoProvider } from "../src/providers/byteplus.mjs";
import { BlotatoPublisher } from "../src/providers/blotato.mjs";

test("BytePlus request is constrained to one vertical Seedance task", async (t) => {
  let request;
  const originalFetch = globalThis.fetch;
  t.after(() => { globalThis.fetch = originalFetch; });
  globalThis.fetch = async (url, options) => {
    request = { url, options, body: JSON.parse(options.body) };
    return new Response(JSON.stringify({ id: "task-1", status: "queued" }), { status: 200 });
  };
  const provider = new BytePlusVideoProvider({
    apiKey: "key",
    baseUrl: "https://byteplus.example/api/v3",
    model: "dreamina-seedance-2-0-260128",
    resolution: "720p",
    watermark: true,
  });
  const result = await provider.createTask({ prompt: "Safe gym scene", durationSeconds: 30, generateAudio: true });
  assert.equal(result.id, "task-1");
  assert.equal(request.body.ratio, "9:16");
  assert.equal(request.body.duration, 15);
  assert.equal(request.body.return_last_frame, true);
  assert.equal(request.body.model, "dreamina-seedance-2-0-260128");
});

test("Blotato marks TikTok content as AI-generated and first-party branded", async (t) => {
  let payload;
  const originalFetch = globalThis.fetch;
  t.after(() => { globalThis.fetch = originalFetch; });
  globalThis.fetch = async (_url, options) => {
    payload = JSON.parse(options.body);
    return new Response(JSON.stringify({ postSubmissionId: "post-1" }), { status: 200 });
  };
  const publisher = new BlotatoPublisher({ apiKey: "key", baseUrl: "https://blotato.example/v2" });
  await publisher.publish({
    platform: "tiktok",
    accountId: "account-1",
    text: "GymFeed test",
    mediaUrls: ["https://cdn.example/video"],
    isVideo: true,
  });
  assert.equal(payload.post.target.isAiGenerated, true);
  assert.equal(payload.post.target.isYourBrand, true);
  assert.equal(payload.post.target.privacyLevel, "PUBLIC_TO_EVERYONE");
});

test("Blotato explicitly publishes generated Instagram video as a reel", async (t) => {
  let payload;
  const originalFetch = globalThis.fetch;
  t.after(() => { globalThis.fetch = originalFetch; });
  globalThis.fetch = async (_url, options) => {
    payload = JSON.parse(options.body);
    return new Response(JSON.stringify({ postSubmissionId: "post-1" }), { status: 200 });
  };
  const publisher = new BlotatoPublisher({ apiKey: "key", baseUrl: "https://blotato.example/v2" });
  await publisher.publish({
    platform: "instagram",
    accountId: "account-1",
    text: "GymFeed test",
    mediaUrls: ["https://blotato.example/media/opaque-id"],
    isVideo: true,
  });
  assert.equal(payload.post.target.mediaType, "reel");
});
