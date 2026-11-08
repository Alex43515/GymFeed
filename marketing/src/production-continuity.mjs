import { createHash } from "node:crypto";
import { z } from "zod";

export const ContinuityLayoutSchema = z.object({
  locations: z.array(z.object({location_id:z.string().regex(/^[a-z][a-z0-9_]{0,29}$/),description:z.string().min(10),lighting:z.string().min(3),anchors:z.array(z.string()).min(1).max(8)})).min(1).max(5),
  scene_locations:z.array(z.object({scene_id:z.string(),location_id:z.string()})),
  narrator_id:z.string(),
});
export const CONTINUITY_DIRECTOR_PROMPT = `Compile the EXISTING approved storyboard into a production continuity layout. Do not change dialogue, story, cast, claims or shot IDs.
Assign each shot to a stable physical location. All angles in the same gym bay use ONE location ID, description, lighting and exact equipment/room anchors, even when wording says "same corner", "bench" or "reverse angle". A different camera angle is not a new room.
An explicitly motivated move from home to outdoors to the gym uses separate locations. Do not merge different destinations. Product-demo inserts inherit the surrounding story location without pretending the demo account belongs to the actor.
Describe reusable empty sets, not actors or generated app UI. Choose narrator_id from the existing cast: normally the lead, so product narration retains her voice. Preserve existing location IDs and descriptions from the previous layout when the place has not changed.
Every storyboard scene must appear exactly once in scene_locations. No invented people, readable signage, music URLs or new story beats.`;
const digest = (value) => createHash("sha256").update(JSON.stringify(value)).digest("hex");
export function continuityInputFingerprint(plan) {
  return digest({cast:(plan.cast??[]).map(({character_id})=>character_id),anchor:plan.character_reference?.environment_anchor,
    scenes:(plan.scenes??[]).map(({scene_id,environment,lighting})=>({scene_id,environment,lighting}))});
}
export function lockedContinuity(plan, layout, previous, voicePool) {
  const cast=plan.cast??[], ids=new Set(cast.map(actor=>actor.character_id));
  const places=new Set(layout.locations.map(place=>place.location_id));
  if(places.size!==layout.locations.length)throw Error("Continuity locations must have unique IDs");
  const mapped=new Map(layout.scene_locations.map(item=>[item.scene_id,item.location_id]));
  if(mapped.size!==layout.scene_locations.length || mapped.size!==plan.scenes.length || plan.scenes.some(scene=>!places.has(mapped.get(scene.scene_id))))throw Error("Continuity layout must assign every existing scene exactly once");
  if(!ids.has(layout.narrator_id))throw Error("Continuity narration must use an existing actor's voice");
  const voices={}, used=new Set();
  for(const actor of cast){
    const saved=previous?.voices?.[actor.character_id];
    const voice=saved&&voicePool.includes(saved)?saved:voicePool.find(item=>!used.has(item));
    if(!voice||used.has(voice))throw Error("Not enough distinct configured voices for this cast");
    used.add(voice);voices[actor.character_id]=voice;
  }
  for(const scene of plan.scenes){
    if(scene.asset_type==="generated_video"&&(!(scene.character_ids?.length)||scene.character_ids.some(id=>!ids.has(id))))throw Error(`Missing locked identity in ${scene.scene_id}`);
    if(scene.audio_strategy==="native"&&!ids.has(scene.speaker_id))throw Error(`Missing locked speaker in ${scene.scene_id}`);
  }
  const lead=plan.scenes.find(scene=>scene.audio_strategy==="native")?.speaker_id;
  return {version:1,input_fingerprint:continuityInputFingerprint(plan),...layout,narrator_id:ids.has(lead)?lead:layout.narrator_id,voices,
    music_policy:"none",source_audio_policy:"discard",dialogue_policy:"canonical_audio_lipsync"};
}
export function productionScene(plan, scene, continuity) {
  if(!continuity)return scene;
  const place=continuity.locations.find(item=>item.location_id===continuity.scene_locations.find(item=>item.scene_id===scene.scene_id)?.location_id);
  if(!place)throw Error(`Missing locked location for ${scene.scene_id}`);
  const native=scene.audio_strategy==="native";
  return {...scene,location_id:place.location_id,environment:place.description,lighting:place.lighting,
    subject:native?`${scene.speaker_id}, the sole visible speaker from the locked identity reference. All conversation partners remain off-camera.`:scene.subject,
    camera:native?`A matched medium or close single on ${scene.speaker_id} only, following the intended movement: ${scene.camera}. Keep the set orientation and eyeline consistent; no listener enters the frame.`:scene.camera,
    character_ids:native?[scene.speaker_id]:scene.character_ids,
    audio_strategy:scene.audio_strategy,ambient_audio:"No generated sound, music, narration or captions. The final audio is supplied separately.",
    continuity_notes:`${scene.continuity_notes??""}; LOCKED SET: ${place.anchors.join("; ")}. Preserve this exact room, equipment, colours and layout. ${native?"Frame the named speaker alone; conversation partners stay off-camera for this single-speaker angle.":""}`,
    canonical_audio:true,
  };
}
export function speechBinding(plan,scene,continuity){
  const text=scene.audio_strategy==="native"?scene.spoken_dialogue:scene.audio_strategy==="voiceover"?scene.voiceover_text:"";
  if(!text?.trim())return null;
  const id=scene.audio_strategy==="native"?scene.speaker_id:continuity.narrator_id;
  const actor=plan.cast.find(actor=>actor.character_id===id),voice=continuity.voices[id];
  if(!actor||!voice)throw Error(`Unbound production voice in ${scene.scene_id}`);
  const instructions=`The same fictional adult creator throughout this film. ${actor.voice_direction} Natural conversational English, 130-160 words per minute, complete sentences and brief pauses. No music or extra words. Pronounce GymFeed as Gym Feed.`;
  return {speaker_id:id,voice,text:text.trim(),instructions,fingerprint:digest({id,voice,text:text.trim(),instructions})};
}
export const locationFingerprint=(place)=>digest(place);
export function locationReferencePrompt(place){return `EMPTY FILM LOCATION REFERENCE: ${place.location_id}. ${place.description}. Lighting: ${place.lighting}. Exact fixed landmarks: ${place.anchors.join("; ")}. Wide view showing the physical layout for matched angles. No people, readable text, logos, UI, phones or watermarks. Photorealistic, natural practical lighting. This is a set reference, not a poster.`;}
