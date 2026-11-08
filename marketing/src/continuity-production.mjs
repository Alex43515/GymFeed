import { randomUUID } from "node:crypto";
import { continuityInputFingerprint,lockedContinuity,speechBinding,productionScene } from "./production-continuity.mjs";
import { allocateSpeechScene } from "./editorial.mjs";
import { inspectVideo,padSpeechAudio } from "./extract-video-frame.mjs";

export async function ensureContinuity(service,content){
  const generation={...content.decision.generation,generation_id:content.decision.generation?.generation_id??randomUUID()};
  if(generation.continuity?.input_fingerprint===continuityInputFingerprint(content.decision.content))return content;
  const reservation=await service.repository.reserveCost("openai",service.config.OPENAI_ESTIMATED_DAILY_COST_USD??.25,{contentId:content.id,runId:content.run_id,metadata:{operation:"production-continuity-layout"}});
  let result;
  try{result=await service.brain.compileContinuity(content.decision.content,generation.continuity??null);
    await service.repository.settleCost(reservation,result.costUsd,result.responseId);
  }catch(error){
    if(Number.isFinite(error.openaiCostUsd)&&error.openaiCostUsd>0)await service.repository.settleCost(reservation,error.openaiCostUsd,error.openaiResponseId??null).catch(()=>{});
    else await service.repository.releaseCost(reservation).catch(()=>{});
    throw error;
  }
  generation.continuity=lockedContinuity(content.decision.content,result.data,generation.continuity,service.config.MARKETING_CREATOR_VOICES??["coral","nova","shimmer"]);
  return service.repository.updateContent(content.id,{decision:{...content.decision,generation}});
}

export function allocatedScene(content,scene){
  const generation=content.decision.generation, locked=productionScene(content.decision.content,scene,generation?.continuity);
  const speech=generation?.speech?.[scene.scene_id];
  if(scene.audio_strategy!=="native")return locked;
  return allocateSpeechScene({...locked,duration_seconds:Math.max(scene.duration_seconds,Number(speech?.duration_seconds??0)+.75)});
}

export async function prepareLockedSpeech(service,content){
  const generation={...content.decision.generation,speech:{...content.decision.generation?.speech}};
  for(const scene of content.decision.content.scenes){
    const binding=speechBinding(content.decision.content,scene,generation.continuity);
    if(!binding||generation.speech[scene.scene_id]?.fingerprint===binding.fingerprint)continue;
    const reservation=await service.repository.reserveCost("openai",service.config.OPENAI_ESTIMATED_TTS_COST_USD??.05,{contentId:content.id,runId:content.run_id,metadata:{operation:"locked-creator-speech",scene_id:scene.scene_id,speaker_id:binding.speaker_id,voice:binding.voice}});
    let audio;
    try{audio=await service.voiceProvider.generate(binding);await service.repository.settleCost(reservation,service.config.OPENAI_ESTIMATED_TTS_COST_USD??.05,audio.requestId);}
    catch(error){await service.repository.releaseCost(reservation).catch(()=>{});throw error;}
    const technical=await service.timedSpeech(content,{...scene,spoken_dialogue:binding.text},audio.buffer,await inspectVideo(audio.buffer));
    const url=await service.repository.uploadAsset(`${content.content_key}/${generation.generation_id}/speech/${scene.scene_id}-${binding.fingerprint.slice(0,16)}.mp3`,audio.buffer,"audio/mpeg");
    generation.speech[scene.scene_id]={...binding,url,duration_seconds:technical.duration_seconds,technical};
    content=await service.repository.updateContent(content.id,{decision:{...content.decision,generation:{...generation,speech:{...generation.speech}}}});
  }
  return content;
}

export function needsLipSync(content,scene,record){
  return Boolean(content.decision.generation?.continuity&&scene.audio_strategy==="native"
    && record.lip_sync?.speech_fingerprint!==content.decision.generation.speech?.[scene.scene_id]?.fingerprint);
}

export async function queueLockedLipSync(service,content,scene,record){
  const generation=content.decision.generation, speech=generation.speech?.[scene.scene_id];
  if(!speech)throw Error(`Missing canonical audio for ${scene.scene_id}; no fallback to a generated voice`);
  if((record.production_spec?.character_ids??scene.character_ids)?.length!==1)throw Error(`Locked dialogue needs a single visible speaker in ${scene.scene_id}; retain the source and request a single-speaker revision`);
  const spec=record.production_spec??allocatedScene(content,scene);
  const actualDuration=record.technical?.duration_seconds??spec.source_duration_seconds;
  let padded=speech.padded;
  if(!padded||padded.duration_seconds!==actualDuration||padded.source_start_seconds!==spec.source_start_seconds){
    const response=await service.fetchFn(speech.url);if(!response.ok)throw Error(`Canonical audio download failed: ${response.status}`);
    const buffer=await padSpeechAudio(Buffer.from(await response.arrayBuffer()),{startSeconds:spec.source_start_seconds,durationSeconds:actualDuration});
    const url=await service.repository.uploadAsset(`${content.content_key}/${generation.generation_id}/speech/${scene.scene_id}-${speech.fingerprint.slice(0,16)}-source.mp3`,buffer,"audio/mpeg");
    const shift=(item)=>({...item,start:item.start+spec.source_start_seconds,end:item.end+spec.source_start_seconds});
    padded={url,duration_seconds:actualDuration,source_start_seconds:spec.source_start_seconds,technical:{...speech.technical,duration_seconds:actualDuration,words:(speech.technical.words??[]).map(shift),segments:(speech.technical.segments??[]).map(shift),silences:(speech.technical.silences??[]).map(shift)}};
    speech.padded=padded;
    await service.repository.updateContent(content.id,{decision:{...content.decision,generation:{...generation,speech:{...generation.speech,[scene.scene_id]:{...speech}}}}});
  }
  const cost=Number((actualDuration*(service.config.FAL_LIPSYNC_USD_PER_SECOND??.05)).toFixed(6));
  const reservation=await service.repository.reserveCost("fal",cost,{contentId:content.id,runId:content.run_id,metadata:{operation:"locked-dialogue-lipsync",scene_id:scene.scene_id,duration_seconds:actualDuration}});
  const source=record.source_asset_url??record.asset_url;
  let task;
  try{task=await service.mediaProvider.createLipSyncTask({videoUrl:source,audioUrl:padded.url,model:service.config.FAL_LIPSYNC_MODEL});}
  catch(error){await service.repository.releaseCost(reservation).catch(()=>{});throw error;}
  return {...record,status:"queued",operation:"lip_sync",source_task_id:record.source_task_id??record.task_id,source_asset_url:source,
    asset_url:null,task_id:task.id,model:task.model,reservation_id:reservation,estimated_cost_usd:cost,
    lip_sync:{speech_fingerprint:speech.fingerprint,audio_url:padded.url,status:"queued"},production_spec:spec};
}
