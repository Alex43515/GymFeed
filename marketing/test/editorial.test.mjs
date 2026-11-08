import test from "node:test";
import assert from "node:assert/strict";
import { allocateSpeechScene, dialogueCut, editorialPlan, verifySpokenTimeline } from "../src/editorial.mjs";
import { videoScenePrompt, MarketingOrchestrator } from "../src/orchestrator.mjs";
import { platformVideoDuration, productionTimeline, verifiedSceneCaptions } from "../src/render-product-video.mjs";
import { OpenAIVoiceProvider } from "../src/providers/openai-voice.mjs";

test("the edit selects this scene's complete line after an unwanted repeated hook", () => {
  const scene = { scene_id: "reply", asset_type: "generated_video", audio_strategy: "native", spoken_dialogue: "Meet GymFeed.", duration_seconds: 2, source_start_seconds: .4 };
  const technical = { has_audio: true, duration_seconds: 8, words: [
    {word:"Never",start:0,end:.3},{word:"alone.",start:.4,end:.8},
    {word:"Meet",start:2,end:2.4},{word:"GymFeed.",start:2.5,end:3.2},
    {word:"Never",start:3.7,end:4},
  ] };
  const cut = dialogueCut(scene, technical);
  assert.equal(cut.matched, true);
  assert.equal(cut.transcript, "Meet GymFeed.");
  assert.ok(cut.source_start_seconds >= .8 && cut.source_start_seconds < 2);
  assert.ok(cut.source_start_seconds + cut.duration_seconds >= 3.2);
  assert.ok(cut.source_start_seconds + cut.duration_seconds <= 3.7);
  const plan = editorialPlan({scenes:[scene]}, [{scene_id:"reply",asset_type:"generated_video",editorial_cut:cut}]);
  assert.equal(plan.scenes[0].source_start_seconds,cut.source_start_seconds);
  assert.equal(verifiedSceneCaptions(plan,[{scene_id:"reply",technical:{...technical,transcript:cut.transcript}}]).reply, "Meet GymFeed.");
});

test("unmatched speech remains reviewable and captions only the retained source", () => {
  const cut = dialogueCut({spoken_dialogue:"Meet GymFeed",source_start_seconds:2,duration_seconds:2}, {duration_seconds:6,words:[
    {word:"Hook",start:0,end:1},{word:"Meet",start:2.1,end:2.4},{word:"GymFit",start:2.5,end:3.3},{word:"Later",start:5,end:6},
  ]});
  assert.equal(cut.matched,false);
  assert.equal(cut.transcript,"Hook Meet GymFit Later");
  assert.equal(cut.source_start_seconds,0);
  assert.equal(cut.duration_seconds,6);
  assert.match(cut.note,/human review.*no automatic retake/);
});

test("timed editing preserves the approved plan, genuine source cut and complete short story on all platforms", () => {
  const scenes = ["hook","problem","product_proof","payoff","cta"].map((purpose,i) => ({
    scene_id:`s${i}`,purpose,asset_type:i===2?"app_capture":"generated_video",duration_seconds:5,
    source_start_seconds:i===2?3.78:.4,audio_strategy:i===2?"voiceover":"native",spoken_dialogue:"Hello.",voiceover_text:i===2?"Tap Start.":"",
  }));
  const approved={production_version:3,hook:"UNWANTED GLOBAL HOOK",cta:"Get started",target_duration_seconds:25,scenes};
  const snapshot=structuredClone(approved);
  const plan=editorialPlan(approved,[{scene_id:"s1",editorial_cut:{matched:true,source_start_seconds:1,duration_seconds:3.5}}],{s2:6});
  assert.deepEqual(approved,snapshot);
  assert.equal(plan.scenes[2].source_start_seconds,3.78);
  assert.equal(plan.scenes[2].source_cut_duration_seconds,5);
  assert.equal(plan.scenes[2].duration_seconds,6.25);
  for(const platform of ["instagram","tiktok","youtube"]) assert.equal(platformVideoDuration(plan,platform),24.75);
  const timeline=productionTimeline(plan,scenes.filter(s=>s.asset_type==="generated_video").map(s=>({sceneId:s.scene_id,buffer:Buffer.from("clip")})));
  assert.equal(timeline[0].headline,"");
  assert.equal(timeline.at(-1).headline,"Get started");
});

