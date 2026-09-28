import { createHash } from "node:crypto";

export function storyFingerprint(plan) {
  return createHash("sha256").update(JSON.stringify(plan)).digest("hex");
}

export function storyReviewPassed(review) {
  const keys = ["hook", "natural_dialogue", "product_causality", "payoff", "filmability"];
  return review?.accept === true && Array.isArray(review.required_fixes) && review.required_fixes.length === 0
    && keys.every((key) => Number.isFinite(review.scores?.[key]) && review.scores[key] >= 85 && review.scores[key] <= 100);
}

export function validateVideoStory(plan) {
  if (!(Number(plan.production_version) >= 3)) return plan;
  const cast = plan.cast ?? [];
  const ids = new Set(cast.map((actor) => actor.character_id));
  if (ids.size !== cast.length) throw new Error("Story cast IDs must be unique");
  for (const actor of cast) {
    if (!/^[a-z][a-z0-9_]{0,29}$/.test(actor.character_id) || !actor.appearance?.trim() || !actor.wardrobe?.trim() || !actor.voice_direction?.trim()) throw new Error("Each cast member needs a safe ID, appearance, wardrobe and voice direction");
  }
  const narrative = plan.narrative;
  if (!narrative || !["dialogue_story", "solo_story", "explicit_tutorial"].includes(narrative.format)) throw new Error("Video requires an explicit narrative format");
  for (const key of ["situation", "tension", "product_turn", "payoff"]) {
    if (String(narrative[key] ?? "").trim().length < 10) throw new Error(`Story is missing ${key}`);
  }
  if (narrative.format !== "dialogue_story" && String(narrative.exception_reason ?? "").trim().length < 20) throw new Error("Non-dialogue story needs a specific creative exception_reason");
  const scenes = plan.scenes ?? [];
  const generated = scenes.filter((scene) => scene.asset_type === "generated_video");
  if (plan.creative_treatment?.visual_mode === "product_led" && narrative.format !== "explicit_tutorial") throw new Error("Product-only video requires an explicit tutorial brief");
  if (generated.length && !cast.length) throw new Error("Generated story requires named cast references");
  for (const scene of scenes) {
    const visible = scene.character_ids ?? [];
    if (new Set(visible).size !== visible.length || visible.some((id) => !ids.has(id))) throw new Error(`Unknown or duplicate cast in ${scene.scene_id}`);
    if (scene.asset_type === "generated_video" && !visible.length) throw new Error(`Generated story scene ${scene.scene_id} needs character_ids`);
    if (scene.asset_type !== "generated_video" && visible.length) throw new Error(`Product scene ${scene.scene_id} cannot contain generated cast`);
    if (scene.audio_strategy === "native") {
      if (!visible.includes(scene.speaker_id)) throw new Error(`Native scene ${scene.scene_id} requires one visible speaker_id`);
    } else if (scene.speaker_id) throw new Error(`Non-native scene ${scene.scene_id} must not name a speaker`);
  }
  if (narrative.format === "dialogue_story") {
    const dialogue = scenes.filter((scene) => scene.audio_strategy === "native" && scene.spoken_dialogue?.trim());
    if (cast.length < 2 || dialogue.length < 3 || new Set(dialogue.map((scene) => scene.speaker_id)).size < 2) throw new Error("Dialogue story requires two distinct speakers and at least three native dialogue beats");
    const proofIndex = scenes.findIndex((scene) => scene.asset_type === "app_capture" && ["action", "product_proof"].includes(scene.purpose));
    if (scenes[0]?.audio_strategy !== "native" || scenes[0]?.asset_type !== "generated_video") throw new Error("Dialogue story must open with a native human hook");
    if (proofIndex < 1 || !scenes.slice(proofIndex + 1).some((scene) => scene.audio_strategy === "native" && ["payoff", "cta"].includes(scene.purpose))) throw new Error("Dialogue story needs a human payoff after the real product action");
    const total = scenes.reduce((sum, scene) => sum + scene.duration_seconds, 0);
    if (generated.reduce((sum, scene) => sum + scene.duration_seconds, 0) < total / 2) throw new Error("Dialogue story must keep people on screen for at least half the edit");
  }
  if (narrative.format === "explicit_tutorial" && generated.length) throw new Error("Explicit product tutorial must not contain generated actors");
  return plan;
}

export function sceneCast(plan, scene) {
  return (scene.character_ids ?? []).map((id) => (plan.cast ?? []).find((actor) => actor.character_id === id)).filter(Boolean);
}

export function sceneReferenceUrls(plan, scene, references) {
  if (typeof references === "string") return [references];
  if (!plan.cast?.length) return [];
  return sceneCast(plan, scene).map((actor) => {
    const url = references?.[actor.character_id];
    if (!url) throw new Error(`Missing locked reference for ${actor.character_id} in ${scene.scene_id}`);
    return url;
  });
}
