import { createHash, randomUUID } from "node:crypto";
import { z } from "zod";

const text = z.string().nullable();
export const VideoAssetRevisionSchema = z.object({
  summary: z.string(),
  pacing: z.enum(["preserve", "calmer"]),
  captions_enabled: z.boolean().nullable(),
  caption_font_size: z.number().int().min(32).max(64).nullable(),
  cta: text,
  instagram_caption: text,
  scene_order: z.array(z.string()),
  cast_updates: z.array(z.object({ character_id: z.string(), appearance: text, wardrobe: text, voice_direction: text })),
  changes: z.array(z.object({
    scene_id: z.string(), reason: z.string(), remove: z.boolean(), replace_media: z.boolean(),
    source_start_seconds: z.number().nonnegative().nullable(),
    duration_seconds: z.number().positive().max(30).nullable(),
    audio_strategy: z.enum(["native", "voiceover", "ambient", "silent"]).nullable(),
    spoken_dialogue: text, voiceover_text: text,
    action: text, camera: text, subject: text, environment: text, lighting: text,
    visual_style: text, continuity_notes: text, overlay_text: text,
  })),
});

export const VIDEO_ASSET_REVISION_PROMPT = `You are the editor of an EXISTING GymFeed video, not the author of a replacement campaign.
Return a minimal, scene-addressed revision from the owner's feedback. Keep stable scene IDs and leave unrequested fields null.
Editing, captions, CTA, pacing, source-window changes and scene ordering reuse paid footage. They do NOT require new video.
To mute unwanted speech use audio_strategy=silent and spoken_dialogue=""; this reuses the existing picture. Shortening a line to words already present can also reuse its source.
Only set replace_media for a shot whose visible action/performance or spoken words actually need changing. An unchanged shot must keep its exact original description and identity.
Use cast_updates only when the owner explicitly requests a casting, wardrobe or voice change. Never change cast to improve pacing.
Keep every complete sentence. Ask for calmer pacing through pacing=calmer, not by shortening lines or chopping clips. Do not change native dialogue when fixing caption spelling.
Do not regenerate the whole video unless the owner explicitly asks for a new production. Do not expand one bad shot into a new setting, cast, hook and storyboard.
For a deliberately fresh production, simplify within existing scene IDs: remove redundant shots and change only the necessary ones. Real app recordings remain real and run at original speed.
source_start_seconds and duration_seconds change only when an actual source window is known; otherwise use null. Never guess new product footage or invent app results.
scene_order empty means preserve current order. Remove a scene only if the owner requested removing that beat or it is redundant under an explicitly requested tighter edit.
No QA score, no automatic retake loop, no publishing. The finished revision returns to its existing Content Review row for the owner.`;

const digest = (value) => createHash("sha256").update(JSON.stringify(value)).digest("hex");
export const narrationFingerprint = (scene) => digest(scene.voiceover_text?.trim() ?? "");
export function sceneMediaFingerprint(plan, scene) {
  const fields = ["action", "camera", "subject", "environment", "lighting", "visual_style", "continuity_notes", "speaker_id", "character_ids"];
  return digest({ shot: Object.fromEntries(fields.map((key) => [key, scene[key] ?? null])),
    cast: (plan.cast ?? []).filter((actor) => (scene.character_ids ?? []).includes(actor.character_id)).map(({voice_direction,...visual})=>visual),
  });
}

export function fullProductionRequested(instructions) {
  return /(?:fresh|new)\s+(?:production|video)|(?:regenerate|rebuild|replace)\s+(?:the\s+)?(?:whole|entire|all)|do not reuse.*(?:failed|generated).*clips|(?:nov[aiu]|ponov[oai])\s+(?:ce[ol]+|cel[aiou]|kompletan)\s*video|sve\s+(?:kadrove|scene).*ponovo/i.test(instructions);
}

