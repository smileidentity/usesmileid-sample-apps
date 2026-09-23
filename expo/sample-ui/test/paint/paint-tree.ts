import { readdirSync } from 'node:fs';
import { join } from 'node:path';

import { createCanvas, GlobalFonts, type Canvas, type SKRSContext2D } from '@napi-rs/canvas';

import { flatten, PAINT_PROPS, type LaidOutNode, type LaidOutSpan, type Style } from '../layout/layout-tree';
import { hasGlyph, measureRun } from '../layout/smile-font';
import { paintSvg } from './paint-svg';

/// 2×, so a 393-wide frame is 786 pixels, as on Android.
export const PIXEL_RATIO = 2;

/// Hosts the painter cannot draw, each drawn as a labelled box.
export const PLACEHOLDERS: Readonly<Record<string, (props: Record<string, unknown>) => string>> = {
  RCTSwitch: (props) =>
    `${props.value === true ? 'on' : 'off'}${props.disabled === true ? ' · disabled' : ''}`,
  ActivityIndicator: () => 'Spinner',
  Image: () => 'Image',
  // The sheet's corner radius and scrim are not drawn at all.
  SheetDragIndicator: () => '',
  // Emoji: the bundled face lacks them and a host emoji font differs per runner.
  MissingGlyph: () => '',
};

/// Hosts that draw nothing in any recorded state.
const DRAWS_NOTHING: ReadonlySet<string> = new Set([
  'RCTRefreshControl',
]);

/// Hosts that draw their own box, then their children.
const PLAIN_HOSTS: ReadonlySet<string> = new Set(['View', 'RCTScrollView', 'RNCSafeAreaProvider']);

/// Style props the painter draws; a paint prop in neither this set nor INERT fails.
const PAINTED = new Set([
  'backgroundColor', 'color', 'opacity', 'transform', 'zIndex', 'borderRadius', 'borderTopLeftRadius',
  'borderTopRightRadius', 'borderBottomLeftRadius', 'borderBottomRightRadius', 'borderColor',
  'borderTopColor', 'borderRightColor', 'borderBottomColor', 'borderLeftColor', 'borderStyle',
  'shadowColor', 'shadowOffset', 'shadowOpacity', 'shadowRadius', 'fontFamily', 'fontSize',
  'letterSpacing', 'lineHeight', 'textAlign', 'textDecorationLine', 'textDecorationColor', 'textTransform', 'fontStyle',
]);

/// Paint props that change nothing in the picture.
const INERT = new Set([
  // Android-only; the jest renderer is iOS.
  'elevation',
  // Each DM Sans weight is its own family.
  'fontWeight',
  // Drawn as circular corners.
  'borderCurve',
  'includeFontPadding', 'textAlignVertical', 'pointerEvents', 'cursor', 'userSelect',
  'backfaceVisibility', 'writingDirection', 'verticalAlign', 'isolation',
]);

const FONT_DIR = join(__dirname, '..', '..', 'assets', 'fonts');

let fontsRegistered = false;

/// Registers each bundled face under its file name, the family styles use.
const registerFonts = (): void => {
  if (fontsRegistered) return;
  for (const file of readdirSync(FONT_DIR).filter((name) => name.endsWith('.ttf'))) {
    const family = file.slice(0, -'.ttf'.length);
    if (!GlobalFonts.registerFromPath(join(FONT_DIR, file), family)) {
      throw new Error(`could not register the bundled face ${file}`);
    }
  }
  fontsRegistered = true;
};

/// Fails, naming the node the painter could not draw.
const fail = (where: string, message: string): never => {
  throw new Error(`${where}: ${message}`);
};

/// Four corner radii, clockwise from the top left.
type Radii = { tl: number; tr: number; br: number; bl: number };

/// Corner radii scaled down together until they fit, as React Native does.
const radiiOf = (style: Style, width: number, height: number): Radii => {
  const all = (style.borderRadius as number | undefined) ?? 0;
  const r = {
    tl: (style.borderTopLeftRadius as number | undefined) ?? all,
    tr: (style.borderTopRightRadius as number | undefined) ?? all,
    br: (style.borderBottomRightRadius as number | undefined) ?? all,
    bl: (style.borderBottomLeftRadius as number | undefined) ?? all,
  };
  const fit = Math.min(
    1,
    width / Math.max(r.tl + r.tr, 1e-9),
    width / Math.max(r.bl + r.br, 1e-9),
    height / Math.max(r.tl + r.bl, 1e-9),
    height / Math.max(r.tr + r.br, 1e-9),
  );
  return { tl: r.tl * fit, tr: r.tr * fit, br: r.br * fit, bl: r.bl * fit };
};

