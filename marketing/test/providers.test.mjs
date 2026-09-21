import test from "node:test";
import assert from "node:assert/strict";
import { FalMediaProvider } from "../src/providers/fal.mjs";
import { BufferPublisher } from "../src/providers/buffer.mjs";
import { OpenAIVoiceProvider } from "../src/providers/openai-voice.mjs";
import { APPROVAL_SHEET_HEADERS, GoogleSheetsApprovalQueue } from "../src/providers/google-sheets.mjs";

function approvalRow(values) {
  const row = Array(APPROVAL_SHEET_HEADERS.length).fill("");
  for (const [header, value] of Object.entries(values)) {
    row[APPROVAL_SHEET_HEADERS.indexOf(header)] = value;
  }
  return row;
}

test("Google Sheet dispatcher reads the decision fields matching each content type", async () => {
  const queue = new GoogleSheetsApprovalQueue({ spreadsheetId: "sheet", auth: {} });
  queue.readRows = async () => [
    approvalRow({
      "Video decision": "Reject",
      "Video instructions": "Show the member arriving at the gym",
      "Carousel decision": "Approve",
      "Carousel instructions": "This must be ignored for a video row",
      "Content type": "video",
      Revision: 2,
      "Content ID": "video-1",
    }),
    approvalRow({
      "Video decision": "Approve",
      "Video instructions": "This must be ignored for a carousel row",
      "Carousel decision": "Reject",
      "Carousel instructions": "Use the verified Train screenshot",
      "Content type": "carousel",
      Revision: 3,
      "Content ID": "carousel-1",
    }),
  ];

  assert.deepEqual(await queue.pendingDecisions(), [
    {
      rowNumber: 2,
      contentId: "video-1",
      contentType: "video",
      revision: 2,
      decision: "Reject",
      instructions: "Show the member arriving at the gym",
    },
    {
      rowNumber: 3,
      contentId: "carousel-1",
      contentType: "carousel",
      revision: 3,
      decision: "Reject",
      instructions: "Use the verified Train screenshot",
    },
  ]);
});

test("OpenAI voice provider creates campaign narration", async () => {
  let request;
  const provider = new OpenAIVoiceProvider({
    apiKey: "key",
    model: "gpt-4o-mini-tts",
    voice: "coral",
    client: {
      audio: {
        speech: {
          create: async (input) => {
            request = input;
            return { arrayBuffer: async () => Buffer.from("voice"), _request_id: "voice-1" };
          },
        },
      },
    },
  });
  const result = await provider.generate({ text: "Start with GymFeed." });
  assert.equal(request.model, "gpt-4o-mini-tts");
  assert.equal(request.voice, "coral");
  assert.equal(request.response_format, "mp3");
  assert.equal(result.buffer.toString(), "voice");
  assert.equal(result.requestId, "voice-1");
});

test("OpenAI voice provider verifies generated creator dialogue", async () => {
  let request;
  const provider = new OpenAIVoiceProvider({
    apiKey: "key",
    model: "gpt-4o-mini-tts",
    voice: "coral",
    transcribeModel: "gpt-4o-mini-transcribe",
    client: {
      audio: {
        transcriptions: {
          create: async (input) => {
            request = input;
            return { text: "Know the workout before the first rep.", _request_id: "transcribe-1" };
          },
        },
      },
    },
  });
  const result = await provider.transcribe({ buffer: Buffer.from("audio") });
  assert.equal(request.model, "gpt-4o-mini-transcribe");
  assert.equal(request.response_format, "json");
  assert.equal(result.text, "Know the workout before the first rep.");
  assert.equal(result.requestId, "transcribe-1");
});

function falProvider(client, fetchFn = async () => new Response(Buffer.from("image"), {
  status: 200,
  headers: { "content-type": "image/png" },
})) {
  return new FalMediaProvider({
    apiKey: "key",
    imageModel: "fal-ai/flux/schnell",
    imageWidth: 1024,
    imageHeight: 1280,
    videoModel: "google/gemini-omni-flash/v1.1/text-to-video",
    referenceVideoModel: "google/gemini-omni-flash/v1.1/reference-to-video",
    videoResolution: "720p",
    client,
    fetchFn,
  });
}

