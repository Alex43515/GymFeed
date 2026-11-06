// Caption real spoken words in small groups at their original timings.
export function timedSceneCaptions(plan, records, narration = []) {
  const clips = new Map(records.map((record) => [record.scene_id, record]));
  const voices = new Map(narration.map((item) => [item.sceneId, item]));
  return Object.fromEntries((plan.scenes ?? []).map((scene) => {
    const source = scene.audio_strategy === "native" ? clips.get(scene.scene_id)?.technical : voices.get(scene.scene_id)?.technical;
    const offset = scene.audio_strategy === "native" ? Number(scene.source_start_seconds ?? 0) : 0;
    const words = ["native", "voiceover"].includes(scene.audio_strategy) ? (source?.words ?? [])
      .filter((word) => word.start >= offset - .02 && word.end <= offset + scene.duration_seconds + .02)
      .map((word) => ({ ...word, start: Math.max(0, word.start - offset), end: Math.min(scene.duration_seconds, word.end - offset) })) : [];
    const groups = [];
    for (const word of words) {
      const last = groups.at(-1);
      if (!last || last.words.length >= 6 || `${last.words.join(" ")} ${word.word}`.length > 42 || word.start - last.end > .7) {
        groups.push({ start: word.start, end: word.end, words: [word.word] });
      } else { last.end = word.end; last.words.push(word.word); }
    }
    return [scene.scene_id, groups.map((group, i) => ({ start: group.start,
      end: Math.min(scene.duration_seconds, group.end + .18, groups[i + 1]?.start ?? Infinity),
      text: group.words.join(" ").replace(/\bgym feed\b/gi, "GymFeed"),
    }))];
  }));
}

const assTime = (seconds) => {
  const ticks = Math.max(0, Math.round(seconds * 100));
  return `${Math.floor(ticks / 360000)}:${String(Math.floor(ticks / 6000) % 60).padStart(2, "0")}:${String(Math.floor(ticks / 100) % 60).padStart(2, "0")}.${String(ticks % 100).padStart(2, "0")}`;
};
export function captionAss(scenes, timings, fontSize = 46) {
  const lines = ["[Script Info]", "ScriptType: v4.00+", "PlayResX: 1080", "PlayResY: 1920", "WrapStyle: 0", "[V4+ Styles]",
    "Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding",
    `Style: Default,Poppins,${fontSize},&H00FFFFFF,&H00FFFFFF,&H99050605,&H99050605,-1,0,0,0,100,100,0,0,3,12,0,2,90,90,310,1`,
    "[Events]", "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text"];
  let at = 0, count = 0;
  for (const scene of scenes) {
    for (const caption of timings[scene.sceneId] ?? []) {
      if (!(caption.end > caption.start) || !caption.text.trim()) continue;
      const text = caption.text.replace(/[{}\\]/g, "").replace(/[\r\n]+/g, " ");
      const margin = scene.type === "video" ? 310 : 140;
      lines.push(`Dialogue: 0,${assTime(at + caption.start)},${assTime(at + Math.min(caption.end, scene.duration))},Default,,0,0,${margin},,${text}`);
      count++;
    }
    at += scene.duration;
  }
  return { text: lines.join("\n"), count };
}
