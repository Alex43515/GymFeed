import test from "node:test";
import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { mkdtemp,readFile,writeFile,rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { lockedContinuity,productionScene,speechBinding,continuityInputFingerprint } from "../src/production-continuity.mjs";
import { sceneReferenceUrls } from "../src/video-story.mjs";
import { applyVideoRevision,revisionGeneration } from "../src/video-revisions.mjs";
import { FalMediaProvider } from "../src/providers/fal.mjs";
import { OpenAIVoiceProvider } from "../src/providers/openai-voice.mjs";
import { MarketingOrchestrator,videoScenePrompt } from "../src/orchestrator.mjs";

const exec=promisify(execFile);
const fixture=()=>({production_version:3,audio_mode:"mixed",target_duration_seconds:10,captions_enabled:true,cta:"Try GymFeed",character_reference:{required:true,environment_anchor:"Same bench and charcoal wall"},
  cast:[{character_id:"maya",appearance:"Adult woman with a long dark braid",wardrobe:"Cobalt shirt",voice_direction:"Warm natural English with dry humour"},{character_id:"lena",appearance:"Adult woman with short curly hair",wardrobe:"Purple top",voice_direction:"Friendly natural English"}],
  scenes:[
    {scene_id:"hook",asset_type:"generated_video",purpose:"hook",character_ids:["maya","lena"],speaker_id:"maya",audio_strategy:"native",spoken_dialogue:"Meet GymFeed.",voiceover_text:"",environment:"Gym bench",lighting:"Soft light",action:"She answers her friend",camera:"Medium single",duration_seconds:3,source_start_seconds:0,source_duration_seconds:6},
    {scene_id:"demo",asset_type:"app_capture",purpose:"product_proof",character_ids:[],speaker_id:"",audio_strategy:"voiceover",spoken_dialogue:"",voiceover_text:"Open Train.",capture_ref:"test",environment:"Demo account",lighting:"Original",duration_seconds:2,source_start_seconds:.3,source_duration_seconds:6},
    {scene_id:"action",asset_type:"generated_video",purpose:"action",character_ids:["maya"],speaker_id:"",audio_strategy:"ambient",spoken_dialogue:"",voiceover_text:"",environment:"Same equipment corner",lighting:"Same soft light",action:"Walk naturally toward the bench",camera:"Medium wide",duration_seconds:2,source_start_seconds:1,source_duration_seconds:6},
    {scene_id:"reply",asset_type:"generated_video",purpose:"payoff",character_ids:["maya","lena"],speaker_id:"lena",audio_strategy:"native",spoken_dialogue:"Ready now.",voiceover_text:"",environment:"Reverse gym angle",lighting:"Matching light",action:"Answer with a small nod",camera:"Reverse single",duration_seconds:3,source_start_seconds:0,source_duration_seconds:6},
  ]});
const layout=plan=>({locations:[{location_id:"gym",description:"One gym bay with a charcoal wall and the same pale wooden bench",lighting:"Soft neutral overhead lighting",anchors:["Pale wooden bench","Charcoal wall","Unbranded black rack"]}],scene_locations:plan.scenes.map(s=>({scene_id:s.scene_id,location_id:"gym"})),narrator_id:"maya"});

test("one location serves all angles; fixed distinct voices carry across product narration",()=>{
  const plan=fixture(),lock=lockedContinuity(plan,layout(plan),null,["coral","nova"]);
  assert.equal(speechBinding(plan,plan.scenes[0],lock).voice,"coral");
  assert.equal(speechBinding(plan,plan.scenes[1],lock).voice,"coral");
  assert.equal(speechBinding(plan,plan.scenes[3],lock).voice,"nova");
  const a=productionScene(plan,plan.scenes[0],lock),b=productionScene(plan,plan.scenes[3],lock);
  assert.equal(a.environment,b.environment);assert.equal(a.lighting,b.lighting);
  assert.deepEqual(a.character_ids,["maya"]);assert.deepEqual(b.character_ids,["lena"]);
  const refs={maya:"maya.png",lena:"lena.png",_locations:{gym:"gym.png"},_scene_locations:lock.scene_locations};
  assert.deepEqual(sceneReferenceUrls(plan,a,refs),["maya.png","gym.png"]);
  assert.match(videoScenePrompt({decision:{content:plan}},a),/<IMAGE_REF_1> is the EMPTY SET/);
  assert.match(videoScenePrompt({decision:{content:plan}},a),/silent picture generation/);
  assert.equal(continuityInputFingerprint({...plan,cta:"Different CTA"}),lock.input_fingerprint);
});

test("continuity mapping rejects missing, duplicated or invented identities before paid media",()=>{
  const p=fixture(),l=layout(p);
  assert.throws(()=>lockedContinuity(p,{...l,scene_locations:l.scene_locations.slice(1)},null,["coral","nova"]),/every existing scene/);
  assert.throws(()=>lockedContinuity(p,{...l,narrator_id:"invented"},null,["coral","nova"]),/existing actor/);
  assert.throws(()=>lockedContinuity(p,l,null,["coral"]),/distinct configured voices/);
  assert.throws(()=>sceneReferenceUrls(p,{...p.scenes[0],location_id:"gym"},{maya:"maya.png",lena:"lena.png",_locations:{}}),/Missing locked set/);
});

test("provider sync uses the documented audio/video endpoint without truncation or automatic retries",async()=>{
  let submitted;
  const p=new FalMediaProvider({apiKey:"test",client:{config:()=>{},queue:{submit:async(model,input)=>(submitted={model,...input},{request_id:"sync-task"})}}});
  assert.equal((await p.createLipSyncTask({videoUrl:"picture.mp4",audioUrl:"canonical.mp3"})).id,"sync-task");
  assert.equal(submitted.model,"fal-ai/sync-lipsync/v2");
  assert.equal(submitted.input.sync_mode,"silence");
  assert.equal(submitted.input.audio_url,"canonical.mp3");
  assert.equal(submitted.input.enable_safety_checker,true);
});

test("voice provider accepts a persistent per-actor voice instead of the global narrator",async()=>{
  let request;
  const p=new OpenAIVoiceProvider({model:"gpt-4o-mini-tts",voice:"coral",client:{audio:{speech:{create:async(input)=>(request=input,{arrayBuffer:async()=>new ArrayBuffer(1)})}}}});
  await p.generate({text:"Ready now.",voice:"nova",instructions:"Same calm creator, complete sentence."});
  assert.equal(request.voice,"nova");assert.equal(request.speed,1);assert.match(request.instructions,/Same calm creator/);
});

test("the attempt cap includes synchronization and shared sets before any media or voice generation",async()=>{
  let row={id:"budget-test",content_type:"video",status:"planned",decision:{content:fixture()}},paidMedia=0;
  const service=new MarketingOrchestrator({config:{MARKETING_REVIEW_MODE:"human",MARKETING_CONTINUITY_MODE:"locked",FAL_MAX_VIDEO_ATTEMPT_USD:4,FAL_VIDEO_USD_PER_SECOND:.2,FAL_ESTIMATED_IMAGE_COST_USD:.08,FAL_LIPSYNC_USD_PER_SECOND:.05},
    repository:{reserveCost:async provider=>{assert.equal(provider,"openai");return "compile-cost";},settleCost:async()=>{},updateContent:async(_id,patch)=>(row={...row,...patch})},
    brain:{compileContinuity:async plan=>({data:layout(plan),costUsd:.01,responseId:"mock"})},
    voiceProvider:{generate:async()=>assert.fail("Voice synthesis must wait for preflight")},
    mediaProvider:{prepareTask:input=>({durationSeconds:input.durationSeconds}),createTask:async()=>paidMedia++,generateReferenceImage:async()=>paidMedia++},appCaptureResolver:async()=>({})});
  await assert.rejects(service.generateVideo(row),/estimated attempt cost.*exceeds/);
  assert.equal(paidMedia,0);
});

test("locked dialogue revisions reuse picture, fixed voices and set references",()=>{
  const plan=fixture(),lock=lockedContinuity(plan,layout(plan),null,["coral","nova"]);
  const source={id:"v",asset_urls:["master.mp4"],decision:{review_revision:2,content:plan,generation:{continuity:lock,speech:{hook:{fingerprint:"old",url:"voice.mp3"}},location_reference_urls:{gym:"gym.png"},location_reference_hashes:{gym:"set-hash"},scenes:plan.scenes.filter(s=>s.asset_type==="generated_video").map(s=>({scene_id:s.scene_id,asset_type:s.asset_type,asset_url:`${s.scene_id}.mp4`,lip_sync:{speech_fingerprint:"old"}}))}}};
  const patch={summary:"New opening words",pacing:"preserve",captions_enabled:null,caption_font_size:null,cta:null,instagram_caption:null,scene_order:[],cast_updates:[],changes:[{scene_id:"hook",reason:"Owner correction",remove:false,replace_media:false,spoken_dialogue:"My routine is ready."}]};
  const result=applyVideoRevision(source,patch,"Change the opening words, keep the picture");
  assert.deepEqual(result.scope.replace_scene_ids,[]);
  const revised=revisionGeneration(source,result.plan,result.scope);
  assert.equal(revised.continuity.voices.maya,"coral");assert.equal(revised.location_reference_urls.gym,"gym.png");
  assert.equal(revised.scenes[0].asset_url,"hook.mp4");
});

test("real assembly keeps canonical voice and silence, never the clip's random music or generated voice",async(t)=>{
  const ffmpeg=process.env.FFMPEG_PATH||"ffmpeg";
  try{await exec(ffmpeg,["-version"]);}catch{t.skip("FFmpeg is required");return;}
  const dir=await mkdtemp(join(tmpdir(),"gymfeed-continuity-test-"));
  try{
    const rawPath=join(dir,"raw.mp4");
    await exec(ffmpeg,["-v","error","-y","-f","lavfi","-i","color=c=blue:s=180x320:r=30:d=6","-f","lavfi","-i","sine=frequency=440:duration=6","-c:v","libx264","-preset","ultrafast","-c:a","aac",rawPath]);
    const raw=await readFile(rawPath),assets=new Map([["https://fixture/raw.mp4",{buffer:raw,type:"video/mp4"}]]);
    const tones={};
    for(const [voice,frequency] of [["coral",660],["nova",880]]){
      const file=join(dir,`${voice}.mp3`);await exec(ffmpeg,["-v","error","-y","-f","lavfi","-i",`sine=frequency=${frequency}:duration=2`,file]);tones[voice]=await readFile(file);
    }
    let row={id:"v",content_key:"TEST-continuity",content_type:"video",status:"planned",decision:{review_revision:1,content:fixture()}},serial=0;
    const calls=[],tasks=new Map(),tts=[],pendingSpeech=[];
    const repository={contentById:async()=>structuredClone(row),updateContent:async(_id,patch)=>(row={...row,...structuredClone(patch)}),reserveCost:async(provider,cost,meta)=>{calls.push({provider,cost,meta});return`cost-${++serial}`;},settleCost:async()=>{},releaseCost:async()=>{},uploadAsset:async(path,buffer,type)=>{const url=`https://fixture/${path}`;assets.set(url,{buffer,type});return url;}};
    const media={prepareTask:options=>({durationSeconds:options.durationSeconds}),generateReferenceImage:async prompt=>{calls.push({image:prompt});return{buffer:Buffer.from("fake-reference"),mimeType:"image/png"};},
      createTask:async options=>{calls.push({video:options});const id=`base-${++serial}`;tasks.set(id,{output:{video_url:"https://fixture/raw.mp4"},status:"succeeded"});return{id,model:"fake-base"};},
      createLipSyncTask:async options=>{calls.push({sync:options});const id=`sync-${++serial}`;tasks.set(id,{output:{video_url:"https://fixture/raw.mp4"},status:"succeeded"});return{id,model:"fake-sync"};},getTask:async id=>tasks.get(id)};
    const service=new MarketingOrchestrator({config:{MARKETING_REVIEW_MODE:"human",MARKETING_CONTINUITY_MODE:"locked",MARKETING_CREATOR_VOICES:["coral","nova"],FAL_VIDEO_USD_PER_SECOND:.2,FAL_ESTIMATED_IMAGE_COST_USD:.08,FAL_MAX_VIDEO_ATTEMPT_USD:25,FAL_LIPSYNC_USD_PER_SECOND:.05},repository,mediaProvider:media,
      brain:{compileContinuity:async plan=>({data:layout(plan),costUsd:.01,responseId:"mock-layout"})},
      voiceProvider:{generate:async binding=>{tts.push(binding);pendingSpeech.push(binding.text);return{buffer:tones[binding.voice],requestId:"mock-voice"};},transcribe:async()=>{const text=pendingSpeech.shift()??row.decision.content.scenes.map(s=>s.spoken_dialogue||s.voiceover_text).filter(Boolean).join(" ");return{text,words:text.split(" ").map((word,i)=>({word,start:.2+i*.35,end:.4+i*.35})),segments:[],requestId:"mock-transcript"};}},
      fetchFn:async url=>{const asset=assets.get(url);if(!asset)throw Error(`Unexpected fixture ${url}`);return new Response(asset.buffer,{headers:{"Content-Type":asset.type}});},
      appCaptureResolver:async()=>({buffer:raw,verified:true,duration_seconds:6,recorded_interactions:["synthetic capture fixture"]})});
    await service.generateVideo(row);
    assert.equal(calls.filter(c=>c.video).length,3);
    assert.ok(calls.filter(c=>c.video).every(c=>c.video.generateAudio===false));
    assert.equal(calls.filter(c=>c.image?.startsWith("EMPTY FILM LOCATION")).length,1);
    assert.deepEqual(tts.map(x=>x.voice),["coral","coral","nova"]);
    assert.equal((await service.refreshContent(row.id)).pending,true,"Base pictures are saved before the separate speech sync phase");
    assert.equal(calls.filter(c=>c.sync).length,2);
    await service.refreshContent(row.id);await service.reviewContent(row.id);
    assert.equal(row.status,"awaiting_approval");
    assert.equal(row.decision.generation.final_technical.sentence_integrity.passed,true);
    const output=join(dir,"finished.mp4");await writeFile(output,assets.get(row.asset_urls[0]).buffer);
    const timeline=row.decision.generation.editorial_timeline;
    let at=0;const starts={};for(const scene of timeline){starts[scene.scene_id]=at;at+=scene.duration_seconds;}
    async function samples(start){const{stdout}=await exec(ffmpeg,["-v","error","-ss",String(start),"-t","0.3","-i",output,"-vn","-ac","1","-ar","8000","-f","s16le","pipe:1"],{encoding:"buffer"});return stdout;}
    async function frequency(start){const data=await samples(start);let n=0;for(let i=2;i<data.length;i+=2)if(data.readInt16LE(i-2)<=0&&data.readInt16LE(i)>0)n++;return n/(data.length/2/8000);}
    assert.ok(Math.abs(await frequency(starts.hook+.7)-660)<20,"Creator voice must replace generated voice/music");
    assert.ok(Math.abs(await frequency(starts.demo+.7)-660)<20,"Product narration must use the same creator voice");
    assert.ok(Math.abs(await frequency(starts.reply+.7)-880)<20,"Other speaker must retain her distinct fixed voice");
    const ambient=await samples(starts.action+.5);let peak=0;for(let i=0;i<ambient.length;i+=2)peak=Math.max(peak,Math.abs(ambient.readInt16LE(i)));
    assert.ok(peak<20,"Random source music must never leak through ambient shots");
    assert.equal(calls.filter(c=>c.video).length,3,"No full-scene retakes during continuity processing");
    const source=structuredClone(row);
    const changed=applyVideoRevision(source,{summary:"Change two opening words",pacing:"preserve",captions_enabled:null,caption_font_size:null,cta:null,instagram_caption:null,scene_order:[],cast_updates:[],changes:[{scene_id:"hook",reason:"Owner changed the line",remove:false,replace_media:false,spoken_dialogue:"Hello GymFeed."}]},"Change the opening line, keep the picture");
    assert.deepEqual(changed.scope.replace_scene_ids,[]);
    row={...row,status:"planned",asset_urls:[],decision:{...row.decision,review_revision:2,content:changed.plan,generation:revisionGeneration(source,changed.plan,changed.scope)}};
    await service.generateVideo(row);
    assert.equal(calls.filter(c=>c.video).length,3,"Changing dialogue does not submit a new base picture");
    await service.refreshContent(row.id);
    assert.equal(calls.filter(c=>c.sync).length,3,"Only the changed line receives another sync pass");
    await service.refreshContent(row.id);await service.reviewContent(row.id);
    assert.equal(tts.length,4,"Unchanged voices and app narration are reused");
    assert.equal(calls.filter(c=>c.image).length,3,"Two identities and the shared set stay unchanged across revisions");
    assert.equal(row.status,"awaiting_approval");
    assert.equal(row.decision.generation.scenes.find(s=>s.scene_id==="reply").asset_url,source.decision.generation.scenes.find(s=>s.scene_id==="reply").asset_url);
  }finally{await rm(dir,{recursive:true,force:true});}
});
