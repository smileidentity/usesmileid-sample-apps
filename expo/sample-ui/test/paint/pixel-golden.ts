import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { basename, dirname, join } from 'node:path';

import type { Canvas, SKRSContext2D } from '@napi-rs/canvas';
import pixelmatch from 'pixelmatch';
import { PNG } from 'pngjs';
import type { ReactElement } from 'react';

import { flatten, layoutTree, loadLayoutEngine, type RenderedNode } from '../layout/layout-tree';
import {
  DESIGN_FONT_SCALE,
  PINNED_FRAME,
  renderInTheme,
  withoutElementProps,
  withoutHarness,
  type Interaction,
} from '../render-in-theme';
import { paintPlaceholder, paintTree, PIXEL_RATIO, PLACEHOLDERS } from './paint-tree';

/// Where mismatches and would-be baselines are written.
export const GOLDEN_OUTPUT_DIR = join(__dirname, '..', 'golden-output');

/// `component.scheme.state`, from a test named `component scheme state`.
export const pngNameOf = (testName: string): string => {
  const parsed = testName.match(/^(\S+) (light|dark) (.+)$/);
  if (!parsed) throw new Error(`"${testName}" is not named "<component> <light|dark> <state>"`);
  return `${parsed[1]}.${parsed[2]}.${parsed[3]}`;
};

/// A native sheet's content, surface colour and grabber.
type Sheet = { content: RenderedNode; backdrop?: string; grabber: boolean };

/// One modifier @expo/ui passes to the sheet host.
type Modifier = { $type?: string; style?: { color?: string }; visibility?: string };

/// Unwraps a native sheet into its content and the chrome the painter can stand in for.
const sheetOf = (tree: RenderedNode): Sheet | undefined => {
  if (typeof tree === 'string' || tree.type !== 'ViewManagerAdapter_ExpoUI') return undefined;
  const modifiers: Modifier[] = [];
  let layoutRoot: Exclude<RenderedNode, string> | undefined;
  const walk = (node: RenderedNode) => {
    if (typeof node === 'string' || node.type !== 'ViewManagerAdapter_ExpoUI') return;
    modifiers.push(...((node.props.modifiers as Modifier[] | undefined) ?? []));
    if (node.props.layoutRoot === true) layoutRoot = node;
    else for (const child of node.children ?? []) walk(child);
  };
  walk(tree);
  if (!layoutRoot) throw new Error('a native sheet with no layout root the painter could lay its content out in');
  const background = modifiers.find((it) => it.$type === 'presentationBackground');
  const indicator = modifiers.find((it) => it.$type === 'presentationDragIndicator');
  return {
    content: { type: 'View', props: {}, children: (layoutRoot.children ?? []).map(sizedByContent) },
    backdrop: background?.style?.color,
    grabber: indicator?.visibility !== 'hidden',
  };
};

/// Drops the size the native sheet assigns on device, so the wrapper lays out at content size.
const sizedByContent = (node: RenderedNode): RenderedNode => {
  if (typeof node === 'string' || node === null) return node;
  const sizedOnDevice = new Set(['height', 'flexGrow', 'width']);
  const style = Object.fromEntries(Object.entries(flatten(node.props.style)).filter(([name]) => !sizedOnDevice.has(name)));
  return { ...node, props: { ...node.props, style } };
};

/// The native grabber's size and inset.
const GRABBER = { width: 36, height: 5, top: 5 } as const;

/// Stands in for the grabber.
const drawGrabber = (ctx: SKRSContext2D, width: number) => {
  const label = PLACEHOLDERS.SheetDragIndicator!({});
  paintPlaceholder(ctx, label, (width - GRABBER.width) / 2, GRABBER.top, GRABBER.width, GRABBER.height);
};

/// [node] with its style replaced.
const withStyle = <T extends Exclude<RenderedNode, string>>(node: T, style: Record<string, unknown>): T => ({
  ...node,
  props: { ...node.props, style },
});

/// Makes vertical scroll views grow from their content, so the picture holds all of it.
const scrolledThrough = (node: RenderedNode): RenderedNode => {
  if (typeof node === 'string' || node === null) return node;
  const children = (node.children ?? []).map(scrolledThrough);
  const style = flatten(node.props.style);
  const vertical = node.type === 'RCTScrollView' && node.props.horizontal !== true;
  if (!vertical || style.flex === undefined) return { ...node, children };
  const { flex, ...rest } = style;
  return { ...withStyle(node, { ...rest, flexGrow: flex, flexShrink: 0, flexBasis: 'auto' }), children };
};

/// Wraps [tree] in a window; a screen that fills its window is at least the pinned frame tall.
const inWindow = (tree: RenderedNode): RenderedNode => {
  const style = typeof tree === 'string' || tree === null ? {} : flatten(tree.props.style);
  const fillsWindow = style.flex !== undefined || style.flexGrow !== undefined;
  return { type: 'View', props: { style: fillsWindow ? { minHeight: PINNED_FRAME.height } : {} }, children: [tree] };
};

