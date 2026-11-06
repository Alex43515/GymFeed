// Editorial timing is mechanical, not an AI quality gate. Never resubmit media.
const tokens = (text) => String(text ?? "").toLowerCase().replace(/[’']/g, "").match(/[\p{L}\p{N}]+/gu) ?? [];
const normalize = (text) => tokens(text).join(" ").replace(/\bgym feed\b/g, "gymfeed");

export function allocateSpeechScene(scene) {
  if (scene.audio_strategy !== "native" || !scene.spoken_dialogue?.trim()) return { ...scene };
  const speechSeconds = tokens(scene.spoken_dialogue).length / 2.4;
  const start = Math.max(1, Number(scene.source_start_seconds ?? 0));
  const retained = Math.max(Number(scene.duration_seconds), speechSeconds + .75);
  const source = Math.ceil(Math.max(6, Number(scene.source_duration_seconds ?? 0), start + retained + 1));
  if (source > 30) throw new Error(`Scene ${scene.scene_id}: the complete line needs more than 30 seconds with breathing room. Split the line before paid generation.`);
  return { ...scene, source_start_seconds: start, duration_seconds: retained, source_duration_seconds: source };
}

function uncutSource(scene, technical, note) {
  return { matched: false, source_start_seconds: 0, duration_seconds: Number(technical.duration_seconds),
    transcript: technical.source_transcript ?? technical.transcript ?? (technical.words ?? []).map((word) => word.word).join(" "), words: technical.words ?? [], note,
    issues: [`${scene.scene_id}: ${note}`] };
}

export function dialogueCut(scene, technical, { calmer = false } = {}) {
  const expected = normalize(scene.spoken_dialogue).split(" ").filter(Boolean);
  const words = (technical.words ?? []).filter((word) => Number.isFinite(word.start) && Number.isFinite(word.end) && word.end >= word.start);
  const raw = words.flatMap((word, index) => tokens(word.word).map((token) => ({ token, index })));
  const expanded = [];
  for (let i = 0; i < raw.length; i++) {
    if (raw[i].token === "gym" && raw[i + 1]?.token === "feed") { expanded.push({ token: "gymfeed", index: raw[i].index, endIndex: raw[i + 1].index }); i++; }
    else expanded.push(raw[i]);
  }
  if (!expected.length) return null;
  if (!expanded.length) return uncutSource(scene, technical, "Speech timing is unavailable. The full source is kept for review; no sentence was cut and no paid retake was started.");
  const offset = expanded.findIndex((_, index) => expected.every((token, j) => expanded[index + j]?.token === token));
  if (offset < 0) {
    return uncutSource(scene, technical, "The complete planned line was not found. The full source is kept for human review; no automatic retake.");
  }
  const first = expanded[offset].index;
  const last = expanded[offset + expected.length - 1].endIndex ?? expanded[offset + expected.length - 1].index;
  // Do not let edit handles include an unrelated preceding/following sentence.
  const next = words[last + 1]?.start ?? Number(technical.duration_seconds);
  if (next - words[last].end < .18 || words[last].end > Number(technical.duration_seconds) - .12) {
    return uncutSource(scene, technical, "No clean pause follows the complete line, or speech reaches the source boundary. Full source retained for review; automatic cutting and paid retakes are disabled.");
  }
  let start = Math.max(0, words[first].start - (calmer ? .8 : .5), first ? words[first - 1].end + .04 : 0);
  let end = Math.min(Number(technical.duration_seconds), words[last].end + (calmer ? 1 : .75), next - .04);
  const segment = technical.segments?.find((item) => normalize(item.text) === normalize(scene.spoken_dialogue)
    && item.start <= words[first].start + .2 && item.end >= words[last].end - .2);
  if (segment) { start = Math.max(0, Math.min(start, segment.start - .15)); end = Math.min(next - .04, Number(technical.duration_seconds), Math.max(end, segment.end + .25)); }
  if (first) start = Math.max(start, words[first - 1].end + .04);
  const silence = (technical.silences ?? []).find((pause) => pause.start >= words[last].end - .1 && pause.start < words[last].end + 1
    && pause.end - pause.start >= .15 && pause.start + .12 < next);
  if (silence) end = Math.min(end, Math.max(words[last].end + .5, silence.start + .5));
  if (!(end > start)) return null;
  const speechRate = expected.length / Math.max(.1, words[last].end - words[first].start);
  const issues = speechRate > 3.3 ? [`${scene.scene_id}: source speech is rushed (${Math.round(speechRate * 60)} words/min). No automatic retake; review this shot.`] : [];
  return { matched: true, source_start_seconds: start, duration_seconds: end - start,
    transcript: words.slice(first, last + 1).map((word) => word.word).join(" "),
    words: words.slice(first, last + 1), issues,
  };
}

export function editorialPlan(plan, records, narrationDurations = {}, settings = {}) {
  const byId = new Map(records.map((record) => [record.scene_id, record]));
  const scenes = (plan.scenes ?? []).map((scene) => {
    const record = byId.get(scene.scene_id);
    const cut = record?.editorial_cut;
    // Genuine app recordings keep their approved timing and original speed.
    const result = scene.asset_type === "generated_video" && Number(cut?.duration_seconds) > 0
      ? { ...scene, source_start_seconds: cut.source_start_seconds, duration_seconds: cut.duration_seconds }
      : { ...scene };
    if (settings.calmer && scene.asset_type === "generated_video" && ["ambient", "silent"].includes(scene.audio_strategy)) {
      const available = Number(record?.technical?.duration_seconds ?? scene.source_duration_seconds) - Number(scene.source_start_seconds ?? 0);
      result.duration_seconds = Math.max(result.duration_seconds, Math.min(3, available));
    }
    const narration = Number(narrationDurations[scene.scene_id]);
    if (scene.audio_strategy === "voiceover" && narration > 0) {
      // Keep narration at its recorded speed. Extend the visual tail rather
      // than accelerate or truncate speech; never extend a native app action.
      result.duration_seconds = Math.max(result.duration_seconds, narration + .25);
      result.source_cut_duration_seconds = scene.duration_seconds;
    }
    return result;
  });
  return { ...plan, scenes, preserve_story_timeline: true, natural_audio_pace: true, transcript_only_overlays: true,
    caption_font_size: settings.caption_font_size ?? 46, allow_incomplete_preview: true,
    target_duration_seconds: scenes.reduce((sum, scene) => sum + Number(scene.duration_seconds), 0) };
}

export function verifySpokenTimeline(plan, transcript) {
  const actual = ` ${normalize(transcript)} `;
  let cursor = 0; const issues = [];
  for (const scene of plan.scenes ?? []) {
    const line = scene.audio_strategy === "native" ? scene.spoken_dialogue : scene.audio_strategy === "voiceover" ? scene.voiceover_text : "";
    if (!line?.trim()) continue;
    const expected = ` ${normalize(line)} `;
    const found = actual.indexOf(expected, cursor);
    if (found < 0) issues.push(`${scene.scene_id}: the complete sentence was not confirmed in final audio: ${line}`);
    else cursor = found + expected.length - 1;
  }
  return { checked: true, passed: !issues.length, issues };
}
