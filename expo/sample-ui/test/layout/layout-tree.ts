import { StyleSheet, type TextStyle, type ViewStyle } from 'react-native';
import { loadYoga, type Config as YogaConfig, type Node as YogaNode, type Yoga } from 'yoga-layout/load';

import { layoutSpans, type SmileTextLine, type SmileTextSpan } from './measure-text';
import { isBundledFace, measureRun } from './smile-font';

/// What `render(...).toJSON()` hands back: a host element, or the text inside one.
export type RenderedNode =
  | string
  | { readonly type: string; readonly props: Record<string, unknown>; readonly children: RenderedNode[] | null };

/// One styled stretch of a laid-out paragraph, with its resolved style.
export type LaidOutSpan = { readonly text: string; readonly run: TextRun; readonly style: Style };

/// A box's four resolved padding or border edges.
export type LaidOutEdges = { readonly top: number; readonly right: number; readonly bottom: number; readonly left: number };

/// One laid-out box, plus the lines if the box was text.
export type LaidOutNode = {
  readonly type: string;
  readonly props: Record<string, unknown>;
  readonly left: number;
  readonly top: number;
  readonly width: number;
  readonly height: number;
  readonly padding: LaidOutEdges;
  readonly border: LaidOutEdges;
  readonly text?: string;
  readonly lines?: readonly SmileTextLine[];
  readonly spans?: readonly LaidOutSpan[];
  /// The scaled run a single-line field draws its value in.
  readonly field?: TextRun;
  readonly numberOfLines?: number;
  readonly children: readonly LaidOutNode[];
};

let yoga: Yoga | undefined;

/// The grid of the layout pass in progress, set only during one [layoutTree] call.
let activeConfig: YogaConfig | undefined;

/// Loads the WASM engine once per worker; every later pass is synchronous.
export const loadLayoutEngine = async (): Promise<void> => {
  yoga ??= await loadYoga();
};

const engine = (): Yoga => {
  if (!yoga) throw new Error('call loadLayoutEngine() before laying a tree out');
  return yoga;
};

/// Style props that change a box, each mapped onto the engine's own setter.
const LAYOUT_PROPS = new Set([
  'width', 'height', 'minWidth', 'minHeight', 'maxWidth', 'maxHeight',
  'flex', 'flexGrow', 'flexShrink', 'flexBasis', 'flexDirection', 'flexWrap',
  'justifyContent', 'alignItems', 'alignSelf', 'alignContent',
  'position', 'top', 'right', 'bottom', 'left', 'start', 'end',
  'margin', 'marginHorizontal', 'marginVertical', 'marginTop', 'marginRight',
  'marginBottom', 'marginLeft', 'marginStart', 'marginEnd',
  'padding', 'paddingHorizontal', 'paddingVertical', 'paddingTop', 'paddingRight',
  'paddingBottom', 'paddingLeft', 'paddingStart', 'paddingEnd',
  'borderWidth', 'borderTopWidth', 'borderRightWidth', 'borderBottomWidth',
  'borderLeftWidth', 'borderStartWidth', 'borderEndWidth',
  'gap', 'rowGap', 'columnGap', 'aspectRatio', 'display', 'overflow', 'direction', 'boxSizing',
]);

/// Style props that paint rather than lay out, listed so an unrecognised one can fail instead of vanish.
export const PAINT_PROPS: ReadonlySet<string> = new Set([
  'backgroundColor', 'color', 'opacity', 'transform', 'transformOrigin', 'zIndex', 'elevation',
  'borderRadius', 'borderTopLeftRadius', 'borderTopRightRadius', 'borderBottomLeftRadius',
  'borderBottomRightRadius', 'borderTopStartRadius', 'borderTopEndRadius',
  'borderBottomStartRadius', 'borderBottomEndRadius', 'borderCurve',
  'borderColor', 'borderTopColor', 'borderRightColor', 'borderBottomColor', 'borderLeftColor',
  'borderStartColor', 'borderEndColor', 'borderStyle',
  'shadowColor', 'shadowOffset', 'shadowOpacity', 'shadowRadius', 'boxShadow',
  'fontFamily', 'fontSize', 'fontStyle', 'fontWeight', 'fontVariant', 'letterSpacing',
  'lineHeight', 'textAlign', 'textAlignVertical', 'textDecorationLine', 'textDecorationColor',
  'textDecorationStyle', 'textShadowColor', 'textShadowOffset', 'textShadowRadius',
  'textTransform', 'includeFontPadding', 'writingDirection', 'verticalAlign', 'userSelect',
  'tintColor', 'resizeMode', 'objectFit', 'pointerEvents', 'cursor', 'backfaceVisibility',
  'isolation', 'mixBlendMode', 'filter', 'experimental_backgroundImage',
]);

