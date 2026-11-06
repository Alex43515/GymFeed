import test from "node:test";
import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { mkdtemp, readFile, writeFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { editorialPlan } from "../src/editorial.mjs";
import { renderProductVideo } from "../src/render-product-video.mjs";
import { inspectVideo } from "../src/extract-video-frame.mjs";
import { MarketingOrchestrator } from "../src/orchestrator.mjs";
import { narrationFingerprint } from "../src/video-revisions.mjs";

const exec = promisify(execFile);
test("editorial render uses the selected native sentence and leaves narration at normal speed", async (t) => {
  const ffmpeg=process.env.FFMPEG_PATH||"ffmpeg";
  try { await exec(ffmpeg,["-version"]); await exec(process.env.FFPROBE_PATH||"ffprobe",["-version"]); }
  catch { t.skip("FFmpeg and FFprobe required"); return; }
  const dir=await mkdtemp(join(tmpdir(),"gymfeed-editorial-test-"));
  try {
    const clip=join(dir,"source.mp4"), narration=join(dir,"narration.wav"), output=join(dir,"result.mp4");
    await exec(ffmpeg,["-y","-loglevel","error","-f","lavfi","-i","color=c=blue:s=180x320:r=30:d=6",
      "-f","lavfi","-i","sine=frequency=440:duration=3","-f","lavfi","-i","sine=frequency=880:duration=3",
      "-filter_complex","[1:a][2:a]concat=n=2:v=0:a=1[a]","-map","0:v","-map","[a]","-c:v","libx264","-preset","ultrafast","-c:a","aac",clip]);
    await exec(ffmpeg,["-y","-loglevel","error","-f","lavfi","-i","sine=frequency=660:duration=2",narration]);
    const approved={production_version:3,audio_mode:"mixed",cta:"Get started",scenes:[
      {scene_id:"native",asset_type:"generated_video",purpose:"hook",duration_seconds:1.5,source_start_seconds:0,audio_strategy:"native",spoken_dialogue:"Meet GymFeed."},
      {scene_id:"demo",asset_type:"app_capture",purpose:"product_proof",duration_seconds:1,source_start_seconds:.25,capture_ref:"test",audio_strategy:"voiceover",voiceover_text:"Open your routine."},
    ]};
    const plan=editorialPlan(approved,[{scene_id:"native",editorial_cut:{matched:true,source_start_seconds:3.5,duration_seconds:1.5}}],{demo:2});
    const source=await readFile(clip);
    const rendered=await renderProductVideo(plan,{sceneVideoBuffers:[{sceneId:"native",buffer:source}],
      sceneVoiceoverBuffers:[{sceneId:"demo",buffer:await readFile(narration)}],
      sceneCaptions:{native:"Meet GymFeed.",demo:"Open your routine."},
      appCaptureResolver:async()=>({buffer:source,verified:true,duration_seconds:6,recorded_interactions:["synthetic integration fixture"]}),
    });
    await writeFile(output,rendered);
    const technical=await inspectVideo(rendered);
    assert.ok(Math.abs(technical.duration_seconds-3.75)<.1,`Unexpected duration ${technical.duration_seconds}`);
    // Frequency distinguishes source speech and detects time-compressed TTS.
    async function frequency(start) {
      const {stdout}=await exec(ffmpeg,["-v","error","-ss",String(start),"-t","0.5","-i",output,"-vn","-ac","1","-ar","8000","-f","s16le","pipe:1"],{encoding:"buffer"});
      let crossings=0;
      for(let i=2;i<stdout.length;i+=2) if(stdout.readInt16LE(i-2)<=0&&stdout.readInt16LE(i)>0) crossings++;
      return crossings/(stdout.length/2/8000);
    }
    assert.ok(Math.abs(await frequency(.4)-880)<15,"The selected native speech must come from the later source cut");
    assert.ok(Math.abs(await frequency(1.8)-660)<15,"Narration must not be accelerated");

    // Run the real assembly/review path with saved footage and narration.
    // The provider is mocked: no generation or TTS request is permitted.
    let row={id:"synthetic-revision",content_type:"video",content_key:"synthetic-test",status:"generating",decision:{content:approved,generation:{
      generation_id:"reuse-only",revision_scope:{replace_scene_ids:[],reused_scene_ids:["native"]},
      scenes:[{scene_id:"native",asset_type:"generated_video",status:"generated",asset_url:"https://fixture/native",technical:{duration_seconds:6,has_audio:true,speech_timing_source:"full_source",source_transcript:"Meet GymFeed.",words:[{word:"Meet",start:3.5,end:3.8},{word:"GymFeed.",start:4,end:4.5}]}},
        {scene_id:"demo",asset_type:"app_capture",status:"ready"}],
      narration:{demo:{fingerprint:narrationFingerprint(approved.scenes[1]),url:"https://fixture/narration",technical:{words:[{word:"Open",start:.1,end:.5},{word:"your",start:.6,end:.9},{word:"routine.",start:1.1,end:1.8}]},words:[]}},
    }}};
    const assets=new Map([["https://fixture/native",source],["https://fixture/narration",await readFile(narration)]]);
    const calls=[];
    const service=new MarketingOrchestrator({config:{MARKETING_REVIEW_MODE:"human",OPENAI_ESTIMATED_TRANSCRIPTION_COST_USD:.01},
      repository:{contentById:async()=>row,updateContent:async(_id,patch)=>(row={...row,...structuredClone(patch)}),
        uploadAsset:async(path,buffer)=>{const url=`https://fixture/${path}`;assets.set(url,buffer);return url;},
        reserveCost:async(provider,_cost,metadata)=>{calls.push({provider,metadata});return "mock";},settleCost:async()=>{},
      },
      fetchFn:async(url)=>new Response(assets.get(url),{headers:{"Content-Type":url.endsWith("narration")?"audio/wav":"video/mp4"}}),
      voiceProvider:{generate:async()=>assert.fail("Existing narration must be reused"),transcribe:async()=>({text:"Meet GymFeed. Open your routine.",words:[],requestId:"mock-final"})},
      mediaProvider:{createTask:async()=>assert.fail("No new fal generation")},
      appCaptureResolver:async()=>({buffer:source,verified:true,duration_seconds:6,recorded_interactions:["synthetic integration fixture"]}),
    });
    const finished=await service.finishVideoGeneration(row,row.decision.generation.scenes,row.decision.generation);
    assert.equal(finished.pending,false);
    assert.equal(row.decision.generation.final_technical.sentence_integrity.passed,true,"The first shared platform master must actually receive final audio verification");
    assert.equal(calls.length,1,"Only final sentence verification is needed; no new scene, voice or creative QA");
    assert.equal(calls[0].metadata.metadata.operation,"final-sentence-integrity");
    assert.equal(new Set(row.asset_urls).size,1,"Every platform retains the same complete story");
    assert.ok(Math.abs(row.decision.generation.platform_variants.youtube.duration_seconds-4.5)<.1);
    await service.reviewContent(row.id);
    assert.equal(row.status,"awaiting_approval");
    assert.match(row.decision.workflow.message,/Ready for your review/);
    assert.equal(row.qa_score,null);
  } finally { await rm(dir,{recursive:true,force:true}); }
});
