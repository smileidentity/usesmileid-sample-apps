#!/usr/bin/env node
// Composes one store panel with no headline: storeshots' brand background, gradient and device frame
// around the screenshot, nothing else. storeshots refuses an empty headline, so this reuses its own
// renderer for the parts that stay; the panel still goes through `storeshots validate` afterwards.
//
//   node scripts/compose-store-panel.mjs --preset ios-phone --bg "#151F72" --screenshot frame.png --output panel.png
//
// The package is the one `npx -p storeshots-mcp` resolves, so the composer and the validator are one version.
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
let { buffer, width: deviceW, height: deviceH } = await renderDevice(preset, values.screenshot);

// The whole device, centred: with no headline to sit under, there is nothing for it to bleed away from.
const margin = Math.round(preset.height * 0.03);
if (deviceH > preset.height - 2 * margin) {
  const fitH = preset.height - 2 * margin;
  const fitW = Math.round(deviceW * (fitH / deviceH));
  buffer = await sharp(buffer).resize(fitW, fitH).png().toBuffer();
  deviceW = fitW;
  deviceH = fitH;
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
