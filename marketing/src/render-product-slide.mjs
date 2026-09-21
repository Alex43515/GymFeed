import { readFile } from "node:fs/promises";
import sharp from "sharp";

const wordmarkUrl = new URL("../assets/brand/gymfeed-wordmark-white.png", import.meta.url);

const FEATURES = {
  connected_ecosystem: { label: "ONE CONNECTED FITNESS LIFE", items: ["HOME", "EXPLORE", "COACH", "FITCLIPS", "PROFILE", "COACH: TRAIN + EVENTS"] },
  starter_plan: { label: "PERSONALIZED START", items: ["4-WEEK WORKOUT PLAN", "28-DAY MEAL PLAN", "SETS · REPS · KG", "CALORIES · MACROS"] },
  home_feed: { label: "FITNESS SOCIAL", items: ["POSTS + FOOD POSTS", "FLEX REACTIONS", "COMMENTS + SAVES", "STORIES + SHARING"] },
  fitclips: { label: "WORKOUT VIDEO", items: ["VERTICAL FITCLIPS", "SOCIAL ACTIONS", "PLAYBACK CONTROLS", "TRAINING DISCOVERY"] },
  ai_coach: { label: "CONTEXT-AWARE AI COACH", items: ["YOUR GOALS", "DATED TRAIN PLAN", "RECENT WORKOUTS", "MEALS + PROGRESS"] },
  train: { label: "PLAN + COMPLETE", items: ["DATED CALENDAR", "SETS · REPS · KG", "REST TIMER", "WORKOUT HISTORY"] },
  scan_food: { label: "PHOTO / ESTIMATE / DIARY", items: ["MEAL PHOTO", "CALORIES", "PROTEIN · CARBS · FAT", "REVIEW BEFORE LOGGING"] },
  scan_equipment: { label: "AI-ASSISTED EQUIPMENT SCAN", items: ["LIKELY MACHINE", "TARGET MUSCLES", "SAFE-USE STEPS", "FOLLOW GYM INSTRUCTIONS"] },
  nutrition_diary: { label: "NUTRITION DIARY", items: ["CALORIE TARGET", "MACRO PROGRESS", "SCANNED MEALS", "PLANNED MEALS"] },
  body_scan: { label: "PROGRESS ESTIMATES", items: ["WEIGHT", "ESTIMATED BODY FAT", "BMI", "MONTHLY VIEW"] },
  progress: { label: "MY PROGRESS + PLANS", items: ["PROGRESS PHOTOS", "WEIGHT + BODY FAT", "WORKOUT PLAN", "MEAL PLAN"] },
  events: { label: "TRAIN TOGETHER", items: ["DISCOVER", "JOIN", "CREATE", "MAP LOCATION"] },
  messages: { label: "FITNESS MESSAGING", items: ["TEXT + MEDIA", "SHARED POSTS", "SHARED ROUTINES", "REAL-TIME UPDATES"] },
};

function escapeXml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&apos;");
}

function wrapText(value, maxChars, maxLines = 4) {
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
  return lines.slice(0, maxLines);
}

function textLines(lines, { x, y, step, className }) {
  return lines.map((line, index) => `<text class="${className}" x="${x}" y="${y + index * step}">${escapeXml(line)}</text>`).join("");
}

function featureDiagram(feature, { x, y, width, height }) {
  const config = FEATURES[feature] ?? FEATURES.connected_ecosystem;
  const gap = 18;
  const columns = 2;
  const itemWidth = (width - 96 - gap) / columns;
  const itemHeight = 84;
  return `
    <rect x="${x}" y="${y}" width="${width}" height="${height}" rx="42" fill="#111613" stroke="#2c3630" stroke-width="3"/>
    <text class="diagramLabel" x="${x + 48}" y="${y + 66}">${escapeXml(config.label)}</text>
    <circle cx="${x + width - 66}" cy="${y + 54}" r="18" fill="#0bea70"/>
    ${config.items.slice(0, 6).map((item, index) => {
      const row = Math.floor(index / columns);
      const column = index % columns;
      const itemX = x + 48 + column * (itemWidth + gap);
      const itemY = y + 112 + row * (itemHeight + gap);
      return `<rect x="${itemX}" y="${itemY}" width="${itemWidth}" height="${itemHeight}" rx="25" fill="#1b231e" stroke="#344239" stroke-width="2"/>
        <circle cx="${itemX + 34}" cy="${itemY + itemHeight / 2}" r="10" fill="#0bea70"/>
        <text class="diagramItem" x="${itemX + 58}" y="${itemY + itemHeight / 2 + 7}">${escapeXml(item)}</text>`;
    }).join("")}
  `;
}

async function roundedScreenshot(input, width, height) {
  const mask = Buffer.from(`<svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg"><rect width="${width}" height="${height}" rx="42" fill="white"/></svg>`);
  return sharp(input)
    .resize(width, height, { fit: "cover", position: "top" })
    .composite([{ input: mask, blend: "dest-in" }])
    .png()
    .toBuffer();
}