export function applyVideoRevision(source, patch, instructions) {
  const plan = structuredClone(source.decision.content);
  const byId = new Map(plan.scenes.map((scene) => [scene.scene_id, scene]));
  const changes = new Map();
  for (const change of patch.changes) {
    if (!byId.has(change.scene_id) || changes.has(change.scene_id)) throw new Error(`Revision contains an unknown or repeated scene: ${change.scene_id}`);
    changes.set(change.scene_id, change);
  }
  const castingRequested = /(?:change|replace|different|new|dislike|don't like).{0,45}(?:cast|actress|creator|woman|wardrobe|voice)|(?:cast|actress|creator|wardrobe|voice).{0,30}(?:change|replace|different)|(?:promen|zameni|drug|nov).{0,35}(?:glumic|devojk|kreatork|glas|ode[cć]|ženu|zenu)/i.test(instructions);
  if (patch.cast_updates.length && !castingRequested) {
    throw new Error("Casting changes were not requested; existing actor references are preserved.");
  }
  for (const update of patch.cast_updates) {
    const actor = plan.cast?.find((actor) => actor.character_id === update.character_id);
    if (!actor) throw new Error(`Unknown actor in revision: ${update.character_id}`);
    for (const key of ["appearance", "wardrobe", "voice_direction"]) if (update[key] != null) actor[key] = update[key];
  }
  const forced = new Set();
  plan.scenes = plan.scenes.filter((scene) => !changes.get(scene.scene_id)?.remove).map((scene) => {
    const change = changes.get(scene.scene_id);
    if (!change) return scene;
    if (scene.asset_type !== "generated_video" && change.replace_media) throw new Error(`A real app asset cannot be replaced with generated video: ${scene.scene_id}`);
    if (change.replace_media) forced.add(scene.scene_id);
    for (const [key, value] of Object.entries(change)) {
      if (!["scene_id", "remove", "replace_media", "reason"].includes(key) && value !== null) scene[key] = value;
    }
    return scene;
  });
  if (!plan.scenes.length) throw new Error("Revision cannot remove the entire video");
  for (const scene of plan.scenes) {
    if (scene.audio_strategy === "native" && (!scene.spoken_dialogue?.trim() || scene.voiceover_text?.trim() || scene.asset_type !== "generated_video")) throw new Error(`Revision must keep complete native speech or explicitly mute it: ${scene.scene_id}`);
    if (scene.audio_strategy === "voiceover" && (!scene.voiceover_text?.trim() || scene.spoken_dialogue?.trim())) throw new Error(`Revision must supply one narration track without overlapping native speech: ${scene.scene_id}`);
    if (["ambient", "silent"].includes(scene.audio_strategy) && (scene.spoken_dialogue?.trim() || scene.voiceover_text?.trim())) throw new Error(`Muted scenes cannot retain spoken lines: ${scene.scene_id}`);
  }
  if (patch.scene_order.length) {
    if (new Set(patch.scene_order).size !== plan.scenes.length || patch.scene_order.length !== plan.scenes.length
      || patch.scene_order.some((id) => !plan.scenes.some((scene) => scene.scene_id === id))) throw new Error("Revision scene order must contain each retained scene exactly once");
    const retained = new Map(plan.scenes.map((scene) => [scene.scene_id, scene]));
    plan.scenes = patch.scene_order.map((id) => retained.get(id));
  }
  if (patch.captions_enabled !== null) plan.captions_enabled = patch.captions_enabled;
  if (patch.cta !== null) plan.cta = patch.cta;
  if (patch.instagram_caption !== null) plan.platform_copy = { ...plan.platform_copy, instagram_caption: patch.instagram_caption };
  plan.target_duration_seconds = plan.scenes.reduce((sum, scene) => sum + Number(scene.duration_seconds), 0);
  plan.reviewer_instruction_map = patch.changes.map((change) => ({ instruction: instructions, scene_ids: [change.scene_id], implemented_change: change.reason }));
  const normalize = (value) => String(value ?? "").toLowerCase().replace(/[’']/g, "").replace(/[^\p{L}\p{N}]+/gu, " ").trim();
  const replace = plan.scenes.filter((scene) => {
    if (scene.asset_type !== "generated_video") return false;
    const old = byId.get(scene.scene_id);
    const record = source.decision.generation?.scenes?.find((item) => item.scene_id === scene.scene_id);
    const wordsExist = normalize(record?.technical?.source_transcript ?? record?.technical?.transcript);
    const exceedsSavedWindow=normalize(scene.spoken_dialogue).split(" ").filter(Boolean).length/2.4+2.75>Number(record?.technical?.duration_seconds??old.source_duration_seconds??0);
    const changedSpeech = (!source.decision.generation?.continuity||exceedsSavedWindow) && scene.audio_strategy === "native" && normalize(scene.spoken_dialogue) !== normalize(old.spoken_dialogue)
      && !(` ${wordsExist} `.includes(` ${normalize(scene.spoken_dialogue)} `));
    return forced.has(scene.scene_id) || changedSpeech || sceneMediaFingerprint(plan, scene) !== sceneMediaFingerprint(source.decision.content, old);
  }).map((scene) => scene.scene_id);
  const originalCount = source.decision.content.scenes.filter((scene) => scene.asset_type === "generated_video").length;
  const visualActor=({voice_direction,...actor})=>actor;
  const changedCastIds = (plan.cast ?? []).filter((actor) => JSON.stringify(visualActor(actor)) !== JSON.stringify(visualActor(source.decision.content.cast?.find((old) => old.character_id === actor.character_id)??{}))).map((actor) => actor.character_id);
  if (replace.length === originalCount && replace.length > 1 && !fullProductionRequested(instructions) && !changedCastIds.length) {
    throw new Error("This revision would regenerate every shot. The owner requested a revision; preserve unaffected shots or explicitly request a whole new production.");
  }
  if (/editing.only|no new fal|do not (?:submit|generate).*fal|bez (?:nove|novih).*gener|samo monta[zž]/i.test(instructions) && replace.length) {
    throw new Error(`Editing-only revision cannot generate new media (${replace.join(", ")}). Keep existing shots or report what cannot be achieved from them.`);
  }
  return { plan, scope: { summary: patch.summary, replace_scene_ids: replace,
    changed_cast_ids: changedCastIds,
    settings: { calmer: patch.pacing === "calmer", ...(patch.caption_font_size == null ? {} : { caption_font_size: patch.caption_font_size }) },
  } };
}

export function revisionGeneration(source, plan, scope) {
  const previous = source.decision.generation ?? {};
  const replaced = new Set(scope.replace_scene_ids);
  const oldRecords = new Map((previous.scenes ?? []).map((record) => [record.scene_id, record]));
  const scenes = plan.scenes.map((scene) => {
    const saved = oldRecords.get(scene.scene_id);
    if (scene.asset_type !== "generated_video") return { scene_id: scene.scene_id, asset_type: scene.asset_type, status: "ready", attempt: 0 };
    if (replaced.has(scene.scene_id)) return null;
    const asset=saved?.asset_url??saved?.source_asset_url;
    if (!asset) throw new Error(`Cannot silently regenerate missing existing footage: ${scene.scene_id}`);
    return { ...saved, asset_url:asset, ...(saved.asset_url?{}:{lip_sync:null,task_id:saved.source_task_id}), status: "generated", reused_from_revision: source.decision.review_revision ?? 1,
      editorial_cut: null, media_fingerprint: sceneMediaFingerprint(plan, scene) };
  }).filter(Boolean);
  const refs = { ...previous.character_reference_urls };
  for (const id of scope.changed_cast_ids) delete refs[id];
  const sourceTimeline = previous.owner_edit
    ? source.decision.content.scenes
    : previous.editorial_timeline ?? source.decision.content.scenes;
  const master = previous.owner_edit?.previous_asset_urls?.[0] ?? source.asset_urls?.[0];
  let at = 0; const narrationSources = {};
  for (const scene of sourceTimeline) {
    const original = source.decision.content.scenes.find((item) => item.scene_id === scene.scene_id);
    if (original?.audio_strategy === "voiceover" && master) narrationSources[scene.scene_id] = {
      url: master, start: at, duration: scene.duration_seconds, fingerprint: narrationFingerprint(original),
    };
    at += Number(scene.duration_seconds);
  }
  return { mode: "selective_revision", generation_id: randomUUID(), scenes,
    continuity:previous.continuity,speech:{...previous.speech},location_reference_urls:{...previous.location_reference_urls},location_reference_hashes:{...previous.location_reference_hashes},
    reference_image_url: scope.changed_cast_ids.length ? null : previous.reference_image_url,
    character_reference_urls: refs, narration: { ...previous.narration }, narration_sources: narrationSources,
    revision_scope: { ...scope, reused_scene_ids: scenes.filter((scene) => scene.asset_type === "generated_video").map((scene) => scene.scene_id) },
    editorial_settings: { ...previous.editorial_settings, ...scope.settings },
    previous_asset_urls: source.asset_urls, previous_thumbnail_url: source.thumbnail_url,
    platform_variants: {},
  };
}
