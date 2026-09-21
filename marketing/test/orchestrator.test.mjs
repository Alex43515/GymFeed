import test from "node:test";
import assert from "node:assert/strict";
import { MarketingOrchestrator, referenceImagePrompt, videoScenePrompt } from "../src/orchestrator.mjs";

test("Gemini creator prompt is a timed cinematic production brief", () => {
  const content = {
    decision: {
      content: {
        concept: "The moment a prepared trainee realizes today's workout is still unclear.",
        hook: "Ready to train, but what are you actually doing today?",
        creative_treatment: {
          visual_mode: "hybrid",
          people_role: "supporting",
          hook_pattern: "recognizable first-second conflict",
        },
        character_reference: {
          description: "fictional woman in her late twenties with dark hair tied back",
          wardrobe: "plain charcoal training top",
          environment_anchor: "quiet unbranded gym corridor",
          continuity_rules: ["same face, wardrobe, room and light"],
        },
      },
    },
  };
  const scene = {
    scene_id: "creator_hook",
    asset_type: "generated_video",
    purpose: "problem",
    source_duration_seconds: 10,
    duration_seconds: 6,
    camera: "eye-level medium close-up with safe caption space",
    subject: "one fictional adult trainee",
    action: "recognizes the missing plan, speaks to camera, then resolves to act",
    environment: "the same quiet unbranded gym corridor",
    lighting: "soft key from camera left with practical ambience",
    visual_style: "warm-neutral creator documentary finish",
    continuity_notes: "one person and one locked background",
    spoken_dialogue: "I came ready to train, but forgot what comes next.",
    ambient_audio: "quiet gym room tone",
  };

  const prompt = videoScenePrompt(content, scene);
  assert.match(prompt, /retains 0\.0–6\.0s/);
  assert.match(prompt, /VISIBLE ACTION/);
  assert.doesNotMatch(prompt, /hands stay empty|no searching|walking into frame/);
  assert.match(prompt, /24 fps/);
  assert.match(prompt, /eye-level medium close-up with safe caption space/);
  assert.match(prompt, /EXACT dialogue/);
  assert.match(prompt, /Do not generate GymFeed UI or branding/);

  const referencePrompt = referenceImagePrompt(content);
  assert.match(referencePrompt, /CAST, SET AND PROP CONTINUITY REFERENCE/);
  assert.match(referencePrompt, /Props required by the action must exist from the start/);
  assert.doesNotMatch(referencePrompt, /Both hands empty/);
});

test("pipeline does nothing while generation is disabled", async () => {
  const orchestrator = new MarketingOrchestrator({ config: { GENERATE_ASSETS: false } });
  assert.deepEqual(await orchestrator.runPipeline(), {
    skipped: true,
    reason: "asset generation disabled",
    actions: [],
  });
});

test("daily run is idempotent when a run already exists", async () => {
  const existing = { id: "run-1", status: "succeeded" };
  const repository = {
    startRun: async () => ({ run: existing, reused: true }),
  };
  const orchestrator = new MarketingOrchestrator({ config: {}, repository });
  assert.deepEqual(await orchestrator.runDaily(new Date("2026-08-12T10:00:00Z")), { reused: true, run: existing });
});

test("three-day test batch creates three dated campaigns and six exact content IDs", async () => {
  const orchestrator = new MarketingOrchestrator({ config: {} });
  const dates = [];
  orchestrator.runDaily = async (date, { revision }) => {
    const key = date.toISOString().slice(0, 10);
    dates.push([key, revision]);
    return {
      reused: false,
      run: { id: `run-${key}` },
      content: [{ id: `${key}-video` }, { id: `${key}-carousel` }],
    };
  };

  const result = await orchestrator.runDailyBatch(new Date("2026-09-18T08:00:00Z"), { days: 3, revision: 2 });

  assert.deepEqual(dates, [
    ["2026-09-18", 2],
    ["2026-09-19", 2],
    ["2026-09-20", 2],
  ]);
  assert.equal(result.campaigns.length, 3);
  assert.equal(result.content_ids.length, 6);
});