export async function renderProductSlide({
  width = 1080,
  height = 1350,
  headline,
  body,
  feature = "connected_ecosystem",
  cta = "Get started with GymFeed",
  index = 0,
  total = 5,
  screenshotUrl = null,
  backgroundBuffer = null,
}) {
  const isVideo = height / width > 1.55;
  const hasScreenshot = Boolean(screenshotUrl);
  const headlineLines = wrapText(headline, isVideo ? 22 : hasScreenshot ? 18 : 24, 4);
  const bodyLines = wrapText(body, isVideo ? 38 : hasScreenshot ? 27 : 46, 5);
  const featureConfig = FEATURES[feature] ?? FEATURES.connected_ecosystem;
  const headlineY = isVideo ? 330 : 300;
  const headlineStep = isVideo ? 94 : 86;
  const bodyY = headlineY + headlineLines.length * headlineStep + 48;
  const diagramY = isVideo ? 860 : 690;
  const diagramHeight = isVideo ? 570 : 410;
  const footerY = height - 72;
  const finalScreenshotUrl = hasScreenshot && index === total - 1;
  const urlX = finalScreenshotUrl ? 70 : width - 70;
  const urlY = finalScreenshotUrl ? height - 180 : footerY - 31;
  const urlAnchor = finalScreenshotUrl ? "start" : "end";
  const copyAlreadyContainsUrl = [headline, body, cta].some((value) => /gymfeed\.io/i.test(String(value ?? "")));
  const showUrl = (!hasScreenshot || index === total - 1) && !copyAlreadyContainsUrl;
  const phoneWidth = isVideo ? 430 : 350;
  const phoneHeight = Math.round(phoneWidth * 2.2222);
  const phoneX = isVideo ? Math.round((width - phoneWidth) / 2) : width - phoneWidth - 48;
  const phoneY = isVideo ? 760 : 440;
  const svg = `<svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <radialGradient id="glow"><stop stop-color="#0bea70" stop-opacity="0.23"/><stop offset="1" stop-color="#0bea70" stop-opacity="0"/></radialGradient>
      <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#050605"/><stop offset="1" stop-color="#0b100d"/></linearGradient>
      <style>
        text { font-family: Poppins, sans-serif; }
        .count { font-size: 30px; font-weight: 600; fill: #aab4ad; }
        .kicker { font-size: 25px; font-weight: 700; fill: #0bea70; letter-spacing: 2px; }
        .headline { font-size: ${isVideo ? 78 : 72}px; font-weight: 700; fill: #fff; }
        .body { font-size: ${isVideo ? 36 : 31}px; font-weight: 400; fill: #c8d0cb; }
        .diagramLabel { font-size: 24px; font-weight: 700; fill: #0bea70; letter-spacing: 1.4px; }
        .diagramItem { font-size: ${isVideo ? 22 : 19}px; font-weight: 600; fill: #f3f6f4; }
        .cta { font-size: 25px; font-weight: 700; fill: #041008; }
        .url { font-size: 25px; font-weight: 600; fill: #fff; }
      </style>
    </defs>
    <rect width="${width}" height="${height}" fill="url(#bg)" opacity="${backgroundBuffer ? 0.84 : 1}"/>
    <circle cx="${width - 70}" cy="90" r="390" fill="url(#glow)"/>
    <circle cx="70" cy="${height - 60}" r="310" fill="url(#glow)" opacity=".45"/>
    <rect x="64" y="58" width="292" height="70" rx="24" fill="#0d120f" stroke="#2b342e" stroke-width="2"/>
    <text class="count" x="${width - 72}" y="102" text-anchor="end">${index + 1}/${total}</text>
    <text class="kicker" x="72" y="${isVideo ? 224 : 204}">${escapeXml(featureConfig.label)}</text>
    ${textLines(headlineLines, { x: 70, y: headlineY, step: headlineStep, className: "headline" })}
    ${textLines(bodyLines, { x: 74, y: bodyY, step: isVideo ? 52 : 46, className: "body" })}
    ${hasScreenshot ? `<rect x="${phoneX - 14}" y="${phoneY - 14}" width="${phoneWidth + 28}" height="${phoneHeight + 28}" rx="54" fill="#111" stroke="#0bea70" stroke-width="4"/>` : featureDiagram(feature, { x: 70, y: diagramY, width: width - 140, height: diagramHeight })}
    <rect x="70" y="${height - 148}" width="${isVideo ? 430 : 390}" height="68" rx="34" fill="#0bea70"/>
    <text class="cta" x="${isVideo ? 285 : 265}" y="${height - 104}" text-anchor="middle">${escapeXml(cta)}</text>
    ${showUrl ? `<text class="url" x="${urlX}" y="${urlY}" text-anchor="${urlAnchor}">gymfeed.io</text>` : ""}
    <rect x="70" y="${footerY}" width="190" height="7" rx="3.5" fill="#0bea70"/>
  </svg>`;

  const composites = [];
  const wordmark = await sharp(await readFile(wordmarkUrl)).resize({ width: 248 }).png().toBuffer();
  composites.push({ input: wordmark, left: 82, top: 70 });
  if (hasScreenshot) {
    const screenshot = await roundedScreenshot(await readFile(screenshotUrl), phoneWidth, phoneHeight);
    composites.push({ input: screenshot, left: phoneX, top: phoneY });
  }
  const base = backgroundBuffer
    ? sharp(backgroundBuffer).resize(width, height, { fit: "cover", position: "attention" }).modulate({ brightness: 0.7, saturation: 0.82 })
    : sharp(Buffer.from(svg));
  const layers = backgroundBuffer ? [{ input: Buffer.from(svg) }, ...composites] : composites;
  return base.composite(layers).png({ compressionLevel: 9 }).toBuffer();
}

export const productFeatureKeys = Object.freeze(Object.keys(FEATURES));
