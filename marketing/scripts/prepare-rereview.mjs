import { randomUUID } from "node:crypto";
import sharp from "sharp";
import { loadConfig } from "../src/config.mjs";
import { MarketingRepository } from "../src/repository.mjs";
import { extractVideoContactSheet } from "../src/extract-video-frame.mjs";
import { renderCarouselSlide } from "../src/render-carousel.mjs";

const VIDEO_KEY = "GF-20260828-V001";
const CAROUSEL_KEY = "GF-20260828-I001";
const config = loadConfig(process.env);
const repository = new MarketingRepository(config);

async function instructionBackground(kind) {
  const calendar = `
    <rect x="90" y="180" width="900" height="480" rx="42" fill="#171d29" stroke="#75809a" stroke-width="5"/>
    <rect x="90" y="180" width="900" height="105" rx="42" fill="#252d3d"/>
    <circle cx="175" cy="232" r="14" fill="#e5ff3f"/><circle cx="225" cy="232" r="14" fill="#e5ff3f"/>
    ${Array.from({ length: 7 }, (_, i) => `<rect x="${125 + i * 123}" y="325" width="90" height="270" rx="18" fill="${[1, 4].includes(i) ? "#e5ff3f" : "#30394a"}" opacity="${[1, 4].includes(i) ? "0.96" : "0.78"}"/>`).join("")}
  `;
  const checklist = `
    <rect x="185" y="140" width="710" height="560" rx="46" fill="#171d29" stroke="#75809a" stroke-width="5"/>
    <rect x="380" y="110" width="320" height="80" rx="30" fill="#30394a"/>
    ${[280, 410, 540].map((y) => `<circle cx="285" cy="${y}" r="40" fill="#e5ff3f"/><path d="M265 ${y} l16 17 l30 -38" fill="none" stroke="#111722" stroke-width="15" stroke-linecap="round" stroke-linejoin="round"/><rect x="360" y="${y - 22}" width="430" height="44" rx="22" fill="#3a4559"/>`).join("")}
  `;
  const svg = `<svg width="1080" height="1350" xmlns="http://www.w3.org/2000/svg">
    <defs><linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#101722"/><stop offset="1" stop-color="#273555"/></linearGradient></defs>
    <rect width="1080" height="1350" fill="url(#bg)"/>
    <circle cx="965" cy="120" r="260" fill="#6b5cff" opacity="0.18"/>
    ${kind === "calendar" ? calendar : checklist}
  </svg>`;
  return sharp(Buffer.from(svg)).png().toBuffer();
}

const videoResult = await repository.client.from("marketing_content").select("*").eq("content_key", VIDEO_KEY).single();
if (videoResult.error) throw new Error(`Load video: ${videoResult.error.message}`);
const video = videoResult.data;
const videoResponse = await fetch(video.asset_urls[0]);
if (!videoResponse.ok) throw new Error(`Download video: ${videoResponse.status}`);
const duration = video.decision.content.scenes[0].duration_seconds;
const contactSheet = await extractVideoContactSheet(Buffer.from(await videoResponse.arrayBuffer()), duration);
const contactSheetUrl = await repository.uploadAsset(
  `${VIDEO_KEY}/${video.provider_task_id}/contact-sheet-${randomUUID()}.jpg`,
  contactSheet,
  "image/jpeg",
);
await repository.updateContent(video.id, {
  status: "generated",
  thumbnail_url: contactSheetUrl,
  qa: {},
  qa_score: null,
  failure_reason: null,
  approved_at: null,
  scheduled_at: null,
});

const carouselResult = await repository.client.from("marketing_content").select("*").eq("content_key", CAROUSEL_KEY).single();
if (carouselResult.error) throw new Error(`Load carousel: ${carouselResult.error.message}`);
const carousel = carouselResult.data;
const carouselContent = carousel.decision.content;
const carouselVersion = randomUUID();
const revisedAssets = [...carousel.asset_urls];
for (const [index, kind] of [[1, "calendar"], [3, "checklist"]]) {
  const slide = carouselContent.slides[index];
  const rendered = await renderCarouselSlide({
    background: await instructionBackground(kind),
    headline: slide.headline,
    body: slide.body,
    index,
    total: carouselContent.slides.length,
  });
  revisedAssets[index] = await repository.uploadAsset(
    `${CAROUSEL_KEY}/${carouselVersion}/slide-${index + 1}.png`,
    rendered,
    "image/png",
  );
}
await repository.updateContent(carousel.id, {
  status: "generated",
  asset_urls: revisedAssets,
  qa: {},
  qa_score: null,
  failure_reason: null,
  approved_at: null,
  scheduled_at: null,
});

console.log(JSON.stringify({ video: "ready_for_qa", carousel: "ready_for_qa", contactSheetUrl }, null, 2));