test("decision context includes GA4 traffic without replacing first-party outcomes", async () => {
  const orchestrator = new MarketingOrchestrator({
    config: {},
    repository: { loadContext: async () => ({ events_7d: [{ event_name: "signup" }] }) },
    analyticsReporter: { summary: async () => ({ status: "ok", last_7_days: { sessions: 12 } }) },
  });

  assert.deepEqual(await orchestrator.decisionContext(), {
    events_7d: [{ event_name: "signup" }],
    ga4: { status: "ok", last_7_days: { sessions: 12 } },
    buffer: { status: "not_configured" },
    app_captures: [],
  });
});

test("decision context includes first-party Buffer post performance", async () => {
  const orchestrator = new MarketingOrchestrator({
    config: {},
    repository: { loadContext: async () => ({ events_7d: [] }) },
    publisher: { performanceSummary: async () => ({ status: "ok", posts_analyzed: 42 }) },
  });

  assert.deepEqual(await orchestrator.decisionContext(), {
    events_7d: [],
    ga4: { status: "not_configured" },
    buffer: { status: "ok", posts_analyzed: 42 },
    app_captures: [],
  });
});

test("video generation creates one locked reference and queues every human scene", async () => {
  const updates = [];
  const content = {
    id: "content-1",
    run_id: "run-1",
    content_key: "GF-20260829-V001",
    content_type: "video",
    status: "planned",
    decision: {
      content: {
        concept: "Show how a planned workout becomes an active GymFeed session.",
        hook: "Your plan should move with you.",
        product_feature: "train",
        feature_sequence: ["train"],
        screenshot_refs: ["curated/gymfeed-train-routine.png"],
        product_promise: "Plan and complete a workout in one connected flow.",
        proof_points: ["Configure sets, reps and kilograms."],
        caption_text: [],
        cta: "Start today's workout",
        audio_mode: "silent",
        character_reference: {
          required: true,
          description: "a fictional adult trainee with short dark hair",
          wardrobe: "plain black shirt and dark shorts",
          environment_anchor: "an unbranded neighborhood gym",
          continuity_rules: ["same face, hair, clothing and lighting"],
        },
        scenes: [{
          scene_id: "hook",
          asset_type: "generated_video",
          purpose: "hook",
          duration_seconds: 8,
          camera: "handheld medium shot",
          subject: "a fictional adult trainee",
          action: "preparing for a controlled gym session",
          environment: "an unbranded neighborhood gym",
          lighting: "natural practical lighting",
          visual_style: "candid platform-native footage",
          continuity_notes: "same adult and wardrobe",
          overlay_text: "Your plan should move with you.",
          screenshot_ref: "",
          spoken_dialogue: "",
          ambient_audio: "natural gym ambience",
        }, {
          scene_id: "action",
          asset_type: "gymfeed_screen",
          purpose: "action",
          duration_seconds: 4,
          camera: "handheld close-up",
          subject: "the same fictional adult trainee",
          action: "starts the planned exercise with controlled form",
          environment: "the same unbranded neighborhood gym",
          lighting: "the same natural practical lighting",
          visual_style: "candid platform-native footage",
          continuity_notes: "same adult and wardrobe",
          overlay_text: "Start today's workout.",
          screenshot_ref: "curated/gymfeed-train-routine.png",
          spoken_dialogue: "",
          ambient_audio: "natural gym ambience",
        }, {
          scene_id: "proof",
          asset_type: "gymfeed_screen",
          purpose: "product_proof",
          duration_seconds: 4,
          camera: "static product frame",
          subject: "verified GymFeed Train screen",
          action: "show the dated routine",
          environment: "GymFeed product frame",
          lighting: "interface lighting",
          visual_style: "GymFeed product design",
          continuity_notes: "use verified screen",
          overlay_text: "Plan. Train. Progress.",
          screenshot_ref: "curated/gymfeed-train-routine.png",
          spoken_dialogue: "",
          ambient_audio: "",
        }],
      },
    },
  };
  const repository = {
    contentById: async () => content,
    reserveCost: async (_provider, _cost, context) => `reservation-${context.metadata.operation}-${context.metadata.scene_id ?? "reference"}`,
    releaseCost: async () => {},
    settleCost: async () => {},
    uploadAsset: async (path) => `https://cdn.example/${path}`,
    updateContent: async (_id, patch) => {
      updates.push(patch);
      return { ...content, ...patch };
    },
  };
  const taskInputs = [];
  const mediaProvider = {
    generateReferenceImage: async () => ({ buffer: Buffer.from("reference"), mimeType: "image/png", raw: { requestId: "reference-1" } }),
    createTask: async (input) => {
      taskInputs.push(input);
      return { id: `fal-task-${taskInputs.length}`, model: "reference-model", status: "queued" };
    },
  };
  const orchestrator = new MarketingOrchestrator({
    config: { GENERATE_ASSETS: true, FAL_VIDEO_USD_PER_SECOND: 0.2, FAL_ESTIMATED_IMAGE_COST_USD: 0.08 },
    repository,
    mediaProvider,
  });

  const result = await orchestrator.generateContent(content.id);
  assert.equal(result.pending, true);
  assert.equal(taskInputs.length, 1);
  assert.equal(taskInputs[0].durationSeconds, 8);
  assert.equal(taskInputs[0].generateAudio, false);
  assert.equal(taskInputs[0].referenceImageUrls.length, 1);
  assert.match(taskInputs[0].prompt, /<IMAGE_REF_0>/);
  assert.equal(updates.at(-1).provider_task_id, "fal-task-1");
  assert.equal(updates.at(-1).decision.generation.scenes[1].status, "ready");
});

