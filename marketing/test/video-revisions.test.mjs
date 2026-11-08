import test from "node:test";
import assert from "node:assert/strict";
import { applyVideoRevision, revisionGeneration, VideoAssetRevisionSchema } from "../src/video-revisions.mjs";
import { MarketingOrchestrator } from "../src/orchestrator.mjs";
import { CmoController } from "../src/cmo-controller.mjs";
import { timedSceneCaptions, captionAss } from "../src/caption-timing.mjs";
import { MarketingBrain } from "../src/brain.mjs";

const source = () => ({ id:"video", content_type:"video", content_key:"GF-test", status:"awaiting_approval", asset_urls:["https://assets/master.mp4"], decision:{
  review_revision:1, campaign:{id:"campaign",idea_revision:1},
  content:{production_version:3,target_duration_seconds:12,captions_enabled:true,cta:"Get started",character_reference:{required:true},
    cast:[{character_id:"creator",appearance:"Adult woman, curly hair",wardrobe:"Green jacket",voice_direction:"Warm"}],
    scenes:["intro","reply","close"].map((scene_id)=>({scene_id,asset_type:"generated_video",purpose:scene_id==="close"?"cta":"hook",duration_seconds:4,source_duration_seconds:6,source_start_seconds:.5,
      audio_strategy:"native",spoken_dialogue:`This is ${scene_id}.`,character_ids:["creator"],action:`Smile during ${scene_id}`,camera:"Medium shot"})),
  },
  generation:{generation_id:"old-production",character_reference_urls:{creator:"https://assets/creator.png"},narration:{},
    scenes:["intro","reply","close"].map((scene_id)=>({scene_id,asset_type:"generated_video",status:"generated",task_id:`paid-${scene_id}`,asset_url:`https://assets/${scene_id}.mp4`,technical:{duration_seconds:6,source_transcript:`This is ${scene_id}.`}})),
    platform_variants:{instagram:{url:"https://assets/master.mp4"}},
  },
} });
const patch = (extra={}) => ({summary:"Calmer edit",pacing:"calmer",captions_enabled:null,caption_font_size:48,cta:null,instagram_caption:null,scene_order:[],cast_updates:[],changes:[],...extra});
const change = (scene_id, extra={}) => ({scene_id,reason:"Owner requested this change",remove:false,replace_media:false,
  ...Object.fromEntries(["source_start_seconds","duration_seconds","audio_strategy","spoken_dialogue","voiceover_text","action","camera","subject","environment","lighting","visual_style","continuity_notes","overlay_text"].map((key)=>[key,null])),...extra});

test("editing revisions preserve all paid footage, casting and narration without a fresh production", () => {
  const original=source();
  const revised=applyVideoRevision(original,VideoAssetRevisionSchema.parse(patch({cta:"Try GymFeed",changes:[change("reply",{overlay_text:"Fixed spelling"})]})),"Editing only: slower cuts, fix captions and CTA. No new fal.");
  assert.deepEqual(revised.scope.replace_scene_ids,[]);
  const generation=revisionGeneration(original,revised.plan,revised.scope);
  assert.deepEqual(generation.scenes.map(s=>s.asset_url),original.decision.generation.scenes.map(s=>s.asset_url));
  assert.deepEqual(generation.character_reference_urls,original.decision.generation.character_reference_urls);
  assert.deepEqual(generation.platform_variants,{});
  assert.notEqual(generation.generation_id,"old-production");
  assert.equal(original.decision.content.cta,"Get started");
});

test("replacing the intro affects only that shot and preserves actor identity", () => {
  const original=source();
  const revised=applyVideoRevision(original,patch({changes:[change("intro",{replace_media:true,action:"Walk in and greet the viewer"})]}),"The intro action looks unnatural. Replace that shot.");
  assert.deepEqual(revised.scope.replace_scene_ids,["intro"]);
  const generation=revisionGeneration(original,revised.plan,revised.scope);
  assert.deepEqual(generation.scenes.map(s=>s.scene_id),["reply","close"]);
  assert.equal(generation.character_reference_urls.creator,"https://assets/creator.png");
});

