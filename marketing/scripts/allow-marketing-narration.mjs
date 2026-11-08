import { createClient } from "@supabase/supabase-js";
import { execFileSync } from "node:child_process";
import { randomUUID } from "node:crypto";
import { loadConfig } from "../src/config.mjs";

const config = loadConfig();
const client = createClient(config.SUPABASE_URL, config.SUPABASE_SERVICE_ROLE_KEY, { auth: { persistSession: false } });
const bucket = config.SUPABASE_MARKETING_BUCKET;
const current = await client.storage.getBucket(bucket);
if (current.error) throw current.error;
const mimeTypes = current.data.allowed_mime_types;
if (mimeTypes?.length && !mimeTypes.includes("audio/mpeg")) {
  const changed = await client.storage.updateBucket(bucket, {
    public: current.data.public,
    allowedMimeTypes: [...mimeTypes, "audio/mpeg"],
  });
  if (changed.error) throw changed.error;
}
const audio = execFileSync(process.env.FFMPEG_PATH || "ffmpeg", ["-v", "error", "-f", "lavfi", "-i", "anullsrc=r=16000:cl=mono", "-t", "0.25", "-f", "mp3", "pipe:1"]);
const path = `diagnostics/audio-upload-${randomUUID()}.mp3`;
const uploaded = await client.storage.from(bucket).upload(path, audio, { contentType: "audio/mpeg" });
if (uploaded.error) throw uploaded.error;
try {
  const downloaded = await client.storage.from(bucket).download(path);
  if (downloaded.error) throw downloaded.error;
  if ((await downloaded.data.arrayBuffer()).byteLength !== audio.length) throw new Error("Stored audio size mismatch");
  console.log(JSON.stringify({ bucket, mp3UploadVerified: true, bytes: audio.length }));
} finally {
  const removed = await client.storage.from(bucket).remove([path]);
  if (removed.error) throw removed.error;
}