test("a failed Gemini scene resumes only the rejected shot with QA corrections", async () => {
  const updates = [];
  const taskInputs = [];
  const content = {
    id: "content-retry",
    run_id: "run-retry",
    content_key: "GF-20260919-V003",
    content_type: "video",
    status: "failed",
    decision: {
      content: {
        concept: "A trainee checks the planned workout beside the dumbbell rack.",
        hook: "You packed the gym bag, not the workout.",
        audio_mode: "silent",
        creative_treatment: { visual_mode: "hybrid", hook_pattern: "relatable forgotten plan" },
        character_reference: { description: "one fictional adult", wardrobe: "charcoal shirt", environment_anchor: "unbranded gym" },
        scenes: [{
          scene_id: "rack_pause",
          asset_type: "generated_video",
          duration_seconds: 8,
          purpose: "hook",
          camera: "candid handheld vertical shot",
          subject: "one fictional adult",
          action: "checks a hidden phone then lifts one dumbbell",
          environment: "the same gym",
          lighting: "natural practical light",
          visual_style: "creator-native",
          continuity_notes: "one phone and one dumbbell",
          overlay_text: "",
          screenshot_ref: "",
          spoken_dialogue: "",
          ambient_audio: "",
        }],
      },
      generation: {
        generation_id: "generation-retry",
        reference_image_url: "https://cdn.example/reference.png",
        scenes: [{
          scene_id: "rack_pause",
          asset_type: "generated_video",
          status: "qa_failed",
          attempt: 1,
          asset_url: "https://cdn.example/attempt-1.mp4",
          contact_sheet_url: "https://cdn.example/attempt-1.jpg",
          qa_score: 75,
          qa: {
            retry_prompt: "Keep exactly one dumbbell and hide the phone display.",
            required_fixes: ["Keep exactly one dumbbell."],
          },
          history: [],
        }],
      },
    },
  };
  const orchestrator = new MarketingOrchestrator({
    config: { GENERATE_ASSETS: true, FAL_VIDEO_USD_PER_SECOND: 0.1, FAL_SCENE_MAX_ATTEMPTS: 2 },
    repository: {
      contentById: async () => content,
      reserveCost: async () => "reservation-retry",
      releaseCost: async () => {},
      updateContent: async (_id, patch) => {
        updates.push(patch);
        return { ...content, ...patch };
      },
    },
    mediaProvider: {
      createTask: async (input) => {
        taskInputs.push(input);
        return { id: "fal-retry-2", model: "google/gemini-omni-flash/v1.1/reference-to-video" };
      },
    },
  });

  const result = await orchestrator.generateContent(content.id);
  assert.equal(result.resumed, true);
  assert.equal(result.pending, true);
  assert.equal(taskInputs.length, 1);
  assert.match(taskInputs[0].prompt, /Keep exactly one dumbbell and hide the phone display/);
  assert.deepEqual(taskInputs[0].referenceImageUrls, ["https://cdn.example/reference.png"]);
  assert.equal(updates.at(-1).provider_task_id, "fal-retry-2");
  assert.equal(updates.at(-1).decision.generation.scenes[0].attempt, 2);
  assert.equal(updates.at(-1).decision.generation.scenes[0].history.length, 1);
});