/// Traces a rectangle with per-corner radii.
const roundedRect = (
  ctx: SKRSContext2D,
  x: number,
  y: number,
  width: number,
  height: number,
  r: Radii,
): void => {
  ctx.moveTo(x + r.tl, y);
  ctx.lineTo(x + width - r.tr, y);
  ctx.ellipse(x + width - r.tr, y + r.tr, r.tr, r.tr, 0, -Math.PI / 2, 0);
  ctx.lineTo(x + width, y + height - r.br);
  ctx.ellipse(x + width - r.br, y + height - r.br, r.br, r.br, 0, 0, Math.PI / 2);
  ctx.lineTo(x + r.bl, y + height);
  ctx.ellipse(x + r.bl, y + height - r.bl, r.bl, r.bl, 0, Math.PI / 2, Math.PI);
  ctx.lineTo(x, y + r.tl);
  ctx.ellipse(x + r.tl, y + r.tl, r.tl, r.tl, 0, Math.PI, (3 * Math.PI) / 2);
  ctx.closePath();
};

/// Whether any corner is rounded.
const hasRadius = (r: Radii): boolean => r.tl > 0 || r.tr > 0 || r.br > 0 || r.bl > 0;

/// Starts a new path around a box's outer edge.
const outline = (ctx: SKRSContext2D, x: number, y: number, width: number, height: number, r: Radii) => {
  ctx.beginPath();
  if (hasRadius(r)) roundedRect(ctx, x, y, width, height, r);
  else ctx.rect(x, y, width, height);
};

/// Fails on a paint style the painter would otherwise drop.
const checkStyle = (style: Style, where: string): void => {
  for (const [name, value] of Object.entries(style)) {
    if (value === undefined || value === null) continue;
    if (!PAINT_PROPS.has(name) || PAINTED.has(name) || INERT.has(name)) continue;
    fail(where, `the style property "${name}" paints, and this painter does not draw it`);
  }
  if (style.borderStyle !== undefined && style.borderStyle !== 'solid') {
    fail(where, `a ${String(style.borderStyle)} border is not one this painter draws`);
  }
  if (style.textTransform !== undefined && style.textTransform !== 'none') {
    fail(where, 'textTransform changes the glyphs the layout pass measured, so it cannot be drawn faithfully');
  }
  if (style.fontStyle !== undefined && style.fontStyle !== 'normal') {
    fail(where, 'no italic face is bundled');
  }
};

/// Applies a React Native transform list about the box's centre.
const applyTransform = (ctx: SKRSContext2D, style: Style, x: number, y: number, node: LaidOutNode, where: string) => {
  const transforms = (style.transform ?? []) as unknown as Record<string, unknown>[];
  if (!Array.isArray(transforms)) fail(where, 'a string transform is not one this painter reads');
  if (transforms.length === 0) return;
  const cx = x + node.width / 2;
  const cy = y + node.height / 2;
  ctx.translate(cx, cy);
  for (const step of transforms) {
    const [name, value] = Object.entries(step)[0] ?? [];
    if (name === 'translateX') ctx.translate(value as number, 0);
    else if (name === 'translateY') ctx.translate(0, value as number);
    else if (name === 'scale') ctx.scale(value as number, value as number);
    else if (name === 'scaleX') ctx.scale(value as number, 1);
    else if (name === 'scaleY') ctx.scale(1, value as number);
    else if (name === 'rotate' && typeof value === 'string' && value.endsWith('deg')) {
      ctx.rotate((Number.parseFloat(value) * Math.PI) / 180);
    } else fail(where, `the transform "${String(name)}" is not one this painter draws`);
  }
  ctx.translate(-cx, -cy);
};

/// One edge of a box.
type Side = 'top' | 'right' | 'bottom' | 'left';

