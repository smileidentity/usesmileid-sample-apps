import { Path2D, type CanvasGradient, type SKRSContext2D } from '@napi-rs/canvas';

import type { LaidOutNode } from '../layout/layout-tree';

/// A react-native-svg colour: a packed ARGB int or a gradient reference.
type Brush = { readonly type: number; readonly payload?: number; readonly brushRef?: string } | null;

/// The presentation attributes a child inherits from its group.
type Inherited = {
  readonly fill: Brush;
  readonly fillOpacity: number;
  readonly fillRule: number;
  readonly stroke: Brush;
  readonly strokeOpacity: number;
  readonly strokeWidth: number;
  readonly strokeLinecap: number;
  readonly strokeLinejoin: number;
  readonly strokeMiterlimit: number;
  readonly strokeDasharray: readonly (number | string)[] | null;
  readonly strokeDashoffset: number | null;
};

/// A linear gradient's props, keyed by name.
type Gradient = { readonly props: Record<string, unknown> };

/// The presentation attributes a group passes to its children.
const INHERITED_NAMES = [
  'fill', 'fillOpacity', 'fillRule', 'stroke', 'strokeOpacity', 'strokeWidth', 'strokeLinecap',
  'strokeLinejoin', 'strokeMiterlimit', 'strokeDasharray', 'strokeDashoffset',
] as const;

/// SVG's initial values: a black fill and no stroke.
const DEFAULTS: Inherited = {
  fill: { type: 0, payload: 0xff000000 },
  fillOpacity: 1,
  fillRule: 1,
  stroke: null,
  strokeOpacity: 1,
  strokeWidth: 1,
  strokeLinecap: 0,
  strokeLinejoin: 0,
  strokeMiterlimit: 4,
  strokeDasharray: null,
  strokeDashoffset: 0,
};

/// Every RNSVG prop the painter draws or knows to be inert.
const KNOWN_PROPS = new Set<string>([
  ...INHERITED_NAMES, 'propList', 'opacity', 'matrix', 'd', 'x', 'y', 'width', 'height', 'rx', 'ry',
  'cx', 'cy', 'r', 'x1', 'x2', 'y1', 'y2', 'name', 'gradient', 'gradientUnits', 'gradientTransform',
  'align', 'meetOrSlice', 'minX', 'minY', 'vbWidth', 'vbHeight', 'bbWidth', 'bbHeight', 'style',
  'focusable', 'pointerEvents', 'testID', 'accessible', 'accessibilityLabel', 'accessibilityRole',
  'collapsable', 'responsible', 'importantForAccessibility',
]);

/// react-native-svg's line cap and join enums, in native order.
const CAPS = ['butt', 'round', 'square'] as const;
const JOINS = ['miter', 'round', 'bevel'] as const;

/// A packed, possibly signed, ARGB int as a CSS colour.
export const argb = (packed: number, alpha = 1): string => {
  const value = packed >>> 0;
  const a = ((value >>> 24) & 0xff) / 255;
  return `rgba(${(value >>> 16) & 0xff}, ${(value >>> 8) & 0xff}, ${value & 0xff}, ${a * alpha})`;
};

/// Fails, naming the element the painter could not draw.
const fail = (where: string, message: string): never => {
  throw new Error(`${where}: ${message}`);
};

/// A length as authored: a number, a numeric string, or a percentage of [extent].
const length = (value: unknown, extent: number, where: string): number => {
  if (value === undefined || value === null) return 0;
  if (typeof value === 'number') return value;
  if (typeof value === 'string') {
    if (value.endsWith('%')) return (Number.parseFloat(value) / 100) * extent;
    const parsed = Number(value);
    if (!Number.isNaN(parsed)) return parsed;
  }
  return fail(where, `"${String(value)}" is not a length this painter reads`);
};

/// The attributes [node] draws with, its own over its group's.
const inherit = (node: LaidOutNode, from: Inherited): Inherited => {
  const own = node.props;
  const listed = new Set((own.propList as string[] | undefined) ?? []);
  const isGroup = node.type === 'RNSVGGroup' || node.type === 'RNSVGSvgView';
  const next: Record<string, unknown> = { ...from };
  for (const name of INHERITED_NAMES) {
    // A shape carries every attribute; only those in propList were authored.
    const authored = isGroup ? own[name] !== undefined : listed.has(name);
    if (authored) next[name] = own[name] ?? (name === 'fill' || name === 'stroke' ? null : DEFAULTS[name]);
  }
  return next as Inherited;
};