test("muting or selecting speech already in the source reuses the existing picture", () => {
  const original=source();
  original.decision.generation.scenes[0].technical.source_transcript="This is intro. Meet GymFeed.";
  const revised=applyVideoRevision(original,patch({changes:[change("intro",{spoken_dialogue:"Meet GymFeed."}),change("reply",{audio_strategy:"silent",spoken_dialogue:""})]}),"Remove repeated speech and keep the existing footage");
  assert.deepEqual(revised.scope.replace_scene_ids,[]);
});

test("unrequested full remakes, fabricated real footage, changed casting and missing raw clips fail before fal", () => {
  assert.throws(()=>applyVideoRevision(source(),patch({changes:[change("intro",{replace_media:true})]}),"Editing only, no new fal"),/Editing-only/);
  const all=patch({changes:["intro","reply","close"].map(id=>change(id,{replace_media:true}))});
  assert.throws(()=>applyVideoRevision(source(),all,"Make the transitions calmer"),/regenerate every shot/);
  assert.equal(applyVideoRevision(source(),all,"Create a fresh production. Do not reuse failed generated clips.").scope.replace_scene_ids.length,3);
  assert.throws(()=>applyVideoRevision(source(),patch({cast_updates:[{character_id:"creator",appearance:"Different woman",wardrobe:null,voice_direction:null}]}),"Slow the transitions"),/Casting changes were not requested/);
  const app=source();app.decision.content.scenes[0].asset_type="app_capture";
  assert.throws(()=>applyVideoRevision(app,patch({changes:[change("intro",{replace_media:true})]}),"Replace intro"),/real app asset/);
  const missing=source();delete missing.decision.generation.scenes[0].asset_url;
  assert.throws(()=>revisionGeneration(missing,missing.decision.content,{replace_scene_ids:[],changed_cast_ids:[],settings:{}}),/silently regenerate/);
});

test("scene removal and ordering are explicit and preserve stable IDs", () => {
  const revised=applyVideoRevision(source(),patch({changes:[change("reply",{remove:true})],scene_order:["close","intro"]}),"Remove the reply beat and reorder these scenes");
  assert.deepEqual(revised.plan.scenes.map(s=>s.scene_id),["close","intro"]);
  assert.deepEqual(revised.scope.replace_scene_ids,[]);
  assert.throws(()=>applyVideoRevision(source(),patch({scene_order:["intro","intro","close"]}),"Reorder"),/each retained scene/);
});

function queuedService(row) {
  row.decision.content.scenes.push({scene_id:"demo",asset_type:"app_capture",capture_ref:"test",duration_seconds:2,audio_strategy:"silent"});
  const calls=[];
  const service=new MarketingOrchestrator({config:{MARKETING_REVIEW_MODE:"human",FAL_MAX_VIDEO_ATTEMPT_USD:25,FAL_VIDEO_USD_PER_SECOND:.2,FAL_ESTIMATED_IMAGE_COST_USD:.08},
    repository:{updateContent:async(_id,update)=>(row={...row,...structuredClone(update)}),reserveCost:async(provider,cost)=>{calls.push({provider,cost});return "reservation";}},
    mediaProvider:{prepareTask:(options)=>({durationSeconds:options.durationSeconds}),createTask:async(options)=>{calls.push({task:options});return{id:"single-new-task",model:"fake"};},generateReferenceImage:async()=>{throw Error("Unchanged references must be reused");}},
    appCaptureResolver:async()=>({}),
  });
  return {service,calls,getRow:()=>row};
}

test("production queues exactly one changed shot, caches its task, and charges for the speech allocation", async () => {
  const row=source();const revised=applyVideoRevision(row,patch({changes:[change("intro",{replace_media:true})]}),"Replace the intro");
  row.decision.content=revised.plan;row.decision.generation=revisionGeneration(row,revised.plan,revised.scope);
  const {service,calls,getRow}=queuedService(row);
  await service.generateVideo(row);
  assert.equal(calls.filter(c=>c.task).length,1);
  assert.ok(Math.abs(calls[0].cost-calls[1].task.durationSeconds*.2)<.00001);
  assert.equal(getRow().decision.generation.scenes[1].asset_url,"https://assets/reply.mp4");
  await service.generateVideo(getRow());
  assert.equal(calls.filter(c=>c.task).length,1,"retry reuses the checkpointed task instead of submitting again");
});