/// A side's own border colour, falling back to the box's.
const sideColour = (style: Style, side: Side): string | undefined => {
  const key = `border${side.charAt(0).toUpperCase()}${side.slice(1)}Color`;
  return (style[key] as string | undefined) ?? (style.borderColor as string | undefined);
};

/// Paints each border side as its own mitred band.
const paintBorders = (ctx: SKRSContext2D, node: LaidOutNode, style: Style, x: number, y: number, r: Radii) => {
  const b = node.border;
  const { width, height } = node;
  const inner: Radii = {
    tl: Math.max(r.tl - Math.max(b.left, b.top), 0),
    tr: Math.max(r.tr - Math.max(b.right, b.top), 0),
    br: Math.max(r.br - Math.max(b.right, b.bottom), 0),
    bl: Math.max(r.bl - Math.max(b.left, b.bottom), 0),
  };
  const corners = {
    outer: [
      [x, y], [x + width, y], [x + width, y + height], [x, y + height],
    ],
    inner: [
      [x + b.left, y + b.top], [x + width - b.right, y + b.top],
      [x + width - b.right, y + height - b.bottom], [x + b.left, y + height - b.bottom],
    ],
  };
  const sides: [Side, number, number][] = [['top', 0, 1], ['right', 1, 2], ['bottom', 2, 3], ['left', 3, 0]];
  const sameEverywhere =
    b.top === b.right && b.top === b.bottom && b.top === b.left &&
    sides.every(([side]) => sideColour(style, side) === sideColour(style, 'top'));
  const band = () => {
    ctx.beginPath();
    if (hasRadius(r)) roundedRect(ctx, x, y, width, height, r);
    else ctx.rect(x, y, width, height);
    const iw = width - b.left - b.right;
    const ih = height - b.top - b.bottom;
    if (iw > 0 && ih > 0) {
      if (hasRadius(inner)) roundedRect(ctx, x + b.left, y + b.top, iw, ih, inner);
      else ctx.rect(x + b.left, y + b.top, iw, ih);
    }
  };
  if (sameEverywhere) {
    const colour = sideColour(style, 'top');
    if (b.top <= 0 || colour === undefined) return;
    ctx.fillStyle = colour;
    band();
    ctx.fill('evenodd');
    return;
  }
  for (const [side, from, to] of sides) {
    const colour = sideColour(style, side);
    if (b[side] <= 0 || colour === undefined) continue;
    ctx.save();
    ctx.beginPath();
    const [ox1, oy1] = corners.outer[from]!;
    const [ox2, oy2] = corners.outer[to]!;
    const [ix2, iy2] = corners.inner[to]!;
    const [ix1, iy1] = corners.inner[from]!;
    ctx.moveTo(ox1!, oy1!);
    ctx.lineTo(ox2!, oy2!);
    ctx.lineTo(ix2!, iy2!);
    ctx.lineTo(ix1!, iy1!);
    ctx.closePath();
    ctx.clip();
    ctx.fillStyle = colour;
    band();
    ctx.fill('evenodd');
    ctx.restore();
  }
};

/// The iOS shadow a box with a background casts.
const paintShadow = (ctx: SKRSContext2D, style: Style, x: number, y: number, node: LaidOutNode, r: Radii) => {
  const opacity = (style.shadowOpacity as number | undefined) ?? 0;
  if (opacity <= 0 || style.shadowColor === undefined || style.backgroundColor === undefined) return;
  const offset = (style.shadowOffset as { width?: number; height?: number } | undefined) ?? {};
  ctx.save();
  // Canvas shadows are in device space, so the pixel ratio is applied by hand.
  ctx.shadowColor = style.shadowColor as string;
  ctx.shadowBlur = ((style.shadowRadius as number | undefined) ?? 3) * PIXEL_RATIO;
  ctx.shadowOffsetX = (offset.width ?? 0) * PIXEL_RATIO;
  ctx.shadowOffsetY = (offset.height ?? 0) * PIXEL_RATIO;
  ctx.globalAlpha *= opacity;
  ctx.fillStyle = style.backgroundColor as string;
  outline(ctx, x, y, node.width, node.height, r);
  ctx.fill();
  ctx.restore();
};

/// A face's ascent and descent at one size.
type FontMetrics = { ascent: number; descent: number };

/// Metrics per face and size.
const metricsCache = new Map<string, FontMetrics>();

