import { execFile } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import sharp from "sharp";
import { renderProductSlide } from "./render-product-slide.mjs";
import { verifiedScreenshotUrl } from "./product-brief.mjs";

const execFileAsync = promisify(execFile);
const ffmpegExecutable = process.env.FFMPEG_PATH || "ffmpeg";
const ffprobeExecutable = process.env.FFPROBE_PATH || "ffprobe";
const PRODUCT_VIDEO_SEGMENT_SECONDS = 2.5;
export const PRODUCT_VIDEO_DURATION_SECONDS = 4 * PRODUCT_VIDEO_SEGMENT_SECONDS;
const wordmarkUrl = new URL("../assets/brand/gymfeed-wordmark-white.png", import.meta.url);

function escapeXml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&apos;");
}

function wrapText(value, maxChars = 22, maxLines = 3) {
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
  if (lines.length > maxLines) throw new Error(`Video text exceeds ${maxLines} readable lines: ${value}`);
  return lines;
}

async function renderVideoOverlay({ headline, subtitle = "", label = "GYMFEED" }) {
  const headlineLines = wrapText(headline, 30, 4);
  const subtitleLines = wrapText(subtitle, 42, 4);
  const svg = `<svg width="1080" height="1920" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="top" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#000" stop-opacity=".82"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
      <linearGradient id="bottom" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".9"/></linearGradient>
      <style>
        text { font-family: Poppins, sans-serif; }
        .label { font-size: 28px; font-weight: 700; fill: #0bea70; letter-spacing: 3px; }
        .headline { font-size: 58px; font-weight: 700; fill: #fff; }
        .subtitle { font-size: 40px; font-weight: 600; fill: #fff; }
      </style>
    </defs>
    <rect width="1080" height="460" fill="url(#top)"/>
    <rect y="1120" width="1080" height="800" fill="url(#bottom)"/>
    ${subtitleLines.length ? `<rect x="56" y="1240" width="968" height="${96 + subtitleLines.length * 58}" rx="32" fill="#050806" fill-opacity=".78" stroke="#0bea70" stroke-opacity=".45"/>` : ""}
    ${subtitleLines.map((line, index) => `<text class="subtitle" text-anchor="middle" x="540" y="${1320 + index * 58}">${escapeXml(line)}</text>`).join("")}
    <rect x="64" y="1510" width="300" height="58" rx="29" fill="#07120b" stroke="#0bea70" stroke-width="2"/>
    <text class="label" x="92" y="1549">${escapeXml(label)}</text>
    ${headlineLines.map((line, index) => `<text class="headline" x="68" y="${1630 + index * 66}">${escapeXml(line)}</text>`).join("")}
    <text class="subtitle" x="68" y="1885">gymfeed.io</text>
  </svg>`;
  const wordmark = await sharp(await readFile(wordmarkUrl)).resize({ width: 252 }).png().toBuffer();
  return sharp(Buffer.from(svg)).composite([{ input: wordmark, left: 74, top: 68 }]).png().toBuffer();
}

async function renderProductScreenOverlay({ headline, subtitle = "" }) {
  const lines = wrapText(headline, 34, 3);
  const subtitleLines = wrapText(subtitle, 42, 3);
  const svg = `<svg width="1080" height="1920" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="top" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#000" stop-opacity=".9"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
      <style>
        text { font-family: Poppins, sans-serif; }
        .headline { font-size: 46px; font-weight: 700; fill: #fff; }
        .subtitle { font-size: 36px; font-weight: 500; fill: #fff; }
      </style>
    </defs>
    <rect width="1080" height="340" fill="url(#top)"/>
    ${lines.map((line, index) => `<text class="headline" x="42" y="${136 + index * 52}">${escapeXml(line)}</text>`).join("")}
    <rect x="42" y="1660" width="996" height="190" rx="24" fill="#050605" fill-opacity=".95"/>
    ${subtitleLines.map((line, index) => `<text class="subtitle" x="62" y="${1710 + index * 46}">${escapeXml(line)}</text>`).join("")}
    <text class="subtitle" x="42" y="1890">gymfeed.io</text>
  </svg>`;
  const wordmark = await sharp(await readFile(wordmarkUrl)).resize({ width: 184 }).png().toBuffer();
  return sharp(Buffer.from(svg)).composite([{ input: wordmark, left: 42, top: 36 }]).png().toBuffer();
}