test("editing-only production queues no fal tasks and preserves the saved scope", async () => {
  const row=source();const revised=applyVideoRevision(row,patch(),"Samo montaža");
  row.decision.generation=revisionGeneration(row,revised.plan,revised.scope);
  const {service,calls,getRow}=queuedService(row);
  await service.generateVideo(row);
  assert.equal(calls.length,0);
  assert.equal(getRow().decision.generation.revision_scope.reused_scene_ids.length,3);
  assert.equal(getRow().provider_task_id,null);
});

test("Reject patches the existing plan across the database reset and returns the same item for review", async () => {
  let row=source(), ideaRevision=1, ideaStatus="approved";const calls=[];
  const ownerPatch=patch({changes:[change("intro",{replace_media:true,action:"Walk in naturally"})]});
  const campaigns={
    decideIdea:async(input)=>{ideaStatus=input.decision==="reject"?"rejected":"approved";},
    claimIdeaRevision:async()=>({claimed:true,token:"claim",instructions:"Replace the intro only"}),
    finishIdeaRevision:async({plan})=>{ideaRevision++;ideaStatus="pending";row={...row,status:"planned",asset_urls:[],decision:{...row.decision,content:plan,generation:{},review_revision:2,campaign:{id:"campaign",idea_revision:2}}};return {finished:true};},
    status:async()=>({ideas:[{content_id:row.id,revision:ideaRevision,idea_status:ideaStatus,content:row}]}),
    startItem:async(input)=>{calls.push(input);return{batch:{id:"batch"}};},failIdeaRevision:async()=>assert.fail("Revision should not fail"),
  };
  const controller=new CmoController({config:{OPENAI_ESTIMATED_DAILY_COST_USD:.05},campaigns,repository:{
    contentById:async()=>structuredClone(row),updateContent:async(_id,update)=>(row={...row,...structuredClone(update)}),
    createContentReview:async()=>({review:{id:"review",decision:"reject",status:"processing"},reused:false}),
    reserveCost:async()=>"reservation",settleCost:async()=>{},finishContentReview:async()=>{},
  },approvalSheet:{markContentDecision:async(_entry,message)=>calls.push(message)},orchestrator:{humanReviewOnly:true,brain:{reviseVideoAsset:async(snapshot,instructions)=>{
    const revised=applyVideoRevision(snapshot,ownerPatch,instructions);return{data:revised.plan,revisionScope:revised.scope,costUsd:.01,responseId:"mock"};
  }}}});
  controller.sync=async()=>({});
  controller.produce=async()=>{
    assert.equal(row.id,"video");assert.equal(row.decision.review_revision,2);
    assert.deepEqual(row.decision.generation.scenes.map(s=>s.asset_url),["https://assets/reply.mp4","https://assets/close.mp4"]);
    assert.deepEqual(row.decision.generation.revision_scope.replace_scene_ids,["intro"]);
    return {reviewRequired:true};
  };
  const result=await controller.assetDecision({contentId:"video",revision:1,decision:"Reject",instructions:"Replace the intro only",rowNumber:128});
  assert.equal(result.action,"asset_replaced_pending_review");
  assert.equal(result.revision,2);
  assert.ok(calls.some(message=>typeof message==="string"&&/reusing 2 saved shots; generating only 1/.test(message)));
});

