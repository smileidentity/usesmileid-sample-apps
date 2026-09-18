import { flattenLayout, layoutTree, type LaidOutNode, type RenderedNode } from './layout-tree';
import { wordAround } from './measure-text';

/// One break the text never offered: the word it landed inside, and how that word read across the two lines.
export type SmileTextBreak = { readonly word: string; readonly detail: string };

/// What the pass found, returned rather than asserted so the rule itself can be tested.
export type SmileTextScaleFindings = {
  readonly truncated: readonly string[];
  readonly split: readonly SmileTextBreak[];
};

/// The narrowest and the widest frame the four apps draw on; a label that survives both survives between.
export const NARROW_WIDTH = 320;
export const WIDE_WIDTH = 393;

type Options = {
  readonly width?: number;
  readonly fontScale?: number;

  /// Words whose breaking is a RECORDED open design question, not a defect this port may fix.
  readonly knownOpenWords?: readonly string[];

  /// Text whose ellipsis is a RECORDED open question; kept apart so neither half mutes the other.
  readonly knownEllipsised?: readonly string[];
};

/// Lays the tree out and reports every mid-word break and every paragraph the line cap clips.
export const textScaleFindings = (
  rendered: RenderedNode,
  { width = WIDE_WIDTH, fontScale = 1 }: Options = {},
): SmileTextScaleFindings => {
  const boxes = flattenLayout(layoutTree(rendered, { width, fontScale }));
  const texts = boxes.filter((box): box is LaidOutNode & { text: string } => box.text !== undefined);
  if (texts.length === 0) throw new Error('collected no text to check');
  const truncated: string[] = [];
  const split: SmileTextBreak[] = [];
  for (const box of texts) {
    const lines = box.lines ?? [];
    if (box.numberOfLines !== undefined && lines.length > box.numberOfLines) {
      truncated.push(box.text);
    }
    for (const line of lines) {
      if (!line.midWordBreak) continue;
      split.push({
        word: wordAround(box.text, line.end),
        detail: `${line.text} | ${box.text.slice(line.end)}`,
      });
    }
  }
  return { truncated, split };
};

/// Fails on text the line cap clips, or on a word broken where the text offered no break.
export const assertSurvivesTextScale = (rendered: RenderedNode, options: Options = {}): void => {
  const findings = textScaleFindings(rendered, options);
  const knownOpenWords = options.knownOpenWords ?? [];
  const knownEllipsised = options.knownEllipsised ?? [];
  const at = `${options.width ?? WIDE_WIDTH} wide at ${options.fontScale ?? 1}x text scale`;
  // The broken word alone: a paragraph match mutes every other break in any string holding it.
  const split = findings.split
    .filter((it) => !knownOpenWords.some((known) => it.word.includes(known)))
    .map((it) => it.detail);
  const truncated = findings.truncated.filter(
    (it) => !knownEllipsised.some((known) => it.includes(known)),
  );
  expect({ at, truncated }).toEqual({ at, truncated: [] });
  expect({ at, split }).toEqual({ at, split: [] });
};