async function inspectMedia(path) {
  const { stdout } = await execFileAsync(ffprobeExecutable, [
    "-v", "error", "-show_entries", "format=duration:stream=codec_type,duration", "-of", "json", path,
  ]);
  const result = JSON.parse(stdout);
  return {
    duration: Number(result.format?.duration ?? 0),
    hasAudio: result.streams?.some((stream) => stream.codec_type === "audio") ?? false,
  };
}

export function validateRetainedCut(scene, actualDuration) {
  const start = Number(scene.source_start_seconds ?? scene.start ?? 0);
  const duration = Number(scene.duration_seconds ?? scene.duration);
  if (!Number.isFinite(actualDuration) || actualDuration <= 0 || !Number.isFinite(start) || start < 0 || !Number.isFinite(duration) || duration <= 0 || start + duration > actualDuration + 0.08) {
    throw new Error(`Source does not cover retained cut for ${scene.scene_id ?? scene.sceneId ?? "scene"}: ${start}s + ${duration}s / ${actualDuration}s`);
  }
  return { start, duration };
}

export function validateAppCaptureSource(scene, asset) {
  if (!asset?.verified || !Array.isArray(asset.recorded_interactions) || !asset.recorded_interactions.length || (!asset.buffer && !asset.path)) {
    throw new Error(`Missing verified recorded interactions for app capture: ${scene.captureRef ?? scene.capture_ref}`);
  }
  validateRetainedCut(scene, Number(asset.duration_seconds));
  return asset;
}

function productScenePlan(plan) {
  const captions = plan.caption_text?.filter(Boolean) ?? [];
  const proofs = plan.proof_points?.filter(Boolean) ?? [];
  const screenshots = plan.screenshot_refs ?? [];
  const availableScreenshots = screenshots.filter(Boolean);
  const screenshotAt = (index) => availableScreenshots[index] ?? availableScreenshots[index % Math.max(availableScreenshots.length, 1)] ?? "";
  const resultProof = proofs[2] ?? proofs[1] ?? proofs[0] ?? plan.product_promise;
  const qualifiedResultProof = plan.product_feature === "scan_equipment"
    ? `${resultProof} When unsure, follow gym and manufacturer instructions.`
    : resultProof;
  return [
    {
      headline: plan.hook,
      body: plan.product_promise,
      screenshotRef: screenshotAt(0),
    },
    {
      headline: captions[1] ?? "Your plan, ready to use.",
      body: proofs[1] ?? proofs[0] ?? plan.product_promise,
      screenshotRef: screenshotAt(1),
    },
    {
      headline: captions[2] ?? "One connected fitness life.",
      body: qualifiedResultProof,
      screenshotRef: screenshotAt(2),
    },
    {
      headline: plan.cta,
      body: [proofs[3], "Your plan. Your progress. Your people. One GymFeed."].filter(Boolean).join(" "),
      screenshotRef: availableScreenshots.at(-1) ?? "",
    },
  ];
}

function timelinePlan(plan, hasSupportingVideo) {
  const productScenes = productScenePlan(plan);
  const mode = plan.creative_treatment?.visual_mode ?? "product_led";
  if (!hasSupportingVideo || mode === "product_led") {
    return productScenes.map((scene) => ({ ...scene, type: "image", duration: PRODUCT_VIDEO_SEGMENT_SECONDS }));
  }
  if (mode === "human_led") {
    return [
      { type: "video", start: 0, duration: 4, headline: plan.hook },
      { type: "video", start: 4, duration: 3, headline: plan.caption_text?.[1] ?? plan.proof_points?.[0] ?? plan.product_promise },
      { ...productScenes.at(-1), type: "image", duration: 3 },
    ];
  }
  const requestedHumanSeconds = PRODUCT_VIDEO_DURATION_SECONDS
    * (plan.creative_treatment?.people_screen_time_percent ?? 60) / 100;
  const humanSeconds = Math.max(4, Math.min(7, requestedHumanSeconds));
  const productSeconds = PRODUCT_VIDEO_DURATION_SECONDS - humanSeconds;
  const firstHumanSeconds = Number((humanSeconds * 0.55).toFixed(2));
  const secondHumanSeconds = Number((humanSeconds - firstHumanSeconds).toFixed(2));
  const productSceneSeconds = Number((productSeconds / 2).toFixed(2));
  return [
    { type: "video", start: 0, duration: firstHumanSeconds, headline: plan.hook },
    { ...productScenes[1], type: "image", duration: productSceneSeconds },
    { type: "video", start: firstHumanSeconds, duration: secondHumanSeconds, headline: plan.caption_text?.[2] ?? plan.proof_points?.[1] ?? plan.product_promise },
    { ...productScenes.at(-1), type: "image", duration: productSceneSeconds },
  ];
}