test("fal image generation requests one safe 4:5 background", async () => {
  let request;
  const client = {
    config: () => {},
    subscribe: async (model, options) => {
      request = { model, options };
      return {
        requestId: "image-1",
        data: { images: [{ url: "https://cdn.example/image.png", content_type: "image/png" }], seed: 42 },
      };
    },
    queue: {},
  };
  const result = await falProvider(client).generateBackground("An athlete training safely");
  assert.equal(request.model, "fal-ai/flux/schnell");
  assert.deepEqual(request.options.input.image_size, { width: 1024, height: 1280 });
  assert.equal(request.options.input.num_images, 1);
  assert.equal(request.options.input.enable_safety_checker, true);
  assert.match(request.options.input.prompt, /No readable text/);
  assert.match(request.options.input.prompt, /No phones, screens, calendars/);
  assert.equal(result.raw.requestId, "image-1");
  assert.equal(result.mimeType, "image/png");
});

test("fal video request is constrained to one vertical Gemini Omni Flash 1.1 task", async () => {
  let request;
  const client = {
    config: () => {},
    subscribe: async () => ({}),
    queue: {
      submit: async (model, options) => {
        request = { model, options };
        return { request_id: "task-1" };
      },
    },
  };
  const result = await falProvider(client).createTask({ prompt: "Safe gym scene", durationSeconds: 30, generateAudio: true });
  assert.equal(result.id, "task-1");
  assert.equal(request.model, "google/gemini-omni-flash/v1.1/text-to-video");
  assert.equal(request.options.input.aspect_ratio, "9:16");
  assert.equal(request.options.input.duration, 10);
  assert.equal(request.options.input.resolution, "720p");
  assert.equal("generate_audio" in request.options.input, false);
});

test("fal video request uses the reference endpoint when a locked character image is supplied", async () => {
  let request;
  const client = {
    config: () => {},
    subscribe: async () => ({}),
    queue: {
      submit: async (model, options) => {
        request = { model, options };
        return { request_id: "reference-task-1" };
      },
    },
  };
  const result = await falProvider(client).createTask({
    prompt: "<IMAGE_REF_0> is the locked production start frame",
    durationSeconds: 8,
    generateAudio: false,
    referenceImageUrls: ["https://cdn.example/reference.png"],
  });
  assert.equal(request.model, "google/gemini-omni-flash/v1.1/reference-to-video");
  assert.deepEqual(request.options.input.image_urls, ["https://cdn.example/reference.png"]);
  assert.equal(request.options.input.duration, 8);
  assert.equal(result.model, request.model);
});

test("fal completed video task exposes the generated video URL", async () => {
  const client = {
    config: () => {},
    subscribe: async () => ({}),
    queue: {
      status: async () => ({ status: "COMPLETED" }),
      result: async () => ({ data: { video: { url: "https://cdn.example/video.mp4" } } }),
    },
  };
  const result = await falProvider(client).getTask("task-1");
  assert.equal(result.status, "succeeded");
  assert.equal(result.output.video_url, "https://cdn.example/video.mp4");
});

function bufferPublisher(onPayload) {
  return new BufferPublisher({
    apiKey: "key",
    baseUrl: "https://api.buffer.example",
    shareMode: "addToQueue",
    youtubePrivacy: "private",
    fetchFn: async (_url, options) => {
      const body = JSON.parse(options.body);
      onPayload?.(body);
      return new Response(JSON.stringify({
        data: {
          createPost: {
            __typename: "PostActionSuccess",
            post: { id: "post-1", status: "scheduled", dueAt: null, externalLink: null, sentAt: null, error: null },
          },
        },
      }), { status: 200 });
    },
  });
}

test("Buffer marks TikTok video as AI-generated", async () => {
  let request;
  const publisher = bufferPublisher((payload) => { request = payload; });
  await publisher.publish({
    platform: "tiktok",
    accountId: "channel-1",
    text: "GymFeed test",
    mediaUrls: ["https://cdn.example/video.mp4"],
    isVideo: true,
  });
  assert.equal(request.variables.input.metadata.tiktok.isAiGenerated, true);
  assert.equal(request.variables.input.schedulingType, "automatic");
  assert.equal(request.variables.input.mode, "addToQueue");
  assert.equal(request.variables.input.assets[0].video.url, "https://cdn.example/video.mp4");
});

test("Buffer publishes generated Instagram video as an AI-labeled reel", async () => {
  let request;
  const publisher = bufferPublisher((payload) => { request = payload; });
  await publisher.publish({
    platform: "instagram",
    accountId: "channel-1",
    text: "GymFeed test",
    mediaUrls: ["https://cdn.example/video.mp4"],
    isVideo: true,
  });
  assert.equal(request.variables.input.metadata.instagram.type, "reel");
  assert.equal(request.variables.input.metadata.instagram.isAiGenerated, true);
  assert.equal(request.variables.input.metadata.instagram.shouldShareToFeed, true);
});

