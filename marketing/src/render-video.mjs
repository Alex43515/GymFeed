import { execFile } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const boldFont = "/usr/share/fonts/truetype/poppins/Poppins-Bold.ttf";
const regularFont = "/usr/share/fonts/truetype/poppins/Poppins-Regular.ttf";

function wrapText(value, maxChars = 28) {
  const lines = [];
  let line = "";
  for (const word of String(value).trim().split(/\s+/).filter(Boolean)) {
    const candidate = line ? `${line} ${word}` : word;
    if (candidate.length > maxChars && line) {
      lines.push(line);
      line = word;
    } else {
      line = candidate;
    }
  }
  if (line) lines.push(line);
  return lines.slice(0, 3).join("\n");
}

export async function renderVideoOverlay(videoBuffer, { hook, cta, durationSeconds }) {
  const directory = await mkdtemp(join(tmpdir(), "gymfeed-render-video-"));
  const input = join(directory, "input.mp4");
  const output = join(directory, "output.mp4");
  const hookFile = join(directory, "hook.txt");
  const ctaFile = join(directory, "cta.txt");
  const hookEnd = Math.max(3, durationSeconds - 2.5);
  const ctaStart = Math.max(3, durationSeconds - 2.5);
  try {
    await Promise.all([
      writeFile(input, videoBuffer),
      writeFile(hookFile, wrapText(hook, 15)),
      writeFile(ctaFile, wrapText(cta, 24)),
    ]);
    const filter = [
      "drawbox=x=48:y=60:w=310:h=76:color=black@0.62:t=fill",
      `drawtext=fontfile=${boldFont}:text='GYMFEED':fontsize=36:fontcolor=white:x=78:y=79`,
      `drawtext=fontfile=${boldFont}:textfile=${hookFile}:fontsize=70:line_spacing=12:fontcolor=white:x=58:y=h-520:box=1:boxcolor=black@0.52:boxborderw=26:enable='between(t,0,${hookEnd})'`,
      `drawtext=fontfile=${regularFont}:textfile=${ctaFile}:fontsize=42:line_spacing=8:fontcolor=white:x=58:y=h-300:box=1:boxcolor=black@0.58:boxborderw=22:enable='gte(t,${ctaStart})'`,
      "drawbox=x=58:y=h-72:w=190:h=8:color=0xe5ff3f:t=fill",
    ].join(",");
    await execFileAsync("ffmpeg", [
      "-hide_banner", "-loglevel", "error", "-y",
      "-i", input,
      "-vf", filter,
      "-c:v", "libx264", "-preset", "medium", "-crf", "20", "-pix_fmt", "yuv420p",
      "-c:a", "aac", "-b:a", "128k",
      "-movflags", "+faststart",
      output,
    ]);
    return await readFile(output);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}