export function plannedVideoDuration(plan) {
  return plan.target_duration_seconds
    ?? plan.scenes?.reduce((total, scene) => total + Number(scene.duration_seconds ?? 0), 0)
    ?? PRODUCT_VIDEO_DURATION_SECONDS;
}

export function productionTimeline(plan, sceneVideoBuffers = [], supportingVideoBuffer = null) {
  const plannedScenes = plan.scenes ?? [];
  if (plannedScenes.some((scene) => scene.asset_type)) {
    const videos = new Map(sceneVideoBuffers.map((item) => [item.sceneId, item]));
    return plannedScenes.map((scene, index) => {
      const common = {
        sceneId: scene.scene_id,
        duration: Number(scene.duration_seconds),
        start: Number(scene.source_start_seconds ?? 0),
        headline: scene.overlay_text || (index === 0 ? plan.hook : plan.caption_text?.[index] ?? plan.product_promise),
        subtitle: scene.spoken_dialogue || scene.voiceover_text || "",
        audioStrategy: scene.audio_strategy ?? null,
        voiceoverText: scene.voiceover_text ?? "",
        purpose: scene.purpose,
      };
      if (scene.asset_type === "generated_video") {
        const generated = videos.get(scene.scene_id);
        if (!generated?.buffer) throw new Error(`Missing generated clip for scene ${scene.scene_id}`);
        return {
          ...common,
          type: "video",
          buffer: generated.buffer,
          reframe: generated.localTreatment?.reframe ?? null,
        };
      }
      if (scene.asset_type === "app_capture") return { ...common, type: "app_capture", captureRef: scene.capture_ref };
      if (scene.asset_type !== "gymfeed_screen") throw new Error(`Unsupported video asset type: ${scene.asset_type}`);
      return {
        ...common,
        type: "image",
        body: plan.proof_points?.[index] ?? plan.product_promise,
        screenshotRef: scene.screenshot_ref,
        directProduct: true,
        showOverlay: true,
      };
    });
  }
  return timelinePlan(plan, Boolean(supportingVideoBuffer)).map((scene) => (
    scene.type === "video" ? { ...scene, buffer: supportingVideoBuffer } : scene
  ));
}