/// A rectangle in the view box's own units.
type Box = { x: number; y: number; width: number; height: number };

/// The canvas paint for a brush over [box], or undefined for none.
const paintBrush = (
  ctx: SKRSContext2D,
  brush: Brush,
  opacity: number,
  box: Box,
  gradients: ReadonlyMap<string, Gradient>,
  where: string,
): string | CanvasGradient | undefined => {
  if (brush === null) return undefined;
  if (brush.type === 0) return argb(brush.payload ?? 0, opacity);
  if (brush.type === 1) {
    const gradient = gradients.get(brush.brushRef ?? '') ?? fail(where, `no gradient named "${brush.brushRef}"`);
    return linearGradient(ctx, gradient, opacity, box, where);
  }
  return fail(where, `brush type ${brush.type} is not one this painter draws`);
};

/// A linear gradient over [box], in bounding-box or user-space units.
const linearGradient = (
  ctx: SKRSContext2D,
  gradient: Gradient,
  opacity: number,
  box: Box,
  where: string,
): CanvasGradient => {
  const { props } = gradient;
  if (props.gradientTransform !== null && props.gradientTransform !== undefined) {
    fail(where, 'a transformed gradient is not one this painter draws');
  }
  const userSpace = props.gradientUnits === 1;
  const along = (value: unknown, offset: number, extent: number) =>
    userSpace ? length(value, extent, where) : offset + length(value, 1, where) * extent;
  const x1 = along(props.x1 ?? '0', box.x, box.width);
  const y1 = along(props.y1 ?? '0', box.y, box.height);
  const x2 = along(props.x2 ?? '1', box.x, box.width);
  const y2 = along(props.y2 ?? '0', box.y, box.height);
  const canvasGradient = ctx.createLinearGradient(x1, y1, x2, y2);
  const stops = props.gradient as number[];
  for (let index = 0; index + 1 < stops.length; index += 2) {
    canvasGradient.addColorStop(stops[index]!, argb(stops[index + 1]!, opacity));
  }
  return canvasGradient;
};

/// A shape's path and the box its gradient resolves against.
const shapeOf = (node: LaidOutNode, viewBox: Box, where: string): { path: Path2D; box: Box } => {
  const p = node.props;
  switch (node.type) {
    case 'RNSVGPath': {
      if (typeof p.d !== 'string') fail(where, 'a path with no d');
      return { path: new Path2D(p.d as string), box: viewBox };
    }
    case 'RNSVGRect': {
      const box = {
        x: length(p.x, viewBox.width, where),
        y: length(p.y, viewBox.height, where),
        width: length(p.width, viewBox.width, where),
        height: length(p.height, viewBox.height, where),
      };
      const rx = length(p.rx ?? p.ry, viewBox.width, where);
      const path = new Path2D();
      if (rx > 0) path.roundRect(box.x, box.y, box.width, box.height, rx);
      else path.rect(box.x, box.y, box.width, box.height);
      return { path, box };
    }
    case 'RNSVGCircle': {
      const cx = length(p.cx, viewBox.width, where);
      const cy = length(p.cy, viewBox.height, where);
      const r = length(p.r, Math.hypot(viewBox.width, viewBox.height) / Math.SQRT2, where);
      const path = new Path2D();
      path.arc(cx, cy, r, 0, Math.PI * 2);
      return { path, box: { x: cx - r, y: cy - r, width: 2 * r, height: 2 * r } };
    }
    case 'RNSVGLine': {
      const path = new Path2D();
      path.moveTo(length(p.x1, viewBox.width, where), length(p.y1, viewBox.height, where));
      path.lineTo(length(p.x2, viewBox.width, where), length(p.y2, viewBox.height, where));
      return { path, box: viewBox };
    }
    default:
      return fail(where, 'is not an SVG shape this painter draws');
  }
};

