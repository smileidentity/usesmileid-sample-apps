import { measureRun, type SmileFontRun } from './smile-font';

/// One stretch of a paragraph drawn in a single style; a nested Text starts a new one.
export type SmileTextSpan = { readonly text: string; readonly run: SmileFontRun };

/// One laid-out line, its span in the original string, and whether the break ENDING it was never offered.
export type SmileTextLine = {
  readonly text: string;
  readonly width: number;
  readonly midWordBreak: boolean;
  readonly start: number;
  readonly end: number;
};

const isSpace = (character: string): boolean => character.trim().length === 0;

const isHyphen = (character: string): boolean =>
  character === '-' || character === '–' || character === '—';

const isDigit = (character: string): boolean => character >= '0' && character <= '9';

/// Whether a break at [index] is one the text itself offered, which is the rule UAX#14 decides by.
const breaksCleanly = (text: string, index: number): boolean => {
  if (index <= 0 || index >= text.length) return true;
  if (isSpace(text[index - 1]!) || isSpace(text[index]!)) return true;
  return isHyphen(text[index - 1]!) && !isDigit(text[index]!);
};

/// Every index a line may legally end at: after a run of spaces, and after a hyphen that is not a minus.
const breakOpportunities = (text: string): number[] => {
  const indices: number[] = [];
  for (let index = 1; index < text.length; index++) {
    if (isSpace(text[index - 1]!) && !isSpace(text[index]!)) indices.push(index);
    else if (isHyphen(text[index - 1]!) && !isDigit(text[index]!)) indices.push(index);
  }
  return indices;
};

type Paragraph = {
  readonly text: string;
  /// The style each character is drawn in, so a width never measures two faces as one run.
  readonly runs: readonly SmileFontRun[];
  readonly runAt: readonly number[];
};

const paragraphOf = (spans: readonly SmileTextSpan[]): Paragraph => {
  const runs: SmileFontRun[] = [];
  const runAt: number[] = [];
  let text = '';
  for (const span of spans) {
    let index = runs.indexOf(span.run);
    if (index < 0) index = runs.push(span.run) - 1;
    text += span.text;
    for (let at = 0; at < span.text.length; at++) runAt.push(index);
  }
  return { text, runs, runAt };
};

/// Trailing spaces hang past the edge rather than forcing a break, as they do in every text engine.
const widthOf = (paragraph: Paragraph, start: number, end: number): number => {
  let last = end;
  while (last > start && isSpace(paragraph.text[last - 1]!)) last--;
  let width = 0;
  let from = start;
  while (from < last) {
    const run = paragraph.runAt[from]!;
    let to = from;
    while (to < last && paragraph.runAt[to] === run) to++;
    width += measureRun(paragraph.text.slice(from, to), paragraph.runs[run]!);
    from = to;
  }
  return width;
};

/// The greedy fill a text engine performs, breaking a word only where the line cannot hold it whole.
const layoutParagraph = (
  paragraph: Paragraph,
  maxWidth: number,
  offset: number,
): SmileTextLine[] => {
  const { text } = paragraph;
  const lines: SmileTextLine[] = [];
  const stops = [...breakOpportunities(text), text.length];
  let start = 0;
  let lastFit = -1;
  let index = 0;
  const emit = (end: number, midWordBreak: boolean) => {
    lines.push({
      text: text.slice(start, end),
      width: widthOf(paragraph, start, end),
      midWordBreak,
      start: offset + start,
      end: offset + end,
    });
    start = end;
    lastFit = -1;
  };
  while (index < stops.length) {
    const stop = stops[index]!;
    if (stop <= start) {
      index++;
      continue;
    }
    if (widthOf(paragraph, start, stop) <= maxWidth) {
      lastFit = stop;
      index++;
      continue;
    }
    if (lastFit > start) {
      emit(lastFit, false);
      continue;
    }
    // The chunk alone overruns the line, so the break lands inside it: the finding this rule exists for.
    let fits = start + 1;
    while (fits < stop && widthOf(paragraph, start, fits + 1) <= maxWidth) fits++;
    emit(fits, !breaksCleanly(text, fits));
  }
  if (start < text.length || lines.length === 0) {
    lines.push({
      text: text.slice(start),
      width: widthOf(paragraph, start, text.length),
      midWordBreak: false,
      start: offset + start,
      end: offset + text.length,
    });
  }
  return lines;
};

/// Lays a run of styled spans out in [maxWidth], honouring the hard breaks the string itself carries.
export const layoutSpans = (
  spans: readonly SmileTextSpan[],
  maxWidth: number,
): readonly SmileTextLine[] => {
  const width = Math.max(maxWidth, 0);
  const whole = paragraphOf(spans);
  const lines: SmileTextLine[] = [];
  let offset = 0;
  for (const piece of whole.text.split('\n')) {
    const paragraph: Paragraph = {
      text: piece,
      runs: whole.runs,
      runAt: whole.runAt.slice(offset, offset + piece.length),
    };
    if (width === 0) {
      lines.push({
        text: piece,
        width: widthOf(paragraph, 0, piece.length),
        midWordBreak: false,
        start: offset,
        end: offset + piece.length,
      });
    } else {
      lines.push(...layoutParagraph(paragraph, width, offset));
    }
    offset += piece.length + 1;
  }
  return lines;
};

/// The whitespace-delimited word [index] falls inside, which is what a finding records rather than the line.
export const wordAround = (text: string, index: number): string => {
  let start = index;
  while (start > 0 && !isSpace(text[start - 1]!)) start--;
  let end = index;
  while (end < text.length && !isSpace(text[end]!)) end++;
  return text.slice(start, end);
};