test("a human-led decision is not overridden by four available screenshots", async () => {
  const content = {
    id: "content-human",
    run_id: "run-human",
    content_key: "GF-20260907-V001",
    content_type: "video",
    status: "planned",
    decision: {
      content: {
        concept: "A trainee freezes at an unfamiliar cable machine, then turns confusion into action with GymFeed.",
        hook: "Nobody wants to admit they do not know this machine.",
        product_feature: "scan_equipment",
        feature_sequence: ["scan_equipment", "scan_equipment", "train", "connected_ecosystem"],
        screenshot_refs: ["one.png", "two.png", "three.png", "four.png"],
        product_promise: "Photograph equipment for AI-assisted identification and safe-use guidance.",
        proof_points: ["Photograph the machine.", "Review the likely result.", "Follow safe-use guidance.", "Continue in GymFeed."],
        caption_text: ["What is this machine?", "Scan it.", "Learn the likely setup."],
        creative_treatment: {
          visual_mode: "human_led",
          opening_asset: "fal_video",
          people_role: "primary",
          hook_pattern: "relatable gym confusion",
          pacing_pattern: "fast reaction then reveal",
        },
        character_reference: {
          required: true,
          description: "fictional adult trainee with a believable natural appearance",
          wardrobe: "plain dark training clothes",
          environment_anchor: "unbranded gym",
          continuity_rules: ["same face, hair and clothing"],
        },
        scenes: [{
          scene_id: "confusion",
          asset_type: "generated_video",
          purpose: "hook",
          duration_seconds: 8,
          camera: "handheld close-up to medium reveal",
          subject: "a fictional adult trainee",
          action: "hesitates at an unfamiliar machine, then confidently prepares to scan it",
          environment: "an unbranded gym",
          lighting: "natural practical lighting",
          visual_style: "candid creator-native footage",
          continuity_notes: "same adult and clothing",
          overlay_text: "What is this machine?",
          screenshot_ref: "",
          spoken_dialogue: "",
          ambient_audio: "natural gym ambience",
        }, {
          scene_id: "scan-action",
          asset_type: "gymfeed_screen",
          purpose: "action",
          duration_seconds: 5,
          camera: "over-shoulder medium shot",
          subject: "the same fictional adult trainee",
          action: "positions safely near the machine and prepares to scan",
          environment: "the same unbranded gym",
          lighting: "natural practical lighting",
          visual_style: "candid creator-native footage",
          continuity_notes: "same adult and clothing",
          overlay_text: "Scan it with GymFeed.",
          screenshot_ref: "one.png",
          spoken_dialogue: "",
          ambient_audio: "natural gym ambience",
        }],
      },
    },
  };
  const taskInputs = [];
  const orchestrator = new MarketingOrchestrator({
    config: { GENERATE_ASSETS: true, FAL_VIDEO_USD_PER_SECOND: 0.2, FAL_ESTIMATED_IMAGE_COST_USD: 0.08 },
    repository: {
      contentById: async () => content,
      reserveCost: async () => "reservation-human",
      releaseCost: async () => {},
      settleCost: async () => {},
      uploadAsset: async (path) => `https://cdn.example/${path}`,
      updateContent: async (_id, patch) => ({ ...content, ...patch }),
    },
    mediaProvider: {
      generateReferenceImage: async () => ({ buffer: Buffer.from("reference"), mimeType: "image/png", raw: { requestId: "reference-human" } }),
      createTask: async (input) => {
        taskInputs.push(input);
        return { id: `fal-human-${taskInputs.length}`, model: "reference-model", status: "queued" };
      },
    },
  });

  const result = await orchestrator.generateContent(content.id);
  assert.equal(result.pending, true);
  assert.equal(taskInputs.length, 1);
  assert.match(taskInputs[0].prompt, /human_led/);
  assert.match(taskInputs[0].prompt, /relatable gym confusion/);
});

