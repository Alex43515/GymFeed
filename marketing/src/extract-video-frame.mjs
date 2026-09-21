import { execFile } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const ffmpegExecutable = process.env.FFMPEG_PATH || "ffmpeg";
const ffprobeExecutable = process.env.FFPROBE_PATH || "ffprobe";

export async function extractVideoContactSheet(videoBuffer, durationSeconds = 8, frameCount = 16) {
  const directory = await mkdtemp(join(tmpdir(), "gymfeed-video-"));
  const input = join(directory, "video.mp4");
  const output = join(directory, "contact-sheet.jpg");
  try {
    await writeFile(input, videoBuffer);
    const grid = Math.ceil(Math.sqrt(frameCount));
    const sampleRate = Math.max(0.1, frameCount / durationSeconds).toFixed(4);
    await execFileAsync(ffmpegExecutable, [
      "-hide_banner",
      "-loglevel", "error",
      "-y",
      "-i", input,
      "-vf", `fps=${sampleRate},scale=270:-1:flags=lanczos,tile=${grid}x${grid}:nb_frames=${frameCount}:padding=8:margin=8:color=0x111111`,
      "-frames:v", "1",
      "-q:v", "2",
      output,
    ]);
    return await readFile(output);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}

export async function inspectVideo(videoBuffer) {
  const directory = await mkdtemp(join(tmpdir(), "gymfeed-video-inspect-"));
  const input = join(directory, "video.mp4");
  try {
    await writeFile(input, videoBuffer);
    const { stdout } = await execFileAsync(ffprobeExecutable, [
      "-v", "error",
      "-show_entries", "format=duration:stream=index,codec_type,codec_name,width,height,r_frame_rate",
      "-of", "json",
      input,
    ]);
    const parsed = JSON.parse(stdout);
    const video = parsed.streams?.find((stream) => stream.codec_type === "video") ?? null;
    const audio = parsed.streams?.find((stream) => stream.codec_type === "audio") ?? null;
    return {
      duration_seconds: Number(Number(parsed.format?.duration ?? 0).toFixed(3)),
      width: video?.width ?? null,
      height: video?.height ?? null,
      video_codec: video?.codec_name ?? null,
      frame_rate: video?.r_frame_rate ?? null,
      has_audio: Boolean(audio),
      audio_codec: audio?.codec_name ?? null,
    };
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}

export async function extractVideoAudio(videoBuffer, { startSeconds = 0, durationSeconds } = {}) {
  const directory = await mkdtemp(join(tmpdir(), "gymfeed-video-audio-"));
  const input = join(directory, "video.mp4");
  const output = join(directory, "dialogue.mp3");
  try {
    await writeFile(input, videoBuffer);
    await execFileAsync(ffmpegExecutable, [
      "-hide_banner",
      "-loglevel", "error",
      "-y",
      "-i", input,
      "-ss", String(startSeconds),
      ...(durationSeconds == null ? [] : ["-t", String(durationSeconds)]),
      "-vn",
      "-ac", "1",
      "-ar", "16000",
      "-b:a", "64k",
      output,
    ]);
    return await readFile(output);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}