/// The canvas font string for a face at a size.
const fontOf = (family: string, size: number): string => `${size}px "${family}"`;

/// The ascent and descent Skia reports for a face.
const metricsOf = (ctx: SKRSContext2D, family: string, size: number): FontMetrics => {
  const key = fontOf(family, size);
  const cached = metricsCache.get(key);
  if (cached) return cached;
  ctx.save();
  ctx.font = key;
  const measured = ctx.measureText('Hg');
  ctx.restore();
  const metrics = { ascent: measured.fontBoundingBoxAscent, descent: measured.fontBoundingBoxDescent };
  metricsCache.set(key, metrics);
  return metrics;
};

/// Splits [text] into runs the bundled face can and cannot draw.
const byCoverage = (text: string, family: string): { text: string; covered: boolean }[] => {
  const runs: { text: string; covered: boolean }[] = [];
  for (const character of text) {
    const covered = hasGlyph(family, character);
    const last = runs[runs.length - 1];
    if (last && last.covered === covered) last.text += character;
    else runs.push({ text: character, covered });
  }
  return runs;
};

/// Draws one styled run and returns its measured width.
const drawRun = (ctx: SKRSContext2D, text: string, span: LaidOutSpan, x: number, baseline: number): number => {
  const width = measureRun(text, span.run);
  if (text.trim().length === 0) return width;
  ctx.font = fontOf(span.run.fontFamily, span.run.fontSize);
  ctx.letterSpacing = `${span.run.letterSpacing ?? 0}px`;
  ctx.fillStyle = (span.style.color as string | undefined) ?? 'black';
  let cursor = x;
  for (const run of byCoverage(text, span.run.fontFamily)) {
    const advance = measureRun(run.text, span.run);
    if (run.covered) {
      ctx.fillText(run.text, cursor, baseline);
    } else {
      const { fontSize } = span.run;
      ctx.save();
      paintPlaceholder(ctx, PLACEHOLDERS.MissingGlyph!({}), cursor, baseline - fontSize * 0.8, advance, fontSize);
      ctx.restore();
    }
    cursor += advance;
  }
  const decoration = span.style.textDecorationLine as string | undefined;
  if (decoration !== undefined && decoration !== 'none') {
    const thickness = Math.max(span.run.fontSize / 14, 1);
    ctx.fillStyle = (span.style.textDecorationColor as string | undefined) ?? ctx.fillStyle;
    if (decoration.includes('underline')) ctx.fillRect(x, baseline + thickness * 1.5, width, thickness);
    if (decoration.includes('line-through')) {
      ctx.fillRect(x, baseline - span.run.fontSize * 0.3, width, thickness);
    }
  }
  return width;
};

/// React Native's tail-truncation mark.
const ELLIPSIS = '…';

/// Draws each laid-out line, centring the glyphs in the line box.
const paintText = (ctx: SKRSContext2D, node: LaidOutNode, style: Style, x: number, y: number, where: string) => {
  const spans = node.spans ?? fail(where, 'text reached the painter without its spans');
  const allLines = node.lines ?? [];
  const cap = node.numberOfLines;
  const lines = cap === undefined ? allLines : allLines.slice(0, cap);
  const truncated = cap !== undefined && allLines.length > cap;
  const lineHeight = Math.max(...spans.map((span) => span.run.lineHeight ?? span.run.fontSize * 1.2), 0);
  const tallest = spans.reduce((best, span) => (span.run.fontSize > best.run.fontSize ? span : best), spans[0]!);
  const metrics = metricsOf(ctx, tallest.run.fontFamily, tallest.run.fontSize);
  const left = x + node.padding.left + node.border.left;
  const top = y + node.padding.top + node.border.top;
  const width = node.width - node.padding.left - node.padding.right - node.border.left - node.border.right;
  const owner: number[] = [];
  spans.forEach((span, index) => {
    for (let at = 0; at < span.text.length; at++) owner.push(index);
  });
  const text = spans.map((span) => span.text).join('');
  const align = (style.textAlign as string | undefined) ?? 'auto';
  if (align === 'justify') fail(where, 'justified text is not laid out by the layout pass');
  lines.forEach((line, index) => {
    let end = line.end;
    let suffix = '';
    let lineWidth = line.width;
    if (truncated && index === lines.length - 1) {
      // Tail truncation cuts the whole remainder, not just the words that wrapped here.
      const newline = text.indexOf('\n', line.start);
      end = newline < 0 ? text.length : newline;
      const last = spans[owner[Math.max(end - 1, line.start)] ?? 0]!;
      suffix = ELLIPSIS;
      const room = width - measureRun(ELLIPSIS, last.run);
      end = longestFitting(text, owner, spans, line.start, end, room);
      while (end > line.start && text[end - 1]!.trim().length === 0) end--;
      lineWidth = measureText(text, owner, spans, line.start, end) + measureRun(ELLIPSIS, last.run);
    }
    const slack = width - lineWidth;
    let cursor = left + (align === 'center' ? slack / 2 : align === 'right' ? slack : 0);
    const baseline = top + index * lineHeight + (lineHeight - metrics.ascent - metrics.descent) / 2 + metrics.ascent;
    let from = line.start;
    while (from < end) {
      const span = owner[from]!;
      let to = from;
      while (to < end && owner[to] === span) to++;
      cursor += drawRun(ctx, text.slice(from, to), spans[span]!, cursor, baseline);
      from = to;
    }
    if (suffix) drawRun(ctx, suffix, spans[owner[Math.max(end - 1, line.start)] ?? 0]!, cursor, baseline);
  });
};