test("non-hook shot requests never include campaign hook, concept, treatment screenplay or revision brief", () => {
  const prompt=videoScenePrompt({decision:{review_instructions:"FULL SCREENPLAY",content:{hook:"Never go alone",concept:"WHOLE FILM",creative_treatment:{visual_mode:"hybrid",why_this_treatment:"ALL LINES"}}}},
    {scene_id:"reply",purpose:"payoff",duration_seconds:4,source_duration_seconds:5,spoken_dialogue:"Meet GymFeed.",action:"Turn and smile"});
  assert.match(prompt,/Meet GymFeed/);
  assert.match(prompt,/130–170/);
  assert.doesNotMatch(prompt,/Never go alone|WHOLE FILM|ALL LINES|FULL SCREENPLAY/);
});

test("ambient B-roll in a mixed-audio film requests no generated speech", async () => {
  let options;
  const service=new MarketingOrchestrator({config:{FAL_VIDEO_USD_PER_SECOND:.2},repository:{reserveCost:async()=>"reservation"},mediaProvider:{createTask:async(input)=>(options=input,{id:"task",model:"test",durationSeconds:4})}});
  await service.queueVideoScene({id:"item",decision:{content:{audio_mode:"mixed"}}},{scene_id:"bag",audio_strategy:"ambient",duration_seconds:3,source_duration_seconds:4,action:"Zip the gym bag"},null,1);
  assert.equal(options.generateAudio,false);
  assert.match(options.prompt,/No spoken dialogue, voiceover/);
});

test("word timings use the supported verbose transcription format without changing creator audio", async () => {
  let request;
  const words=[{word:"GymFeed",start:1,end:1.5}];
  const provider=new OpenAIVoiceProvider({client:{audio:{transcriptions:{create:async(input)=>(request=input,{text:"GymFeed",words})}}}});
  const result=await provider.transcribe({buffer:Buffer.from("original-voice"),timestamps:true});
  assert.equal(request.model,"whisper-1");
  assert.equal(request.response_format,"verbose_json");
  assert.deepEqual(request.timestamp_granularities,["word","segment"]);
  assert.deepEqual(result.words,words);
});

test("native speech gets natural delivery time and handles without mutating the approved scene", () => {
  const scene={scene_id:"long",audio_strategy:"native",spoken_dialogue:"This is my routine and I can see all my sets in GymFeed today.",duration_seconds:3,source_start_seconds:.4,source_duration_seconds:4};
  const allocated=allocateSpeechScene(scene);
  assert.ok(allocated.duration_seconds>=14/2.4+.75);
  assert.ok(allocated.source_duration_seconds>=allocated.source_start_seconds+allocated.duration_seconds+1);
  assert.equal(scene.duration_seconds,3);
  assert.equal(allocateSpeechScene({...scene,audio_strategy:"silent"}).source_duration_seconds,4);
});

test("speech at the file boundary or without a clean ending stays uncut and visibly flagged", () => {
  for(const end of [2.95,3]) {
    const cut=dialogueCut({scene_id:"end",spoken_dialogue:"Meet GymFeed."},{duration_seconds:3,words:[{word:"Meet",start:2,end:2.4},{word:"GymFeed",start:2.5,end}]});
    assert.equal(cut.matched,false);
    assert.equal(cut.duration_seconds,3);
    assert.match(cut.note,/source boundary/);
  }
});

test("word and sentence timings preserve contractions, brand words, and sentence pauses", () => {
  const scene={scene_id:"s",spoken_dialogue:"I've got GymFeed."};
  const cut=dialogueCut(scene,{duration_seconds:7,words:[{word:"I've",start:2,end:2.3},{word:"got",start:2.4,end:2.6},{word:"Gym",start:2.7,end:3},{word:"Feed.",start:3,end:3.3}],segments:[{text:"I've got GymFeed.",start:1.8,end:3.5}],silences:[{start:3.4,end:4.5}]});
  assert.equal(cut.matched,true);
  assert.ok(cut.source_start_seconds+cut.duration_seconds>=3.8);
  assert.equal(verifySpokenTimeline({scenes:[{...scene,audio_strategy:"native"}]},"I've got Gym Feed.").passed,true);
});

test("missing final words are reported per scene instead of marking an incomplete sentence ready", () => {
  const result=verifySpokenTimeline({scenes:[{scene_id:"closing",audio_strategy:"native",spoken_dialogue:"My next set is ready in GymFeed."}]},"My next set is ready in");
  assert.equal(result.passed,false);
  assert.match(result.issues[0],/closing.*complete sentence/);
});
