import { mkdir, readdir } from 'node:fs/promises';
import path from 'node:path';
import sharp from 'sharp';

const imageExtensions = new Set(['.png', '.jpg', '.jpeg', '.webp']);

function escapeXml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
}

async function collectImages(root) {
  const entries = await readdir(root, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    const absolute = path.join(root, entry.name);
    if (entry.isDirectory()) files.push(...await collectImages(absolute));
    if (entry.isFile() && imageExtensions.has(path.extname(entry.name).toLowerCase())) {
      files.push(absolute);
    }
  }

  return files.sort((left, right) => left.localeCompare(right, undefined, { numeric: true }));
}

async function makeTile(file, root, width, height) {
  const labelHeight = 58;
  const inset = 8;
  const image = await sharp(file)
    .rotate()
    .resize({ width: width - inset * 2, height: height - labelHeight - inset * 2, fit: 'contain', background: '#111512' })
    .png()
    .toBuffer();
  const metadata = await sharp(image).metadata();
  const relative = path.relative(root, file).replaceAll('\\', '/');
  const label = relative.length > 34 ? `…${relative.slice(-33)}` : relative;
  const background = Buffer.from(`
    <svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg">
      <rect width="100%" height="100%" rx="16" fill="#0a0d0b"/>
      <rect x="1" y="1" width="${width - 2}" height="${height - 2}" rx="15" fill="none" stroke="#243329" stroke-width="2"/>
      <rect y="${height - labelHeight}" width="100%" height="${labelHeight}" fill="#101713"/>
      <text x="12" y="${height - 23}" fill="#f2f5f2" font-family="Arial, sans-serif" font-size="16" font-weight="700">${escapeXml(label)}</text>
    </svg>`);

  return sharp(background)
    .composite([{ input: image, left: Math.round((width - metadata.width) / 2), top: inset }])
    .png()
    .toBuffer();
}

async function makeSheets(source, outputRoot) {
  const files = await collectImages(source);
  const columns = 5;
  const rows = 4;
  const tileWidth = 250;
  const tileHeight = 470;
  const perSheet = columns * rows;
  const slugSource = `${path.basename(path.dirname(source))}-${path.basename(source)}`;
  const slug = slugSource.replaceAll(/[^a-z0-9]+/gi, '-').replaceAll(/^-|-$/g, '').toLowerCase() || 'images';
  const outputs = [];

  for (let start = 0; start < files.length; start += perSheet) {
    const batch = files.slice(start, start + perSheet);
    const tiles = await Promise.all(batch.map((file) => makeTile(file, source, tileWidth, tileHeight)));
    const canvas = sharp({
      create: {
        width: columns * tileWidth,
        height: rows * tileHeight,
        channels: 4,
        background: '#050706',
      },
    });
    const output = path.join(outputRoot, `${slug}-${String(start / perSheet + 1).padStart(2, '0')}.png`);
    await canvas.composite(tiles.map((input, index) => ({
      input,
      left: (index % columns) * tileWidth,
      top: Math.floor(index / columns) * tileHeight,
    }))).png().toFile(output);
    outputs.push(output);
  }

  return { source, images: files.length, outputs };
}

const sources = process.argv.slice(2);
if (sources.length === 0) throw new Error('Pass one or more source directories.');

const outputRoot = path.resolve('artifacts/source-catalog');
await mkdir(outputRoot, { recursive: true });

for (const source of sources) {
  const result = await makeSheets(path.resolve(source), outputRoot);
  console.log(JSON.stringify(result));
}