test("timed captions follow actual audio, stay within each cut, and have no repeated full-scene headline", () => {
  const plan={scenes:[{scene_id:"intro",asset_type:"generated_video",audio_strategy:"native",source_start_seconds:2,duration_seconds:4},{scene_id:"demo",audio_strategy:"voiceover",duration_seconds:2}]};
  const timings=timedSceneCaptions(plan,[{scene_id:"intro",technical:{words:[{word:"Unwanted",start:0,end:1},{word:"Meet",start:2.3,end:2.6},{word:"Gym",start:2.8,end:3},{word:"Feed.",start:3,end:3.2}]}}],[{sceneId:"demo",technical:{words:[{word:"Open",start:.1,end:.3},{word:"Train.",start:.5,end:.9}]}}]);
  assert.equal(timings.intro[0].text,"Meet GymFeed.");
  assert.ok(Math.abs(timings.intro[0].start-.3)<.001);
  const ass=captionAss([{sceneId:"intro",type:"video",duration:4},{sceneId:"demo",type:"app_capture",duration:2}],timings,48);
  assert.equal(ass.count,2);
  assert.match(ass.text,/0:00:04.10.*Open Train/);
  assert.doesNotMatch(ass.text,/Unwanted/);
});

test("final speech defects are visible to the owner without creative QA or automatic retakes", async () => {
  let row=source();row.status="generated";row.decision.generation.final_technical={sentence_integrity:{checked:true,passed:false,issues:["reply: final sentence is incomplete"]}};
  const service=new MarketingOrchestrator({config:{MARKETING_REVIEW_MODE:"human"},repository:{contentById:async()=>row,updateContent:async(_id,update)=>(row={...row,...update})}});
  await service.reviewContent(row.id);
  assert.equal(row.status,"awaiting_approval");
  assert.match(row.decision.workflow.message,/Needs Review: reply: final sentence is incomplete/);
  assert.match(row.decision.workflow.message,/No automatic retakes/);
});

test("Astra returns a minimal structured edit, without web research or a replacement campaign", async () => {
  let request;
  const brain=new MarketingBrain({OPENAI_CREATIVE_MODEL:"gpt-6-astra",OPENAI_CREATIVE_INPUT_USD_PER_MILLION:1,OPENAI_CREATIVE_OUTPUT_USD_PER_MILLION:1},{responses:{parse:async(input)=>{request=input;return{id:"mock-patch",model:"gpt-6-astra",usage:{input_tokens:100,output_tokens:100},output_parsed:patch()};}}});
  const result=await brain.reviseVideoAsset(source(),"Slow the cuts; keep footage and voice");
  assert.equal(request.model,"gpt-6-astra");
  assert.equal(request.tools,undefined);
  assert.match(request.text.format.name,/selective_video_revision/);
  assert.deepEqual(result.revisionScope.replace_scene_ids,[]);
  assert.deepEqual(result.data.scenes,source().decision.content.scenes);
});

test("a retry after the campaign reset restores reusable sources without asking Astra or fal twice", async () => {
  let row=source();const snapshot=structuredClone(row);const revised=applyVideoRevision(snapshot,patch(),"Only slower cuts");
  row.decision={...row.decision,content:revised.plan,review_revision:2,generation:{},campaign:{id:"campaign",idea_revision:2},pending_asset_revision:{review_id:"original-review",review_revision:1,source:snapshot,planned:true,scope:revised.scope}};
  const controller=new CmoController({repository:{contentById:async()=>structuredClone(row),updateContent:async(_id,update)=>(row={...row,...structuredClone(update)}),
    createContentReview:async()=>({review:{id:"original-review",decision:"reject",status:"failed"},reused:false}),finishContentReview:async()=>{},
  },orchestrator:{humanReviewOnly:true,brain:{reviseVideoAsset:async()=>assert.fail("Do not plan a paid revision twice")}},campaigns:{
    status:async()=>({ideas:[{content_id:row.id,idea_status:"approved",revision:2,content:row}]}),startItem:async()=>({batch:{id:"existing-batch"}}),
  },approvalSheet:{markContentDecision:async()=>{}}});
  controller.sync=async()=>({});controller.produce=async()=>{assert.equal(row.decision.generation.scenes.length,3);return{reviewRequired:true};};
  const result=await controller.assetDecision({contentId:row.id,revision:1,decision:"Reject",instructions:"Only slower cuts"});
  assert.equal(result.action,"asset_replaced_pending_review");
  assert.equal(row.decision.review_revision,2);
});
