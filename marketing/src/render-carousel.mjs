import sharp from "sharp";

function escapeXml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&apos;");
}

function wrapText(text, maxChars) {
  const words = String(text).trim().split(/\s+/).filter(Boolean);
  const lines = [];
  let line = "";
  for (const word of words) {
    const candidate = line ? `${line} ${word}` : word;
    if (candidate.length > maxChars && line) {
      lines.push(line);
      line = word;
    } else {
      line = candidate;
    }
  }
  if (line) lines.push(line);
  return lines;
}

export async function renderCarouselSlide({ background, headline, body, index, total }) {
  const headlineLines = wrapText(headline, 22).slice(0, 4);
  const bodyLines = wrapText(body, 44).slice(0, 6);
  const headlineStart = 690 - Math.max(0, headlineLines.length - 2) * 45;
  const bodyStart = headlineStart + headlineLines.length * 92 + 32;
  const svg = `
    <svg width="1080" height="1350" viewBox="0 0 1080 1350" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="shade" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="#000" stop-opacity="0.05"/>
          <stop offset="0.44" stop-color="#000" stop-opacity="0.18"/>
          <stop offset="1" stop-color="#000" stop-opacity="0.94"/>
        </linearGradient>
        <style>
          .brand { font-family: Poppins; font-size: 34px; font-weight: 700; fill: #fff; letter-spacing: 1px; }
          .headline { font-family: Poppins; font-size: 76px; font-weight: 700; fill: #fff; }
          .body { font-family: Poppins; font-size: 34px; font-weight: 400; fill: #f2f2f2; }
          .count { font-family: Poppins; font-size: 28px; font-weight: 600; fill: #fff; }
        </style>
      </defs>
      <rect width="1080" height="1350" fill="url(#shade)"/>
      <rect x="70" y="70" width="250" height="62" rx="31" fill="#000" fill-opacity="0.56"/>
      <circle cx="108" cy="101" r="15" fill="#e5ff3f"/>
      <text class="brand" x="138" y="114">GYMFEED</text>
      <text class="count" x="930" y="112" text-anchor="end">${index + 1}/${total}</text>
      ${headlineLines.map((line, i) => `<text class="headline" x="72" y="${headlineStart + i * 92}">${escapeXml(line)}</text>`).join("")}
      ${bodyLines.map((line, i) => `<text class="body" x="74" y="${bodyStart + i * 53}">${escapeXml(line)}</text>`).join("")}
      <rect x="72" y="1270" width="180" height="7" rx="3.5" fill="#e5ff3f"/>
    </svg>`;

  return sharp(background)
    .resize(1080, 1350, { fit: "cover", position: "attention" })
    .composite([{ input: Buffer.from(svg) }])
    .png({ compressionLevel: 9 })
    .toBuffer();
}