/// A flattened React Native style.
export type Style = ViewStyle & TextStyle & Record<string, unknown>;

/// Flattens a host element's style prop into one object.
export const flatten = (style: unknown): Style => (StyleSheet.flatten(style as never) ?? {}) as Style;

/// A style value the engine has no constant for would otherwise coerce to 0 and lay out silently wrong.
const pick = (table: Record<string, number>, value: unknown, where: string, name: string): number => {
  const mapped = table[String(value)];
  if (mapped === undefined) {
    throw new Error(`${where}: "${name}: ${String(value)}" is not a value this harness maps`);
  }
  return mapped;
};

const ALIGN = (Y: Yoga) =>
  ({
    'flex-start': Y.ALIGN_FLEX_START,
    'flex-end': Y.ALIGN_FLEX_END,
    center: Y.ALIGN_CENTER,
    stretch: Y.ALIGN_STRETCH,
    baseline: Y.ALIGN_BASELINE,
    'space-between': Y.ALIGN_SPACE_BETWEEN,
    'space-around': Y.ALIGN_SPACE_AROUND,
    'space-evenly': Y.ALIGN_SPACE_EVENLY,
    auto: Y.ALIGN_AUTO,
  }) as Record<string, number>;

const JUSTIFY = (Y: Yoga) =>
  ({
    'flex-start': Y.JUSTIFY_FLEX_START,
    'flex-end': Y.JUSTIFY_FLEX_END,
    center: Y.JUSTIFY_CENTER,
    'space-between': Y.JUSTIFY_SPACE_BETWEEN,
    'space-around': Y.JUSTIFY_SPACE_AROUND,
    'space-evenly': Y.JUSTIFY_SPACE_EVENLY,
  }) as Record<string, number>;

const edgesFor = (Y: Yoga): Record<string, number> => ({
  '': Y.EDGE_ALL,
  Horizontal: Y.EDGE_HORIZONTAL,
  Vertical: Y.EDGE_VERTICAL,
  Top: Y.EDGE_TOP,
  Right: Y.EDGE_RIGHT,
  Bottom: Y.EDGE_BOTTOM,
  Left: Y.EDGE_LEFT,
  Start: Y.EDGE_START,
  End: Y.EDGE_END,
});

const asPercent = (value: unknown): number | undefined =>
  typeof value === 'string' && value.endsWith('%') ? Number.parseFloat(value) : undefined;

const applyDimension = (
  node: YogaNode,
  name: 'Width' | 'Height' | 'MinWidth' | 'MinHeight' | 'MaxWidth' | 'MaxHeight',
  value: unknown,
): void => {
  const percent = asPercent(value);
  if (percent !== undefined) {
    (node[`set${name}Percent`] as (v: number) => void)(percent);
    return;
  }
  if (value === 'auto') {
    if (name === 'Width') node.setWidthAuto();
    else if (name === 'Height') node.setHeightAuto();
    return;
  }
  if (typeof value === 'number') (node[`set${name}`] as (v: number) => void)(value);
};

