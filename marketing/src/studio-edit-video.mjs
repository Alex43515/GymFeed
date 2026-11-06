import { execFile } from "node:child_process";
import { readFile } from "node:fs/promises";
import { promisify } from "node:util";
import { probeMp4 } from "./capture-storage.mjs";

const run = promisify(execFile);
const fps = 30;
const mp4 = ["-c:v", "libx264", "-preset", "fast", "-pix_fmt", "yuv420p",
  "-maxrate", "5M", "-bufsize", "5M", "-movflags", "+faststart"];
const ffmpeg = args => run("ffmpeg", ["-nostdin", "-v", "error", ...args], { timeout: 240_000 });
const seconds = frames => (frames / fps).toFixed(6);

export function planVideoParts(duration) {
  const total = Math.min(60 * fps, Math.round(duration * fps));
  const count = Math.ceil(total / (15 * fps));
  return Array.from({ length: count }, (_, index) => {
    const start = Math.round(index * total / count);
    const frames = Math.round((index + 1) * total / count) - start;
    return { start, frames, duration: frames / fps };
  });
}

export async function cutVideoPart(source, target, part) {
  await ffmpeg(["-ss", seconds(part.start), "-i", source, "-map", "0:v:0", "-map", "0:a:0?",
    "-vf", `fps=${fps},scale=trunc(iw/2)*2:trunc(ih/2)*2,setsar=1,tpad=stop_mode=clone:stop_duration=0.1`,
    "-frames:v", String(part.frames), "-t", seconds(part.frames), ...mp4, "-crf", "18", "-c:a", "aac", target]);
}

export async function joinVideoParts(source, clips, parts, target) {
  const measurements = [];
  for (const clip of clips) measurements.push(await probeMp4(await readFile(clip)));
  const width = Math.floor(measurements[0].width / 2) * 2;
  const height = Math.floor(measurements[0].height / 2) * 2;
  const filters = parts.map((part, index) => {
    const ratio = part.duration / measurements[index].duration;
    return `[${index}:v]setpts=${ratio}*(PTS-STARTPTS),fps=${fps},`
      + `scale=${width}:${height}:force_original_aspect_ratio=decrease:force_divisible_by=2,`
      + `pad=${width}:${height}:(ow-iw)/2:(oh-ih)/2,setsar=1,`
      + `tpad=stop_mode=clone:stop_duration=0.25,trim=end_frame=${part.frames},setpts=PTS-STARTPTS[v${index}]`;
  });
  filters.push(parts.map((_, index) => `[v${index}]`).join("") + `concat=n=${parts.length}:v=1:a=0[out]`);
  await ffmpeg([...clips.flatMap(clip => ["-i", clip]), "-i", source,
    "-filter_complex_threads", "1", "-filter_complex", filters.join(";"), "-map", "[out]", "-map", `${clips.length}:a:0?`,
    "-t", seconds(parts.reduce((sum, part) => sum + part.frames, 0)),
    ...mp4, "-crf", "21", "-c:a", "aac", "-b:a", "128k", target]);
}