/// Fills then strokes one shape.
const paintShape = (
  ctx: SKRSContext2D,
  node: LaidOutNode,
  style: Inherited,
  opacity: number,
  viewBox: Box,
  gradients: ReadonlyMap<string, Gradient>,
  where: string,
): void => {
  const { path, box } = shapeOf(node, viewBox, where);
  if (node.type === 'RNSVGPath' && style.fill?.type === 1) {
    fail(where, 'a gradient fill on a path needs its bounding box, which this painter does not compute');
  }
  const fill = paintBrush(ctx, style.fill, opacity * style.fillOpacity, box, gradients, where);
  if (fill !== undefined && node.type !== 'RNSVGLine') {
    ctx.fillStyle = fill;
    ctx.fill(path, style.fillRule === 0 ? 'evenodd' : 'nonzero');
  }
  const stroke = paintBrush(ctx, style.stroke, opacity * style.strokeOpacity, box, gradients, where);
  if (stroke !== undefined && style.strokeWidth > 0) {
    ctx.strokeStyle = stroke;
    ctx.lineWidth = style.strokeWidth;
    ctx.lineCap = CAPS[style.strokeLinecap] ?? fail(where, `line cap ${style.strokeLinecap}`);
    ctx.lineJoin = JOINS[style.strokeLinejoin] ?? fail(where, `line join ${style.strokeLinejoin}`);
    ctx.miterLimit = style.strokeMiterlimit;
    // react-native-svg passes dash lengths as strings.
    ctx.setLineDash((style.strokeDasharray ?? []).map((dash) => length(dash, 0, where)));
    ctx.lineDashOffset = style.strokeDashoffset ?? 0;
    ctx.stroke(path);
  }
};

/// Paints a group's children in order.
const paintChildren = (
  ctx: SKRSContext2D,
  node: LaidOutNode,
  from: Inherited,
  opacity: number,
  viewBox: Box,
  gradients: ReadonlyMap<string, Gradient>,
  where: string,
): void => {
  for (const child of node.children) {
    const at = `${where} > ${child.type}`;
    for (const name of Object.keys(child.props)) {
      if (!KNOWN_PROPS.has(name)) fail(at, `the prop "${name}" is neither drawn nor known to draw nothing`);
    }
    if (child.type === 'RNSVGDefs') continue;
    const style = inherit(child, from);
    const alpha = opacity * ((child.props.opacity as number | undefined) ?? 1);
    ctx.save();
    const matrix = child.props.matrix as number[] | undefined | null;
    if (matrix) ctx.transform(matrix[0]!, matrix[1]!, matrix[2]!, matrix[3]!, matrix[4]!, matrix[5]!);
    if (child.type === 'RNSVGGroup') paintChildren(ctx, child, style, alpha, viewBox, gradients, at);
    else paintShape(ctx, child, style, alpha, viewBox, gradients, at);
    ctx.restore();
  }
};

/// Every gradient the tree defines; other paint servers fail.
const collectGradients = (node: LaidOutNode, into: Map<string, Gradient>, where: string): void => {
  for (const child of node.children) {
    if (child.type === 'RNSVGLinearGradient') into.set(child.props.name as string, { props: child.props });
    else if (child.type === 'RNSVGRadialGradient' || child.type === 'RNSVGPattern') {
      fail(`${where} > ${child.type}`, 'is not a paint server this painter draws');
    }
    collectGradients(child, into, where);
  }
};

/// Paints one react-native-svg root into its laid-out box, honouring preserveAspectRatio.
export const paintSvg = (ctx: SKRSContext2D, node: LaidOutNode, where: string): void => {
  const p = node.props;
  const vbWidth = (p.vbWidth as number | undefined) ?? 0;
  const vbHeight = (p.vbHeight as number | undefined) ?? 0;
  const viewBox =
    vbWidth > 0 && vbHeight > 0
      ? { x: (p.minX as number) ?? 0, y: (p.minY as number) ?? 0, width: vbWidth, height: vbHeight }
      : { x: 0, y: 0, width: node.width, height: node.height };
  ctx.save();
  if (vbWidth > 0 && vbHeight > 0) {
    const sx = node.width / vbWidth;
    const sy = node.height / vbHeight;
    if (p.meetOrSlice === 2 || p.align === 'none') {
      ctx.scale(sx, sy);
    } else {
      const scale = p.meetOrSlice === 1 ? Math.max(sx, sy) : Math.min(sx, sy);
      const align = String(p.align ?? 'xMidYMid');
      const slack = (extent: number, content: number, key: 'x' | 'y') => {
        const part = key === 'x' ? align.slice(1, 4) : align.slice(5, 8);
        if (part === 'Min') return 0;
        if (part === 'Max') return extent - content;
        return (extent - content) / 2;
      };
      ctx.translate(slack(node.width, vbWidth * scale, 'x'), slack(node.height, vbHeight * scale, 'y'));
      ctx.scale(scale, scale);
    }
    ctx.translate(-viewBox.x, -viewBox.y);
  }
  const gradients = new Map<string, Gradient>();
  collectGradients(node, gradients, where);
  // The root's fill is a string react-native-svg already moved onto its first group.
  paintChildren(ctx, node, DEFAULTS, 1, viewBox, gradients, where);
  ctx.restore();
};