const applyStyle = (node: YogaNode, style: Style, where: string): void => {
  const Y = engine();
  const align = ALIGN(Y);
  const justify = JUSTIFY(Y);
  const edges = edgesFor(Y);
  for (const [name, value] of Object.entries(style)) {
    if (value === undefined || value === null) continue;
    if (PAINT_PROPS.has(name)) continue;
    if (!LAYOUT_PROPS.has(name)) {
      throw new Error(
        `${where}: the style property "${name}" is neither mapped onto the layout engine nor known to only paint, so this tree would lay out as if it were absent`,
      );
    }
    switch (name) {
      case 'width': applyDimension(node, 'Width', value); break;
      case 'height': applyDimension(node, 'Height', value); break;
      case 'minWidth': applyDimension(node, 'MinWidth', value); break;
      case 'minHeight': applyDimension(node, 'MinHeight', value); break;
      case 'maxWidth': applyDimension(node, 'MaxWidth', value); break;
      case 'maxHeight': applyDimension(node, 'MaxHeight', value); break;
      case 'flex': node.setFlex(value as number); break;
      case 'flexGrow': node.setFlexGrow(value as number); break;
      case 'flexShrink': node.setFlexShrink(value as number); break;
      case 'flexBasis': {
        const percent = asPercent(value);
        if (percent !== undefined) node.setFlexBasisPercent(percent);
        else if (value === 'auto') node.setFlexBasisAuto();
        else node.setFlexBasis(value as number);
        break;
      }
      case 'flexDirection':
        node.setFlexDirection(
          pick(
            {
              row: Y.FLEX_DIRECTION_ROW,
              column: Y.FLEX_DIRECTION_COLUMN,
              'row-reverse': Y.FLEX_DIRECTION_ROW_REVERSE,
              'column-reverse': Y.FLEX_DIRECTION_COLUMN_REVERSE,
            },
            value, where, name,
          ),
        );
        break;
      case 'flexWrap':
        node.setFlexWrap(
          pick(
            { wrap: Y.WRAP_WRAP, nowrap: Y.WRAP_NO_WRAP, 'wrap-reverse': Y.WRAP_WRAP_REVERSE },
            value, where, name,
          ),
        );
        break;
      case 'justifyContent': node.setJustifyContent(pick(justify, value, where, name)); break;
      case 'alignItems': node.setAlignItems(pick(align, value, where, name)); break;
      case 'alignSelf': node.setAlignSelf(pick(align, value, where, name)); break;
      case 'alignContent': node.setAlignContent(pick(align, value, where, name)); break;
      case 'position':
        node.setPositionType(
          pick(
            {
              absolute: Y.POSITION_TYPE_ABSOLUTE,
              relative: Y.POSITION_TYPE_RELATIVE,
              static: Y.POSITION_TYPE_STATIC,
            },
            value, where, name,
          ),
        );
        break;
      case 'top': case 'right': case 'bottom': case 'left': case 'start': case 'end': {
        const edge = edges[name.charAt(0).toUpperCase() + name.slice(1)]!;
        const percent = asPercent(value);
        if (percent !== undefined) node.setPositionPercent(edge, percent);
        else node.setPosition(edge, value as number);
        break;
      }
      case 'aspectRatio': node.setAspectRatio(value as number); break;
      case 'display':
        node.setDisplay(value === 'none' ? Y.DISPLAY_NONE : Y.DISPLAY_FLEX);
        break;
      case 'overflow':
        node.setOverflow(
          pick(
            {
              visible: Y.OVERFLOW_VISIBLE,
              hidden: Y.OVERFLOW_HIDDEN,
              scroll: Y.OVERFLOW_SCROLL,
            },
            value, where, name,
          ),
        );
        break;
      case 'direction':
        node.setDirection(value === 'rtl' ? Y.DIRECTION_RTL : Y.DIRECTION_LTR);
        break;
      case 'boxSizing':
        node.setBoxSizing(
          value === 'content-box' ? Y.BOX_SIZING_CONTENT_BOX : Y.BOX_SIZING_BORDER_BOX,
        );
        break;
      case 'gap': node.setGap(Y.GUTTER_ALL, value as number); break;
      case 'rowGap': node.setGap(Y.GUTTER_ROW, value as number); break;
      case 'columnGap': node.setGap(Y.GUTTER_COLUMN, value as number); break;
      default: {
        if (name.startsWith('margin')) {
          const edge = edges[name.slice('margin'.length)]!;
          const percent = asPercent(value);
          if (value === 'auto') node.setMarginAuto(edge);
          else if (percent !== undefined) node.setMarginPercent(edge, percent);
          else node.setMargin(edge, value as number);
        } else if (name.startsWith('padding')) {
          const edge = edges[name.slice('padding'.length)]!;
          const percent = asPercent(value);
          if (percent !== undefined) node.setPaddingPercent(edge, percent);
          else node.setPadding(edge, value as number);
        } else if (name.startsWith('border') && name.endsWith('Width')) {
          const edge = edges[name.slice('border'.length, -'Width'.length)]!;
          node.setBorder(edge, value as number);
        } else {
          throw new Error(`${where}: "${name}" is listed as a layout property but nothing applies it`);
        }
      }
    }
  }
};

const fontRun = (style: Style, fontScale: number, props: Record<string, unknown>) => {
  const scale = props.allowFontScaling === false ? 1 : fontScale;
  const cap = props.maxFontSizeMultiplier as number | undefined;
  const applied = cap === undefined || cap === 0 ? scale : Math.min(scale, cap);
  return {
    fontFamily: style.fontFamily as string,
    fontSize: (style.fontSize ?? 14) * applied,
    // Letter spacing is set as a raw kern and is the one text metric the scale leaves alone.
    letterSpacing: style.letterSpacing ?? 0,
    lineHeight: style.lineHeight === undefined ? undefined : style.lineHeight * applied,
  };
};