export async function renderProductVideo(plan, {
  screenshotResolver = verifiedScreenshotUrl,
  supportingVideoBuffer = null,
  sceneVideoBuffers = [],
  voiceoverBuffer = null,
  sceneVoiceoverBuffers = [],
  appCaptureResolver = async (reference) => { throw new Error(`Verified app capture resolver is not configured: ${reference}`); },
} = {}) {
  const scenes = productionTimeline(plan, sceneVideoBuffers, supportingVideoBuffer);
  const totalDuration = scenes.reduce((total, scene) => total + Number(scene.duration), 0);
  const productionV2 = Number(plan.production_version) >= 2;
  if (productionV2 && voiceoverBuffer) throw new Error("Production V2 needs sceneVoiceoverBuffers; a full-master voiceover could overlap native speech");
  const narration = new Map(sceneVoiceoverBuffers.map((item) => [item.sceneId, item.buffer]));
  const directory = await mkdtemp(join(tmpdir(), "gymfeed-product-video-"));
  const output = join(directory, "gymfeed-product-video.mp4");
  try {
    for (let index = 0; index < scenes.length; index += 1) {
      const scene = scenes[index];
      scene.audioStrategy ??= ["native_audio", "ambient_plus_captions"].includes(plan.audio_mode) && scene.type === "video" ? "native" : "silent";
      if (productionV2 && !["native", "voiceover", "ambient", "silent"].includes(scene.audioStrategy)) throw new Error(`Missing audio strategy for ${scene.sceneId}`);
      if (scene.audioStrategy === "voiceover") {
        const buffer = narration.get(scene.sceneId);
        if (!buffer) throw new Error(`Missing narration for scene ${scene.sceneId}`);
        scene.voicePath = join(directory, `narration-${index}.mp3`);
        await writeFile(scene.voicePath, buffer);
        const spoken = await inspectMedia(scene.voicePath);
        if (!spoken.hasAudio || spoken.duration > scene.duration + 0.08) throw new Error(`Narration does not fit retained cut for ${scene.sceneId}: ${spoken.duration}s / ${scene.duration}s`);
      }
      if (scene.type === "app_capture") {
        const asset = validateAppCaptureSource(scene, await appCaptureResolver(scene.captureRef));
        scene.buffer = asset.buffer ?? await readFile(asset.path);
      }
      if (["video", "app_capture"].includes(scene.type)) {
        scene.videoPath = join(directory, `supporting-${index}.mp4`);
        await writeFile(scene.videoPath, scene.buffer);
        const technical = await inspectMedia(scene.videoPath);
        validateRetainedCut(scene, technical.duration);
        scene.hasAudio = technical.hasAudio;
        if (scene.audioStrategy === "native" && !technical.hasAudio) throw new Error(`Native speech is missing for scene ${scene.sceneId}`);
        const overlay = scene.type === "app_capture" ? renderProductScreenOverlay : renderVideoOverlay;
        await writeFile(join(directory, `overlay-${index}.png`), await overlay({ headline: scene.headline, subtitle: scene.subtitle }));
        continue;
      }
      const screenshotUrl = scene.screenshotRef ? await screenshotResolver(scene.screenshotRef) : null;
      if (scene.directProduct && screenshotUrl) {
        const screenshot = await readFile(screenshotUrl);
        await writeFile(join(directory, `scene-${index}.png`), screenshot);
        if (scene.showOverlay) {
          await writeFile(join(directory, `product-overlay-${index}.png`), await renderProductScreenOverlay({ headline: scene.headline, subtitle: scene.subtitle }));
        }
        continue;
      }
      const image = await renderProductSlide({
        width: 1080,
        height: 1920,
        headline: scene.headline,
        body: scene.body,
        feature: plan.feature_sequence?.[Math.min(index, plan.feature_sequence.length - 1)] ?? plan.product_feature,
        cta: index === scenes.length - 1 ? plan.cta : "Get started with GymFeed",
        index,
        total: scenes.length,
        screenshotUrl,
      });
      await writeFile(join(directory, `scene-${index}.png`), image);
    }

    const voiceoverPath = voiceoverBuffer ? join(directory, "voiceover.mp3") : null;
    if (voiceoverPath) {
      await writeFile(voiceoverPath, voiceoverBuffer);
      const spoken = await inspectMedia(voiceoverPath);
      if (!spoken.hasAudio || spoken.duration > totalDuration + 0.08) throw new Error("Full-master narration would be truncated by the edit");
    }
    const sceneAudio = !voiceoverPath && scenes.some((scene) => scene.voicePath || scene.hasAudio && ["native", "ambient"].includes(scene.audioStrategy));
    if (productionV2 && !sceneAudio) throw new Error("Production video has no audible story timeline");

    const args = ["-hide_banner", "-loglevel", "error", "-y"];
    const segments = [];
    let nextInputIndex = 0;
    for (let index = 0; index < scenes.length; index += 1) {
      const scene = scenes[index];
      let segment;
      if (["video", "app_capture"].includes(scene.type)) {
        args.push("-ss", String(scene.start ?? 0), "-t", String(scene.duration), "-i", scene.videoPath);
        const videoInputIndex = nextInputIndex;
        nextInputIndex += 1;
        args.push("-loop", "1", "-t", String(scene.duration), "-i", join(directory, `overlay-${index}.png`));
        const overlayInputIndex = nextInputIndex;
        nextInputIndex += 1;
        segment = { ...scene, type: scene.type, inputIndex: videoInputIndex, overlayInputIndex };
      } else {
        args.push("-loop", "1", "-t", String(scene.duration), "-i", join(directory, `scene-${index}.png`));
        const inputIndex = nextInputIndex;
        nextInputIndex += 1;
        if (scene.directProduct) {
          let overlayInputIndex = null;
          if (scene.showOverlay) {
            args.push("-loop", "1", "-t", String(scene.duration), "-i", join(directory, `product-overlay-${index}.png`));
            overlayInputIndex = nextInputIndex;
            nextInputIndex += 1;
          }
          segment = { ...scene, type: "product", inputIndex, overlayInputIndex };
        } else {
          segment = { ...scene, type: "image", inputIndex };
        }
      }
      if (scene.voicePath) {
        args.push("-i", scene.voicePath);
        segment.voiceInputIndex = nextInputIndex++;
      }
      segments.push(segment);
    }
    const audioInputIndex = nextInputIndex;
    if (voiceoverPath) args.push("-i", voiceoverPath);
    const filters = [];
    for (let index = 0; index < segments.length; index += 1) {
      const segment = segments[index];
      if (segment.type === "video") {
        const framingFilter = segment.reframe === "medium_close"
          ? "scale=1944:3456:force_original_aspect_ratio=increase,crop=1080:1920:(iw-ow)/2:220"
          : "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920";
        filters.push(`[${segment.inputIndex}:v]${framingFilter},fps=30,trim=duration=${segment.duration},setpts=PTS-STARTPTS,setsar=1[base${index}]`);
        filters.push(`[${segment.overlayInputIndex}:v]scale=1080:1920,format=rgba,trim=duration=${segment.duration},setpts=PTS-STARTPTS[overlay${index}]`);
        filters.push(`[base${index}][overlay${index}]overlay=0:0:format=auto[v${index}]`);
      } else if (["product", "app_capture"].includes(segment.type)) {
        // Preserve the whole real interface. Panning a screenshot cannot demonstrate an interaction.
        filters.push(`[${segment.inputIndex}:v]scale=900:1360:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:280:color=0x050605,fps=30,trim=duration=${segment.duration},setpts=PTS-STARTPTS,setsar=1[product${index}]`);
        if (segment.overlayInputIndex != null) {
          filters.push(`[${segment.overlayInputIndex}:v]scale=1080:1920,format=rgba,trim=duration=${segment.duration},setpts=PTS-STARTPTS[productOverlay${index}]`);
          filters.push(`[product${index}][productOverlay${index}]overlay=0:0:format=auto[v${index}]`);
        } else {
          filters.push(`[product${index}]null[v${index}]`);
        }
      } else {
        filters.push(`[${segment.inputIndex}:v]scale=1080:1920,fps=30,trim=duration=${segment.duration},setpts=PTS-STARTPTS,setsar=1[v${index}]`);
      }
      if (sceneAudio) {
        const audioIndex = segment.voiceInputIndex ?? (segment.hasAudio && ["native", "ambient"].includes(segment.audioStrategy) ? segment.inputIndex : null);
        if (audioIndex != null) {
          // Inputs already begin at the selected source cut; narration starts with its scene.
          filters.push(`[${audioIndex}:a]aresample=48000,aformat=channel_layouts=stereo,asetpts=PTS-STARTPTS,apad=whole_dur=${segment.duration},atrim=duration=${segment.duration}[a${index}]`);
        } else {
          filters.push(`anullsrc=r=48000:cl=stereo:d=${segment.duration}[a${index}]`);
        }
      }
    }
    if (sceneAudio) {
      filters.push(`${segments.map((_segment, index) => `[v${index}][a${index}]`).join("")}concat=n=${segments.length}:v=1:a=1[outv][ambient]`);
    } else {
      filters.push(`${segments.map((_segment, index) => `[v${index}]`).join("")}concat=n=${segments.length}:v=1:a=0[outv]`);
    }
    if (voiceoverPath) {
      filters.push(`[${audioInputIndex}:a]aresample=48000,aformat=channel_layouts=stereo,asetpts=PTS-STARTPTS,apad=whole_dur=${totalDuration},atrim=duration=${totalDuration}[aout]`);
    }
    args.push(
      "-filter_complex", filters.join(";"),
      "-map", "[outv]",
      ...(voiceoverPath
        ? ["-map", "[aout]", "-c:a", "aac", "-b:a", "160k"]
        : sceneAudio ? ["-map", "[ambient]", "-c:a", "aac", "-b:a", "160k"] : ["-an"]),
      "-c:v", "libx264", "-preset", "medium", "-crf", "19", "-pix_fmt", "yuv420p",
      "-movflags", "+faststart",
      "-t", String(totalDuration),
      output,
    );
    await execFileAsync(ffmpegExecutable, args, { maxBuffer: 4 * 1024 * 1024 });
    return await readFile(output);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}