test("Buffer sends an Instagram multi-image carousel as a feed post", async () => {
  let request;
  const publisher = bufferPublisher((payload) => { request = payload; });
  await publisher.publish({
    platform: "instagram",
    accountId: "channel-1",
    text: "GymFeed carousel",
    mediaUrls: ["https://cdn.example/one.png", "https://cdn.example/two.png"],
    isVideo: false,
  });
  assert.equal(request.variables.input.metadata.instagram.type, "post");
  assert.equal(request.variables.input.assets.length, 2);
  assert.equal(request.variables.input.assets[0].image.url, "https://cdn.example/one.png");
});

test("Buffer keeps YouTube test uploads private and disables subscriber notifications", async () => {
  let request;
  const publisher = bufferPublisher((payload) => { request = payload; });
  await publisher.publish({
    platform: "youtube",
    accountId: "channel-1",
    text: "GymFeed test",
    title: "A safe workout",
    mediaUrls: ["https://cdn.example/video.mp4"],
    isVideo: true,
  });
  assert.equal(request.variables.input.metadata.youtube.privacy, "private");
  assert.equal(request.variables.input.metadata.youtube.notifySubscribers, false);
  assert.equal(request.variables.input.metadata.youtube.isAiGenerated, true);
});

test("Buffer performance summary exposes first-party views, shares, watch time, and creative thumbnails", async () => {
  const publisher = new BufferPublisher({
    apiKey: "key",
    baseUrl: "https://api.buffer.example",
    shareMode: "addToQueue",
    youtubePrivacy: "private",
    fetchFn: async (_url, options) => {
      const body = JSON.parse(options.body);
      let data;
      if (body.query.includes("GetOrganizations")) {
        data = { account: { organizations: [{ id: "org-1", name: "GymFeed" }] } };
      } else if (body.query.includes("GetChannels")) {
        data = { channels: [{ id: "tt-1", service: "tiktok", displayName: "gymfeedapp" }] };
      } else {
        data = {
          posts: {
            edges: [{
              node: {
                id: "post-top",
                channelService: "tiktok",
                status: "sent",
                sentAt: "2026-08-01T10:00:00Z",
                createdAt: "2026-07-31T10:00:00Z",
                text: "A relatable gym moment",
                externalLink: "https://tiktok.example/post-top",
                metrics: [
                  { type: "views", name: "Views", value: 1000, unit: "count" },
                  { type: "shares", name: "Shares", value: 50, unit: "count" },
                  { type: "averageTimeWatched", name: "Average watch", value: 8, unit: "count" },
                ],
                metricsUpdatedAt: "2026-09-01T10:00:00Z",
                assets: [{
                  type: "video",
                  source: "https://cdn.example/video.mp4",
                  thumbnail: "https://cdn.example/thumb.jpg",
                  video: { durationMs: 10000, width: 1080, height: 1920 },
                }],
              },
            }],
            pageInfo: { hasNextPage: false, endCursor: null },
          },
        };
      }
      return new Response(JSON.stringify({ data }), { status: 200 });
    },
  });

  const summary = await publisher.performanceSummary();
  const top = summary.platforms.tiktok.top_posts[0];
  assert.equal(summary.posts_analyzed, 1);
  assert.equal(top.metrics.views, 1000);
  assert.equal(top.metrics.shares, 50);
  assert.equal(top.duration_seconds, 10);
  assert.equal(top.watch_ratio, 0.8);
  assert.equal(top.thumbnail_url, "https://cdn.example/thumb.jpg");
});

test("Buffer can remove a rejected scheduled post", async () => {
  let variables;
  const publisher = new BufferPublisher({
    apiKey: "key",
    baseUrl: "https://api.buffer.example",
    shareMode: "addToQueue",
    youtubePrivacy: "private",
    fetchFn: async (_url, options) => {
      const body = JSON.parse(options.body);
      variables = body.variables;
      return new Response(JSON.stringify({
        data: { deletePost: { __typename: "DeletePostSuccess", id: "post-rejected" } },
      }), { status: 200 });
    },
  });

  assert.deepEqual(await publisher.deletePost("post-rejected"), { id: "post-rejected", deleted: true });
  assert.deepEqual(variables, { input: { id: "post-rejected" } });
});