type TextRun = ReturnType<typeof fontRun>;

/// The styled spans a Text subtree renders, a nested Text inheriting the style it does not override.
const spansOf = (
  node: RenderedNode,
  style: Style,
  props: Record<string, unknown>,
  fontScale: number,
  where: string,
): LaidOutSpan[] => {
  if (node === null) return [];
  if (typeof node === 'string') {
    if (!isBundledFace(style.fontFamily)) {
      throw new Error(`${where}: text is drawn in "${style.fontFamily}", which is not a bundled face`);
    }
    return [{ text: node, run: fontRun(style, fontScale, props), style }];
  }
  const inner = node.type === 'Text' ? { ...style, ...flatten(node.props.style) } : style;
  const innerProps = node.type === 'Text' ? { ...props, ...node.props } : props;
  return (node.children ?? []).flatMap((child) =>
    spansOf(child, inner, innerProps, fontScale, where),
  );
};

/// One run per span, deduplicated so a paragraph never measures the same style as two faces.
const internRuns = (spans: LaidOutSpan[]): LaidOutSpan[] => {
  const seen = new Map<string, TextRun>();
  return spans.map((span) => {
    const key = JSON.stringify(span.run);
    const run = seen.get(key) ?? (span.run as TextRun);
    seen.set(key, run);
    return { ...span, run };
  });
};

const lineHeightOf = (spans: readonly SmileTextSpan[]): number =>
  Math.max(
    ...spans.map((span) => (span.run as TextRun).lineHeight ?? span.run.fontSize * 1.2),
    0,
  );

type Built = {
  node: YogaNode;
  rendered: Exclude<RenderedNode, string>;
  style: Style;
  children: Built[];
};

const build = (
  rendered: RenderedNode,
  fontScale: number,
  path: string,
  inherited?: Style,
): Built | undefined => {
  if (rendered === null || typeof rendered === 'string') return undefined;
  const Y = engine();
  const where = `${path} > ${rendered.type}`;
  const node = Y.Node.create(activeConfig);
  const style = { ...inherited, ...flatten(rendered.props.style) };
  applyStyle(node, style, where);

  if (rendered.type === 'Text') {
    const spans = internRuns(spansOf(rendered, style, rendered.props, fontScale, where));
    const height = lineHeightOf(spans);
    const cap = lineCapOf(rendered.props);
    node.setMeasureFunc((available, widthMode) => {
      const bound = widthMode === Y.MEASURE_MODE_UNDEFINED ? Number.POSITIVE_INFINITY : available;
      const lines = layoutSpans(spans, bound);
      return {
        width: Math.min(bound, Math.max(...lines.map((line) => line.width), 0)),
        // A capped paragraph occupies its cap, not the height the overflow would have taken.
        height: Math.min(lines.length, cap ?? lines.length) * height,
      };
    });
    return { node, rendered, style, children: [] };
  }

  const leaf = measuredLeaf(rendered, style, fontScale, where);
  if (leaf) {
    node.setMeasureFunc((available, widthMode) => ({
      width:
        leaf.width === undefined
          ? widthMode === Y.MEASURE_MODE_UNDEFINED ? 0 : available
          : widthMode === Y.MEASURE_MODE_UNDEFINED ? leaf.width : Math.min(available, leaf.width),
      height: leaf.height,
    }));
    return { node, rendered, style, children: [] };
  }

  // The jest mock drops the row direction React Native gives a horizontal scroll view.
  const horizontal = rendered.type === 'RCTScrollView' && rendered.props.horizontal === true;
  if (horizontal && style.flexDirection === undefined) node.setFlexDirection(Y.FLEX_DIRECTION_ROW);
  const contentStyle =
    rendered.type === 'RCTScrollView'
      ? { ...(horizontal ? { flexDirection: 'row' as const } : {}), ...flatten(rendered.props.contentContainerStyle) }
      : undefined;
  const children: Built[] = [];
  let container = contentStyle;
  for (const child of rendered.children ?? []) {
    // The refresh control precedes the content container and is never it.
    const isContainer = typeof child === 'object' && child !== null && child.type !== 'RCTRefreshControl';
    const built = build(child, fontScale, where, isContainer ? container : undefined);
    if (isContainer) container = undefined;
    if (!built) continue;
    node.insertChild(built.node, children.length);
    children.push(built);
  }
  return { node, rendered, style, children };
};