test("one-day campaign schedules the carousel and video on the same date", () => {
  const orchestrator = new MarketingOrchestrator({
    config: { BUFFER_SCHEDULE_AT: "2026-09-06T08:00:00.000Z" },
  });

  assert.equal(
    orchestrator.scheduledTime({ content_type: "carousel" }, "instagram"),
    "2026-09-06T08:00:00.000Z",
  );
  assert.equal(
    orchestrator.scheduledTime({ content_type: "video" }, "instagram"),
    "2026-09-06T16:00:00.000Z",
  );
  assert.equal(
    orchestrator.scheduledTime({ content_type: "video" }, "tiktok"),
    "2026-09-06T16:15:00.000Z",
  );
  assert.equal(
    orchestrator.scheduledTime({ content_type: "video" }, "youtube"),
    "2026-09-06T16:30:00.000Z",
  );
});

test("main orchestrator processes only the requested content through generation and QA", async () => {
  let content = {
    id: "campaign-content-1",
    status: "planned",
    provider_task_id: null,
  };
  const calls = [];
  const orchestrator = new MarketingOrchestrator({
    config: {},
    repository: {
      contentById: async (id) => {
        assert.equal(id, "campaign-content-1");
        return content;
      },
    },
  });
  orchestrator.generateContent = async (id) => {
    calls.push(["generate", id]);
    content = { ...content, status: "generating", provider_task_id: "fal-task-1" };
    return { skipped: false, pending: true, content };
  };
  orchestrator.refreshContent = async (id) => {
    calls.push(["refresh", id]);
    content = { ...content, status: "generated" };
    return { skipped: false, pending: false, content };
  };
  orchestrator.reviewContent = async (id) => {
    calls.push(["qa", id]);
    content = { ...content, status: "awaiting_approval" };
    return { skipped: false, passed: true, content };
  };

  const result = await orchestrator.processContentToReview("campaign-content-1", { pollIntervalMs: 0 });

  assert.deepEqual(calls, [
    ["generate", "campaign-content-1"],
    ["refresh", "campaign-content-1"],
    ["qa", "campaign-content-1"],
  ]);
  assert.equal(result.pending, false);
  assert.equal(result.passed, true);
  assert.equal(result.content.status, "awaiting_approval");
});

test("main orchestrator does not regenerate content already waiting for approval", async () => {
  const content = { id: "campaign-content-2", status: "awaiting_approval" };
  const orchestrator = new MarketingOrchestrator({
    config: {},
    repository: { contentById: async () => content },
  });

  const result = await orchestrator.processContentToReview(content.id, { pollIntervalMs: 0 });

  assert.equal(result.skipped, true);
  assert.equal(result.pending, false);
  assert.match(result.reason, /already reached awaiting_approval/);
});

