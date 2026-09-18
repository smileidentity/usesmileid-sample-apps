import { StyleSheet, type TextStyle, type ViewStyle } from 'react-native';
import { loadYoga, type Node as YogaNode, type Yoga } from 'yoga-layout/load';

import { layoutSpans, type SmileTextLine, type SmileTextSpan } from './measure-text';
import { isBundledFace } from './smile-font';

/// What `render(...).toJSON()` hands back: a host element, or the text inside one.
export type RenderedNode =
  | string
  | { readonly type: string; readonly props: Record<string, unknown>; readonly children: RenderedNode[] | null };

/// One laid-out box, plus the lines if the box was text.
export type LaidOutNode = {
  readonly type: string;
  readonly props: Record<string, unknown>;
  readonly left: number;
  readonly top: number;
  readonly width: number;
  readonly height: number;
  readonly text?: string;
  readonly lines?: readonly SmileTextLine[];
  readonly numberOfLines?: number;
  readonly children: readonly LaidOutNode[];
};

let yoga: Yoga | undefined;

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
  'gap', 'rowGap', 'columnGap', 'aspectRatio', 'display', 'overflow', 'direction',
]);

/// Style props that paint rather than lay out, listed so an unrecognised one can fail instead of vanish.
const PAINT_PROPS = new Set([
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
  'boxSizing', 'isolation', 'mixBlendMode', 'filter', 'experimental_backgroundImage',
]);

type Style = ViewStyle & TextStyle & Record<string, unknown>;

const flatten = (style: unknown): Style => (StyleSheet.flatten(style as never) ?? {}) as Style;

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
          {
            row: Y.FLEX_DIRECTION_ROW,
            column: Y.FLEX_DIRECTION_COLUMN,
            'row-reverse': Y.FLEX_DIRECTION_ROW_REVERSE,
            'column-reverse': Y.FLEX_DIRECTION_COLUMN_REVERSE,
          }[value as string]!,
        );
        break;
      case 'flexWrap':
        node.setFlexWrap(
          { wrap: Y.WRAP_WRAP, nowrap: Y.WRAP_NO_WRAP, 'wrap-reverse': Y.WRAP_WRAP_REVERSE }[
            value as string
          ]!,
        );
        break;
      case 'justifyContent': node.setJustifyContent(justify[value as string]!); break;
      case 'alignItems': node.setAlignItems(align[value as string]!); break;
      case 'alignSelf': node.setAlignSelf(align[value as string]!); break;
      case 'alignContent': node.setAlignContent(align[value as string]!); break;
      case 'position':
        node.setPositionType(
          {
            absolute: Y.POSITION_TYPE_ABSOLUTE,
            relative: Y.POSITION_TYPE_RELATIVE,
            static: Y.POSITION_TYPE_STATIC,
          }[value as string]!,
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
          {
            visible: Y.OVERFLOW_VISIBLE,
            hidden: Y.OVERFLOW_HIDDEN,
            scroll: Y.OVERFLOW_SCROLL,
          }[value as string]!,
        );
        break;
      case 'direction':
        node.setDirection(value === 'rtl' ? Y.DIRECTION_RTL : Y.DIRECTION_LTR);
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
): SmileTextSpan[] => {
  if (node === null) return [];
  if (typeof node === 'string') {
    if (!isBundledFace(style.fontFamily)) {
      throw new Error(`${where}: text is drawn in "${style.fontFamily}", which is not a bundled face`);
    }
    return [{ text: node, run: fontRun(style, fontScale, props) }];
  }
  const inner = node.type === 'Text' ? { ...style, ...flatten(node.props.style) } : style;
  const innerProps = node.type === 'Text' ? { ...props, ...node.props } : props;
  return (node.children ?? []).flatMap((child) =>
    spansOf(child, inner, innerProps, fontScale, where),
  );
};

/// One run per span, deduplicated so a paragraph never measures the same style as two faces.
const internRuns = (spans: SmileTextSpan[]): SmileTextSpan[] => {
  const seen = new Map<string, TextRun>();
  return spans.map((span) => {
    const key = JSON.stringify(span.run);
    const run = seen.get(key) ?? (span.run as TextRun);
    seen.set(key, run);
    return { text: span.text, run };
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
  const node = Y.Node.create();
  const style = { ...inherited, ...flatten(rendered.props.style) };
  applyStyle(node, style, where);

  if (rendered.type === 'Text') {
    const spans = internRuns(spansOf(rendered, style, rendered.props, fontScale, where));
    const height = lineHeightOf(spans);
    node.setMeasureFunc((available, widthMode) => {
      const bound = widthMode === Y.MEASURE_MODE_UNDEFINED ? Number.POSITIVE_INFINITY : available;
      const lines = layoutSpans(spans, bound);
      return {
        width: Math.min(bound, Math.max(...lines.map((line) => line.width), 0)),
        height: lines.length * height,
      };
    });
    return { node, rendered, style, children: [] };
  }

  // A scroll view styles its content container through a prop, so the padding is not on the child itself.
  const contentStyle =
    rendered.type === 'RCTScrollView' ? flatten(rendered.props.contentContainerStyle) : undefined;
  const children: Built[] = [];
  for (const child of rendered.children ?? []) {
    const built = build(child, fontScale, where, children.length === 0 ? contentStyle : undefined);
    if (!built) continue;
    node.insertChild(built.node, children.length);
    children.push(built);
  }
  return { node, rendered, style, children };
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
    children: built.children.map((child) => harvest(child, fontScale)),
  };
  if (built.rendered.type !== 'Text') return base;
  const spans = internRuns(
    spansOf(built.rendered, style, built.rendered.props, fontScale, built.rendered.type),
  );
  const cap = built.rendered.props.numberOfLines as number | undefined;
  return {
    ...base,
    text: spans.map((span) => span.text).join(''),
    lines: layoutSpans(spans, box.width),
    numberOfLines: cap === 0 ? undefined : cap,
  };
};

/// Lays a rendered tree out at [width], as the engine React Native itself uses would lay it out.
export const layoutTree = (
  rendered: RenderedNode,
  { width, fontScale = 1 }: { width: number; fontScale?: number },
): LaidOutNode => {
  const Y = engine();
  const built = build(rendered, fontScale, 'root');
  if (!built) throw new Error('nothing was rendered to lay out');
  built.node.setWidth(width);
  built.node.calculateLayout(width, undefined, Y.DIRECTION_LTR);
  const laidOut = harvest(built, fontScale);
  built.node.freeRecursive();
  return laidOut;
};

/// Every box in the tree, parents before children.
export const flattenLayout = (node: LaidOutNode): LaidOutNode[] => [
  node,
  ...node.children.flatMap(flattenLayout),
];