/// UISwitch's fixed size, which a hostless runner reports as zero.
const NATIVE_SWITCH_SIZE = { width: 51, height: 31 } as const;

/// The on-device size of a self-measuring native leaf, which a stretching column still widens to fill it.
const measuredLeaf = (
  rendered: Exclude<RenderedNode, string>,
  style: Style,
  fontScale: number,
  where: string,
): { width?: number; height: number } | undefined => {
  if (rendered.type === 'RCTSwitch') return NATIVE_SWITCH_SIZE;
  if (rendered.type !== 'TextInput') return undefined;
  if (rendered.props.multiline === true) {
    throw new Error(`${where}: a multiline field measures its content, which this harness does not`);
  }
  if (!isBundledFace(style.fontFamily)) {
    throw new Error(`${where}: the field is drawn in "${style.fontFamily}", which is not a bundled face`);
  }
  const run = fontRun(style, fontScale, rendered.props);
  // Fabric measures a field by its text, or its placeholder when empty, so a row does not hand it the whole line.
  const shown = String(rendered.props.value || rendered.props.placeholder || '');
  return { width: measureRun(shown, run), height: run.lineHeight ?? run.fontSize * 1.2 };
};

/// React Native reads 0 as "no cap", which is not the same as one line.
const lineCapOf = (props: Record<string, unknown>): number | undefined => {
  const cap = props.numberOfLines as number | undefined;
  return cap === 0 ? undefined : cap;
};

/// The width the text itself was given: padding and border come out of the box before it wraps.
const contentWidth = (built: Built): number => {
  const Y = engine();
  const box = built.node.getComputedLayout();
  const inset = (edge: number) =>
    built.node.getComputedPadding(edge) + built.node.getComputedBorder(edge);
  return Math.max(box.width - inset(Y.EDGE_LEFT) - inset(Y.EDGE_RIGHT), 0);
};

/// A node's four computed edges of one kind.
const edgesOf = (read: (edge: number) => number): LaidOutEdges => {
  const Y = engine();
  return { top: read(Y.EDGE_TOP), right: read(Y.EDGE_RIGHT), bottom: read(Y.EDGE_BOTTOM), left: read(Y.EDGE_LEFT) };
};

const harvest = (built: Built, fontScale: number): LaidOutNode => {
  const box = built.node.getComputedLayout();
  const { style } = built;
  const base: LaidOutNode = {
    type: built.rendered.type,
    props: built.rendered.props,
    left: box.left,
    top: box.top,
    width: box.width,
    height: box.height,
    padding: edgesOf((edge) => built.node.getComputedPadding(edge)),
    border: edgesOf((edge) => built.node.getComputedBorder(edge)),
    children: built.children.map((child) => harvest(child, fontScale)),
  };
  if (built.rendered.type === 'TextInput') return { ...base, field: fontRun(style, fontScale, built.rendered.props) };
  if (built.rendered.type !== 'Text') return base;
  const spans = internRuns(
    spansOf(built.rendered, style, built.rendered.props, fontScale, built.rendered.type),
  );
  return {
    ...base,
    text: spans.map((span) => span.text).join(''),
    lines: layoutSpans(spans, contentWidth(built)),
    spans,
    numberOfLines: lineCapOf(built.rendered.props),
  };
};

/// Lays a rendered tree out at [width], as the engine React Native itself uses would lay it out.
export const layoutTree = (
  rendered: RenderedNode,
  { width, fontScale = 1, pixelRatio }: { width: number; fontScale?: number; pixelRatio?: number },
): LaidOutNode => {
  const Y = engine();
  // Without the device grid the engine rounds 0.5 hairlines to zero.
  activeConfig = pixelRatio === undefined ? undefined : Y.Config.create();
  activeConfig?.setPointScaleFactor(pixelRatio ?? 1);
  try {
    const built = build(rendered, fontScale, 'root');
    if (!built) throw new Error('nothing was rendered to lay out');
    built.node.setWidth(width);
    built.node.calculateLayout(width, undefined, Y.DIRECTION_LTR);
    const laidOut = harvest(built, fontScale);
    built.node.freeRecursive();
    return laidOut;
  } finally {
    if (activeConfig) Y.Config.destroy(activeConfig);
    activeConfig = undefined;
  }
};

/// Every box in the tree, parents before children.
export const flattenLayout = (node: LaidOutNode): LaidOutNode[] => [
  node,
  ...node.children.flatMap(flattenLayout),
];