/// The largest end in [start, end] whose run fits [room], found by halving.
const longestFitting = (
  text: string,
  owner: readonly number[],
  spans: readonly LaidOutSpan[],
  start: number,
  end: number,
  room: number,
): number => {
  let low = start;
  let high = end;
  while (low < high) {
    const mid = Math.ceil((low + high) / 2);
    if (measureText(text, owner, spans, start, mid) <= room) low = mid;
    else high = mid - 1;
  }
  return low;
};

/// The measured width of [start, end) across spans.
const measureText = (
  text: string,
  owner: readonly number[],
  spans: readonly LaidOutSpan[],
  start: number,
  end: number,
): number => {
  let width = 0;
  let from = start;
  while (from < end) {
    const span = owner[from]!;
    let to = from;
    while (to < end && owner[to] === span) to++;
    width += measureRun(text.slice(from, to), spans[span]!.run);
    from = to;
  }
  return width;
};

/// Draws a single-line field's value, or its placeholder, centred in the box.
const paintTextInput = (ctx: SKRSContext2D, node: LaidOutNode, style: Style, x: number, y: number, where: string) => {
  const value = (node.props.value as string | undefined) ?? (node.props.defaultValue as string | undefined) ?? '';
  const showsPlaceholder = value.length === 0;
  const raw = showsPlaceholder ? ((node.props.placeholder as string | undefined) ?? '') : value;
  if (raw.length === 0) return;
  const shown = !showsPlaceholder && node.props.secureTextEntry === true ? '•'.repeat([...raw].length) : raw;
  const run = node.field ?? fail(where, 'a field reached the painter without its run');
  const span: LaidOutSpan = {
    text: shown,
    run,
    style: { ...style, color: showsPlaceholder ? (node.props.placeholderTextColor as string) : style.color },
  };
  const left = x + node.padding.left + node.border.left;
  const width = node.width - node.padding.left - node.padding.right - node.border.left - node.border.right;
  const metrics = metricsOf(ctx, run.fontFamily, run.fontSize);
  const baseline = y + (node.height - metrics.ascent - metrics.descent) / 2 + metrics.ascent;
  const slack = width - measureRun(shown, run);
  const align = (style.textAlign as string | undefined) ?? 'auto';
  ctx.save();
  ctx.beginPath();
  ctx.rect(left, y, Math.max(width, 0), node.height);
  ctx.clip();
  drawRun(ctx, shown, span, left + (align === 'center' ? slack / 2 : align === 'right' ? slack : 0), baseline);
  ctx.restore();
};

/// Every colour a stand-in is drawn in: harness ink, not the design's, so no token applies.
const PLACEHOLDER_COLOURS = {
  ink: 'rgb(138, 138, 138)',
  hatch: 'rgba(138, 138, 138, 0.18)',
  labelBackground: 'rgba(255, 255, 255, 0.85)',
  label: 'rgb(58, 58, 58)',
} as const;

