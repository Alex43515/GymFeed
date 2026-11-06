import test from "node:test";
import assert from "node:assert/strict";
import { MarketingOrchestrator, videoScenePrompt } from "../src/orchestrator.mjs";
import { loadConfig } from "../src/config.mjs";

test("production defaults to human review", () => {
  assert.equal(loadConfig({ MARKETING_INTERNAL_TOKEN: "i".repeat(32), MARKETING_APPROVAL_TOKEN: "a".repeat(32), SUPABASE_URL: "https://example.supabase.co", SUPABASE_SERVICE_ROLE_KEY: "s".repeat(32) }).MARKETING_REVIEW_MODE, "human");
});

test("a full revision screenplay never leaks into an individual scene request", () => {
  const content = { decision: { review_instructions: "OTHER SCENES: gym, cafe, kitchen and every line of the whole film", content: {
    concept: "A gym visit", hook: "A question", scenes: [],
  } } };
  const prompt = videoScenePrompt(content, { scene_id: "home", purpose: "hook", duration_seconds: 3, action: "Zip the bag", environment: "home" }, "Keep the zip visible");
  assert.match(prompt, /Zip the bag/);
  assert.match(prompt, /Keep the zip visible/);
  assert.doesNotMatch(prompt, /OTHER SCENES|every line of the whole film/);
});

test("all content types reach human review without AI QA or paid reservations", async () => {
  for (const content_type of ["video", "carousel", "image"]) {
    let row = { id: "item", content_type, status: "generated", asset_urls: ["https://example.com/asset"], decision: {}, qa_score: 20 };
    const service = new MarketingOrchestrator({ config: { MARKETING_REVIEW_MODE: "human" }, repository: {
      contentById: async () => row,
      updateContent: async (_id,patch) => (row={...row,...patch}),
      reserveCost: async () => { throw Error("Human review must not reserve AI QA spend"); },
    }, brain: { qualityReview: async () => { throw Error("AI QA must not run"); } } });
    const result = await service.reviewContent("item");
    assert.equal(result.humanReviewRequired, true);
    assert.equal(row.status, "awaiting_approval");
    assert.equal(row.qa_score, null);
    assert.equal(row.qa.publish, false, "human review is not publication approval");
  }
});

test("saved generated scenes go directly to assembly without scene QA or regeneration", async () => {
  const row = { id: "item", content_type: "video", status: "generating", decision: { content: { scenes: [] }, generation: { scenes: [
    { scene_id: "shot", asset_type: "generated_video", status: "generated", asset_url: "https://example.com/paid.mp4" },
  ] } } };
  let assembly = 0;
  const service = new MarketingOrchestrator({ config: { MARKETING_REVIEW_MODE: "human" }, repository: {
    contentById: async () => row, updateContent: async () => row,
    reserveCost: async () => { throw Error("No automatic QA or retakes"); },
  } });
  service.finishVideoGeneration = async (_content,scenes) => { assembly++; assert.equal(scenes[0].asset_url,"https://example.com/paid.mp4"); return { content: row }; };
  await service.refreshContent("item");
  assert.equal(assembly, 1);
});

test("human review does not automatically retry failed scenes", async () => {
  const service = new MarketingOrchestrator({ config: { MARKETING_REVIEW_MODE: "human" } });
  assert.equal(await service.resumeFailedVideoScene({}), null);
});

test("a provider failure cannot trigger a paid replacement in human review mode", async () => {
  let row={id:"failed-shot",content_type:"video",status:"generating",decision:{content:{scenes:[]},generation:{scenes:[{scene_id:"shot",asset_type:"generated_video",status:"queued",task_id:"existing-paid-task",attempt:1}]}}};
  const service=new MarketingOrchestrator({config:{MARKETING_REVIEW_MODE:"human",FAL_SCENE_MAX_ATTEMPTS:4},repository:{contentById:async()=>row,updateContent:async(_id,patch)=>(row={...row,...patch})},mediaProvider:{getTask:async()=>({status:"failed",message:"Provider 504",error:{infrastructureFailure:true}}),createTask:async()=>{throw Error("No paid replacement permitted");}}});
  const result=await service.refreshContent(row.id);
  assert.equal(result.content.status,"failed");
  assert.match(result.content.failure_reason,/Provider 504/);
});

test("the per-video estimate is checked before reference images or paid scene calls", async () => {
  const service=new MarketingOrchestrator({config:{MARKETING_REVIEW_MODE:"human",FAL_VIDEO_USD_PER_SECOND:0.2,FAL_ESTIMATED_IMAGE_COST_USD:0.08,FAL_MAX_VIDEO_ATTEMPT_USD:1},repository:{},mediaProvider:{prepareTask:()=>({durationSeconds:10})}});
  await assert.rejects(service.generateVideo({id:"over-budget",decision:{content:{scenes:[{scene_id:"shot",asset_type:"generated_video",source_duration_seconds:10,duration_seconds:8}]}}}),/estimated attempt cost.*exceeds/);
});

test("a human-approved V3 video queues each initial scene once without preproduction AI QA", async () => {
  let row={id:"approved-video",content_type:"video",status:"planned",decision:{content:{production_version:3,audio_mode:"mixed",scenes:[{scene_id:"one",asset_type:"generated_video",purpose:"hook",duration_seconds:2,source_duration_seconds:3,action:"Smile naturally"},{scene_id:"demo",asset_type:"app_capture",capture_ref:"verified-test"}]}}};
  let queued=0;
  const service=new MarketingOrchestrator({config:{MARKETING_REVIEW_MODE:"human",FAL_VIDEO_USD_PER_SECOND:0.2,FAL_ESTIMATED_IMAGE_COST_USD:0.08,FAL_MAX_VIDEO_ATTEMPT_USD:25},repository:{updateContent:async(_id,patch)=>(row={...row,...patch}),reserveCost:async(provider)=>{assert.equal(provider,"fal");return "reservation";}},brain:{storyQualityReview:async()=>{throw Error("AI story QA must not run");}},mediaProvider:{prepareTask:()=>({durationSeconds:3,model:"test-model"}),createTask:async()=>{queued++;return{id:"existing-new-approved-task",model:"test-model"};}}});
  service.appCaptureResolver=async()=>({});
  const result=await service.generateVideo(row);
  assert.equal(queued,1);
  assert.equal(result.content.decision.generation.scenes[0].task_id,"existing-new-approved-task");
});