/// Lays [tree] out at the pinned width and content height, and paints it.
export const paintGolden = async (tree: RenderedNode, fontScale: number): Promise<Canvas> => {
  await loadLayoutEngine();
  const sheet = sheetOf(tree);
  const framed = sheet ? sheet.content : inWindow(tree);
  const laidOut = layoutTree(scrolledThrough(framed), { width: PINNED_FRAME.width, fontScale, pixelRatio: PIXEL_RATIO });
  return paintTree(laidOut, { backdrop: sheet?.backdrop, overlay: sheet?.grabber ? drawGrabber : undefined });
};

/// The canvas's pixels as a PNG.
const pixelsOf = (canvas: Canvas): PNG => {
  const png = new PNG({ width: canvas.width, height: canvas.height });
  const { data } = canvas.getContext('2d').getImageData(0, 0, canvas.width, canvas.height);
  png.data = Buffer.from(data.buffer, data.byteOffset, data.byteLength);
  return png;
};

/// The modes jest's snapshot state can be in, which is private to jest and so is checked, not assumed.
const RECORDING_MODES = ['all', 'new', 'none'] as const;

type RecordingMode = (typeof RECORDING_MODES)[number];

/// UPDATE_GOLDENS=1 re-records; otherwise the run follows `jest -u` or `--ci`.
const recordingMode = (): RecordingMode => {
  if (process.env.UPDATE_GOLDENS === '1') return 'all';
  const mode = (expect.getState().snapshotState as unknown as { _updateSnapshot?: unknown })._updateSnapshot;
  if (!RECORDING_MODES.includes(mode as RecordingMode)) {
    throw new Error(`jest's snapshot state no longer says whether to record (got ${String(mode)}); use UPDATE_GOLDENS=1`);
  }
  return mode as RecordingMode;
};

/// Writes [bytes], creating the directory.
const write = (path: string, bytes: Buffer) => {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, bytes);
};

/// Compares [canvas] against its baseline with zero tolerance.
export const expectPixelGolden = (canvas: Canvas, name: string): void => {
  const { testPath } = expect.getState();
  if (!testPath) throw new Error('a pixel golden needs the running test file');
  const suite = basename(testPath).replace(/\.test\.tsx?$/, '');
  const baseline = join(dirname(testPath), 'goldens', suite, `${name}.png`);
  const bytes = canvas.encodeSync('png');
  const mode = recordingMode();
  const recorded = existsSync(baseline) ? readFileSync(baseline) : undefined;
  if (recorded?.equals(bytes)) return;
  if (mode === 'all' || (mode === 'new' && recorded === undefined)) {
    write(baseline, bytes);
    return;
  }
  const record = () => {
    write(join(GOLDEN_OUTPUT_DIR, 'recorded', suite, `${name}.png`), bytes);
    write(join(GOLDEN_OUTPUT_DIR, 'failures', suite, `${name}.actual.png`), bytes);
  };
  if (recorded === undefined) {
    record();
    throw new Error(`no pixel golden is recorded for ${suite}/${name}; run with UPDATE_GOLDENS=1 to record it`);
  }
  const expected = PNG.sync.read(recorded);
  const png = pixelsOf(canvas);
  if (expected.width !== png.width || expected.height !== png.height) {
    record();
    throw new Error(
      `${suite}/${name} is ${png.width}x${png.height}, and its baseline is ${expected.width}x${expected.height}`,
    );
  }
  const diff = new PNG({ width: png.width, height: png.height });
  const differing = pixelmatch(expected.data, png.data, diff.data, png.width, png.height, { threshold: 0 });
  // Same pixels under different bytes is an encoder change, not a regression.
  if (differing === 0) return;
  record();
  write(join(GOLDEN_OUTPUT_DIR, 'failures', suite, `${name}.diff.png`), PNG.sync.write(diff));
  throw new Error(`${suite}/${name} differs from its baseline in ${differing} pixels`);
};

/// Records one state as a style-tree snapshot and a PNG from a single render.
export const expectGoldens = async (
  element: ReactElement,
  dark: boolean,
  { interact, fontScale = DESIGN_FONT_SCALE, name }: { interact?: Interaction; fontScale?: number; name?: string } = {},
): Promise<void> => {
  const rendered = await renderInTheme(element, dark, fontScale);
  if (interact) await interact(rendered);
  const tree = withoutElementProps(withoutHarness(rendered.toJSON()));
  expect(tree).toMatchSnapshot();
  if (tree === null || Array.isArray(tree)) throw new Error('a golden must render exactly one host element');
  const canvas = await paintGolden(tree as RenderedNode, fontScale);
  expectPixelGolden(canvas, name ?? pngNameOf(expect.getState().currentTestName ?? ''));
};