/// A hatched, outlined, labelled stand-in for something the painter cannot draw.
export const paintPlaceholder = (ctx: SKRSContext2D, label: string, x: number, y: number, width: number, height: number) => {
  ctx.save();
  ctx.beginPath();
  ctx.rect(x, y, width, height);
  ctx.clip();
  ctx.fillStyle = PLACEHOLDER_COLOURS.hatch;
  ctx.fillRect(x, y, width, height);
  ctx.strokeStyle = PLACEHOLDER_COLOURS.ink;
  ctx.lineWidth = 0.5;
  for (let offset = -height; offset < width; offset += 4) {
    ctx.beginPath();
    ctx.moveTo(x + offset, y + height);
    ctx.lineTo(x + offset + height, y);
    ctx.stroke();
  }
  ctx.lineWidth = 1;
  ctx.strokeRect(x + 0.5, y + 0.5, Math.max(width - 1, 0), Math.max(height - 1, 0));
  if (label) {
    const run = { fontFamily: 'DMSans-Bold', fontSize: 6, letterSpacing: 0, lineHeight: undefined };
    const textWidth = measureRun(label, run);
    if (textWidth + 4 <= width && height >= 8) {
      ctx.fillStyle = PLACEHOLDER_COLOURS.labelBackground;
      ctx.fillRect(x + (width - textWidth) / 2 - 2, y + height / 2 - 4, textWidth + 4, 8);
      drawRun(ctx, label, { text: label, run, style: { color: PLACEHOLDER_COLOURS.label } }, x + (width - textWidth) / 2, y + height / 2 + 2);
    }
  }
  ctx.restore();
};

/// The target canvas, and its size, which bounds an opacity layer.
type Paint = { ctx: SKRSContext2D; canvasWidth: number; canvasHeight: number };

/// Paints one laid-out box and its subtree.
const paintNode = (paint: Paint, node: LaidOutNode, parentX: number, parentY: number, path: string): void => {
  const { ctx } = paint;
  const where = `${path} > ${node.type}`;
  const x = parentX + node.left;
  const y = parentY + node.top;
  const style = flatten(node.props.style);
  checkStyle(style, where);
  if (style.display === 'none') return;
  if (DRAWS_NOTHING.has(node.type)) return;
  const opacity = (style.opacity as number | undefined) ?? 1;
  if (opacity <= 0) return;

  const draw = (target: SKRSContext2D) => {
    target.save();
    applyTransform(target, style, x, y, node, where);
    const label = PLACEHOLDERS[node.type];
    if (label) {
      paintPlaceholder(target, label(node.props), x, y, node.width, node.height);
      target.restore();
      return;
    }
    const radii = radiiOf(style, node.width, node.height);
    paintShadow(target, style, x, y, node, radii);
    if (style.backgroundColor !== undefined && style.backgroundColor !== 'transparent') {
      target.fillStyle = style.backgroundColor as string;
      outline(target, x, y, node.width, node.height, radii);
      target.fill();
    }
    paintBorders(target, node, style, x, y, radii);
    if (node.type === 'Text') paintText(target, node, style, x, y, where);
    else if (node.type === 'TextInput') paintTextInput(target, node, style, x, y, where);
    else if (node.type === 'RNSVGSvgView') {
      target.save();
      target.translate(x, y);
      paintSvg(target, node, where);
      target.restore();
    } else if (PLAIN_HOSTS.has(node.type)) {
      // Vertical scroll views are recorded at content height, so only horizontal ones clip.
      const clips = style.overflow === 'hidden' || (node.type === 'RCTScrollView' && node.props.horizontal === true);
      if (clips) {
        outline(target, x, y, node.width, node.height, radii);
        target.clip();
      }
      const ordered = node.children
        .map((child, index) => ({ child, index, z: (flatten(child.props.style).zIndex as number | undefined) ?? 0 }))
        .sort((a, b) => a.z - b.z || a.index - b.index);
      for (const { child } of ordered) paintNode({ ...paint, ctx: target }, child, x, y, where);
    } else fail(where, 'is a host type this painter neither draws nor stands in for');
    target.restore();
  };

  if (opacity >= 1) {
    draw(ctx);
    return;
  }
  // Group opacity composites the subtree once, so overlapping children do not show through.
  const box = layerBounds(paint, node, style, x, y, ctx.getTransform());
  if (box.width <= 0 || box.height <= 0) return;
  const layer = createCanvas(box.width, box.height);
  const layerCtx = layer.getContext('2d');
  const base = ctx.getTransform();
  layerCtx.setTransform(base.a, base.b, base.c, base.d, base.e - box.left, base.f - box.top);
  draw(layerCtx);
  ctx.save();
  ctx.setTransform(1, 0, 0, 1, 0, 0);
  ctx.globalAlpha *= opacity;
  ctx.drawImage(layer, box.left, box.top);
  ctx.restore();
};

