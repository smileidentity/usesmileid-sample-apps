#!/usr/bin/env node
// Composes one wordless store panel: storeshots' own background, gradient and device frame, no headline.
//   node scripts/compose-store-panel.mjs --preset ios-phone --bg "#151F72" --screenshot f.png --output p.png
// It reuses the package npx resolves, so the frame matches the tool that still validates the output.

import { execFileSync } from "node:child_process";
import { mkdirSync, realpathSync } from "node:fs";
import { createRequire } from "node:module";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { parseArgs } from "node:util";

const { values } = parseArgs({
  options: {
    preset: { type: "string" },
    bg: { type: "string" },
    screenshot: { type: "string" },
    output: { type: "string" },
    storeshots: { type: "string" }, // package root; resolved through npx when omitted
  },
});
for (const key of ["preset", "bg", "screenshot", "output"]) {
  if (!values[key]) {
    console.error(`missing --${key}`);
    process.exit(2);
  }
}

const pkg = values.storeshots ?? storeshotsPackageRoot();
const load = (rel) => import(pathToFileURL(path.join(pkg, rel)).href);
const { getPreset } = await load("dist/presets.js");
const { normalizeHex } = await load("dist/util.js");
const { renderDevice } = await load("dist/render/frame.js");
const sharpPath = createRequire(path.join(pkg, "package.json")).resolve("sharp");
const sharp = (await import(pathToFileURL(sharpPath).href)).default;

const preset = getPreset(values.preset);
const bg = normalizeHex(values.bg);

// storeshots sizes the device for a headline and shapes its screen like the canvas; a wordless panel wants neither.
const shot = await sharp(values.screenshot).metadata();
if (!shot.width || !shot.height) {
  console.error(`cannot read the dimensions of ${values.screenshot}`);
  process.exit(2);
}
const screenAspect = shot.height / shot.width;
const margin = Math.round(preset.height * 0.03);
const heightPerWidth = (1 - 2 * preset.device.bezelRatio) * screenAspect + 2 * preset.device.bezelRatio;
const fitRatio = Math.min(0.9, (preset.height - 2 * margin) / heightPerWidth / preset.width);
let { buffer, width: deviceW, height: deviceH } = await renderDevice(
  { ...preset, screenAspect, deviceWidthRatio: fitRatio },
  values.screenshot,
);

// Centred whole; an overhang on either axis centres to a negative offset and sharp throws.
const scale = Math.min(1, (preset.height - 2 * margin) / deviceH, (preset.width - 2 * margin) / deviceW);
if (scale < 1) {
  deviceW = Math.round(deviceW * scale);
  deviceH = Math.round(deviceH * scale);
  buffer = await sharp(buffer).resize(deviceW, deviceH).png().toBuffer();
}
const deviceLeft = Math.round((preset.width - deviceW) / 2);
const deviceTop = Math.round((preset.height - deviceH) / 2);

// storeshots' own gradient, so a wordless panel sits beside a captioned one without a seam.
const gradient = `<svg width="${preset.width}" height="${preset.height}" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#000000" stop-opacity="0"/>
      <stop offset="1" stop-color="#000000" stop-opacity="0.22"/>
    </linearGradient>
  </defs>
  <rect width="${preset.width}" height="${preset.height}" fill="url(#g)"/>
</svg>`;

mkdirSync(path.dirname(path.resolve(values.output)), { recursive: true });
const composed = await sharp({
  create: { width: preset.width, height: preset.height, channels: 4, background: bg },
})
  .composite([
    { input: Buffer.from(gradient), left: 0, top: 0 },
    { input: buffer, left: deviceLeft, top: deviceTop },
  ])
  .png()
  .toBuffer();
// Stores reject an alpha channel, and sharp applies composite last, so flattening is a second pass.
await sharp(composed).removeAlpha().png().toFile(values.output);
console.log(`${values.output}  ${preset.width}x${preset.height}  ${preset.id}`);

function storeshotsPackageRoot() {
  const bin = execFileSync("npx", ["--yes", "-p", "storeshots-mcp", "-c", "command -v storeshots"], {
    encoding: "utf8",
  })
    .trim()
    .split("\n")
    .pop();
  return path.resolve(path.dirname(realpathSync(bin)), "..");
}