test("sheet approval records the decision but does not call Buffer while auto publish is disabled", async () => {
  const content = {
    id: "content-review-1",
    status: "awaiting_approval",
    decision: { review_revision: 1 },
  };
  const updates = [];
  const orchestrator = new MarketingOrchestrator({
    config: { AUTO_PUBLISH: false },
    repository: {
      contentById: async () => content,
      createContentReview: async () => ({ review: { id: "review-1" }, reused: false }),
      updateContent: async (_id, patch) => {
        updates.push(patch);
        return { ...content, ...patch };
      },
      finishContentReview: async (_id, status, payload) => ({ id: "review-1", status, ...payload }),
    },
    publisher: { publish: async () => { throw new Error("Buffer must not be called"); } },
  });

  const result = await orchestrator.applySheetDecision({
    rowNumber: 2,
    contentId: content.id,
    revision: 1,
    decision: "Approve",
    instructions: "",
  });

  assert.equal(result.result.action, "approved_buffer_disabled");
  assert.equal(updates.at(-1).status, "approved");
});

test("sheet rejection requires actionable revision instructions", async () => {
  const orchestrator = new MarketingOrchestrator({
    config: {},
    repository: {
      contentById: async () => ({ id: "content-review-2", status: "awaiting_approval", decision: { review_revision: 1 } }),
    },
  });

  await assert.rejects(
    orchestrator.applySheetDecision({
      rowNumber: 3,
      contentId: "content-review-2",
      revision: 1,
      decision: "Reject",
      instructions: "",
    }),
    /Add revision instructions/,
  );
});

test("sheet dispatcher claims a decision once and passes exact revision context to n8n", async () => {
  const processing = [];
  const entry = {
    rowNumber: 7,
    contentId: "content-dispatch-1",
    revision: 2,
    decision: "Reject",
    instructions: "Keep the same hook but replace the unrealistic human scenes.",
  };
  const orchestrator = new MarketingOrchestrator({
    config: {},
    repository: {
      approvalSheetContent: async () => [],
      contentById: async () => ({ id: entry.contentId, decision: { review_revision: 2 } }),
      createContentReview: async () => ({ review: { id: "review-dispatch-1" }, reused: false }),
    },
    approvalSheet: {
      configured: true,
      syncContent: async () => ({ updated: 0, appended: 0 }),
      pendingDecisions: async () => [entry],
      setProcessingResult: async (...args) => processing.push(args),
    },
  });

  const result = await orchestrator.claimApprovalSheetDecisions();

  assert.deepEqual(result.decisions, [{ ...entry, reviewId: "review-dispatch-1", mode: "sheet_decision" }]);
  assert.match(processing[0][1], /Queued for the main CMO orchestrator/);
});

test("claimed rejection revises only its content and waits for the main generation loop", async () => {
  const original = {
    id: "content-revision-1",
    run_id: "run-1",
    content_type: "video",
    status: "awaiting_approval",
    decision: { review_revision: 1, content: { topic: "old" } },
  };
  const revisedContent = {
    ...original,
    status: "planned",
    decision: { review_revision: 2, content: { topic: "revised" } },
  };
  let resetCalls = 0;
  const orchestrator = new MarketingOrchestrator({
    config: { OPENAI_ESTIMATED_DAILY_COST_USD: 0.5 },
    repository: {
      contentReviewById: async () => ({ id: "review-revision-1", content_id: original.id, revision: 1, decision: "reject", instructions: "Replace every defective scene", status: "pending" }),
      contentById: async () => original,
      reserveCost: async () => "reservation-revision",
      settleCost: async () => {},
      releaseCost: async () => {},
      resetContentForRevision: async () => {
        resetCalls += 1;
        return revisedContent;
      },
    },
    brain: {
      reviseContent: async () => ({ data: revisedContent.decision.content, costUsd: 0.02, responseId: "response-revision" }),
    },
  });
  orchestrator.generateContent = async () => { throw new Error("Generation must be owned by the visible n8n loop"); };

  const result = await orchestrator.prepareClaimedReview({ reviewId: "review-revision-1", rowNumber: 7 });

  assert.equal(result.requiresGeneration, true);
  assert.equal(result.contentId, original.id);
  assert.equal(result.reviewId, "review-revision-1");
  assert.equal(resetCalls, 1);
});