/// How far a box's shadow can reach past it, in layout units: the blur twice over, plus its offset.
const shadowReach = (style: Style): number => {
  if (((style.shadowOpacity as number | undefined) ?? 0) <= 0) return 0;
  const offset = (style.shadowOffset as { width?: number; height?: number } | undefined) ?? {};
  const blur = (style.shadowRadius as number | undefined) ?? 3;
  return 2 * blur + Math.max(Math.abs(offset.width ?? 0), Math.abs(offset.height ?? 0));
};

/// The layout-space rectangle a subtree can paint into, including every shadow in it.
const subtreeExtent = (node: LaidOutNode, x: number, y: number) => {
  const reach = shadowReach(flatten(node.props.style));
  let extent = { left: x - reach, top: y - reach, right: x + node.width + reach, bottom: y + node.height + reach };
  for (const child of node.children) {
    const inner = subtreeExtent(child, x + child.left, y + child.top);
    extent = {
      left: Math.min(extent.left, inner.left),
      top: Math.min(extent.top, inner.top),
      right: Math.max(extent.right, inner.right),
      bottom: Math.max(extent.bottom, inner.bottom),
    };
  }
  return extent;
};

/// The device-pixel box an opacity layer needs: the subtree's reach, or the whole canvas under a transform.
const layerBounds = (
  paint: Paint,
  node: LaidOutNode,
  style: Style,
  x: number,
  y: number,
  matrix: { a: number; b: number; c: number; d: number; e: number; f: number },
) => {
  const whole = { left: 0, top: 0, width: paint.canvasWidth, height: paint.canvasHeight };
  if (((style.transform ?? []) as unknown[]).length > 0 || matrix.b !== 0 || matrix.c !== 0) return whole;
  const extent = subtreeExtent(node, x, y);
  const xs = [extent.left, extent.right].map((px) => matrix.a * px + matrix.e);
  const ys = [extent.top, extent.bottom].map((py) => matrix.d * py + matrix.f);
  const left = Math.max(0, Math.floor(Math.min(...xs)));
  const top = Math.max(0, Math.floor(Math.min(...ys)));
  const right = Math.min(paint.canvasWidth, Math.ceil(Math.max(...xs)));
  const bottom = Math.min(paint.canvasHeight, Math.ceil(Math.max(...ys)));
  return { left, top, width: right - left, height: bottom - top };
};

/// The bottom edge of everything in the tree.
export const contentHeight = (node: LaidOutNode, top = 0): number =>
  Math.max(top + node.top + node.height, ...node.children.map((child) => contentHeight(child, top + node.top)));

/// Paints a laid-out tree at [PIXEL_RATIO] into a canvas its content height tall.
export const paintTree = (
  root: LaidOutNode,
  { backdrop, overlay }: {
    backdrop?: string;
    overlay?: (ctx: SKRSContext2D, width: number) => void;
  } = {},
): Canvas => {
  registerFonts();
  const width = Math.ceil(root.width * PIXEL_RATIO);
  const height = Math.max(Math.ceil(contentHeight(root) * PIXEL_RATIO), 1);
  const canvas = createCanvas(width, height);
  const ctx = canvas.getContext('2d');
  if (backdrop) {
    ctx.fillStyle = backdrop;
    ctx.fillRect(0, 0, width, height);
  }
  ctx.scale(PIXEL_RATIO, PIXEL_RATIO);
  paintNode({ ctx, canvasWidth: width, canvasHeight: height }, { ...root, left: 0, top: 0 }, 0, 0, 'root');
  overlay?.(ctx, root.width);
  return canvas;
};
