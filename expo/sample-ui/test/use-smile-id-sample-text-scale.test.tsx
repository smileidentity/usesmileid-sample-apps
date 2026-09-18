import { Text } from 'react-native';

import { UseSmileIDSampleNavBar } from '../src/components/use-smile-id-sample-nav-bar';
import { UseSmileIDSampleSelectionBar } from '../src/components/use-smile-id-sample-selection-bar';
import { flattenLayout, layoutTree } from './layout/layout-tree';
import { loadLayoutEngine, renderForLayout } from './layout/render-for-layout';
import { measureRun } from './layout/smile-font';
import {
  NARROW_WIDTH,
  WIDE_WIDTH,
  assertSurvivesTextScale,
  textScaleFindings,
} from './layout/text-scale';
import { scaleSensitive } from './scale-sensitive-states';
import { DESIGN_FONT_SCALE, ENLARGED_FONT_SCALE } from './render-in-theme';

const noop = () => {};

/// Both frames at both scales: a label that survives all four survives every phone the apps ship on.
const envelopes = [
  [NARROW_WIDTH, DESIGN_FONT_SCALE],
  [NARROW_WIDTH, ENLARGED_FONT_SCALE],
  [WIDE_WIDTH, DESIGN_FONT_SCALE],
  [WIDE_WIDTH, ENLARGED_FONT_SCALE],
] as const;

/// The words the Flutter twin also records as an open design question, not a defect this port may fix.
const tabOpenWords = ['Products', 'Verifications', 'Settings'];

/// Per state, not global: an exemption recorded for one row must not mute the same word in another.
/// The job id is what the Flutter twin records for this row — a column too narrow for one hex id.
const openWords: Record<string, readonly string[]> = {
  data_field_row_with_copy: ['7d2f01aa-4b1c'],
};

/// A column too narrow for one word, which is the smallest tree either half of the rule can fire on.
const NARROW_COLUMN = { width: 60 };

const text = (value: string, numberOfLines?: number) => (
  <Text numberOfLines={numberOfLines} style={{ fontFamily: 'DMSans-Bold', fontSize: 20, lineHeight: 24 }}>
    {value}
  </Text>
);

beforeAll(async () => {
  await loadLayoutEngine();
});

describe('text is measured the way a shaper measures it', () => {
  const bold = (text: string, letterSpacing?: number) =>
    measureRun(text, { fontFamily: 'DMSans-Bold', fontSize: 20, letterSpacing });

  it('applies the standard ligatures, so an "fi" is one glyph and not two', () => {
    expect(bold('fi')).toBeLessThan(bold('f') + bold('i'));
  });

  it('applies pair kerning, so "AV" is tighter than its two glyphs apart', () => {
    expect(bold('AV')).toBeLessThan(bold('A') + bold('V'));
  });

  it('adds letter spacing per character without scaling it', () => {
    expect(bold('AV', 2) - bold('AV')).toBeCloseTo(4, 10);
  });

  // Pinned against fontkit's own shaping of the same face: 42,805 comparisons agreed exactly.
  it('measures the label this bar turns on to the unit', () => {
    expect(bold('Verifications')).toBeCloseTo(123.88, 10);
  });
});

describe('the rule itself can fail', () => {
  it('flags a word broken where the text offered no break', async () => {
    const found = textScaleFindings(await renderForLayout(text('Verifications')), NARROW_COLUMN);
    // Every break is reported, not just the first, so a column three lines too narrow reads as worse than one.
    expect(found.split.length).toBeGreaterThan(0);
    expect([...new Set(found.split.map((it) => it.word))]).toEqual(['Verifications']);
  });

  it('flags text the line cap clips', async () => {
    const found = textScaleFindings(await renderForLayout(text('Verifications pending', 1)), NARROW_COLUMN);
    expect(found.truncated).toEqual(['Verifications pending']);
  });

  it('leaves a word the text broke for itself alone', async () => {
    const found = textScaleFindings(await renderForLayout(text('Tap to go')), NARROW_COLUMN);
    expect(found).toEqual({ split: [], truncated: [] });
  });

  it('reads a cap of zero as no cap, which is what React Native does with it', async () => {
    const found = textScaleFindings(await renderForLayout(text('Verifications pending', 0)), NARROW_COLUMN);
    expect(found.truncated).toEqual([]);
  });
});

describe('a recorded exemption stays as narrow as it was recorded', () => {
  it('matches the word that broke, never the paragraph holding it', async () => {
    const tree = await renderForLayout(text('Verifications'));
    // 'Verifications pending' contains the broken word, so a paragraph match would mute it; a word match cannot.
    expect(() =>
      assertSurvivesTextScale(tree, { ...NARROW_COLUMN, knownOpenWords: ['Verifications pending'] }),
    ).toThrow();
    expect(() =>
      assertSurvivesTextScale(tree, { ...NARROW_COLUMN, knownOpenWords: ['Verifications'] }),
    ).not.toThrow();
  });

  it('keeps breaking and ellipsis apart, so neither set mutes the other', async () => {
    const broken = await renderForLayout(text('Verifications'));
    const clipped = await renderForLayout(text('Verifications pending', 1));
    // Each half only answers to its own set: crossing them over leaves both findings standing.
    expect(() =>
      assertSurvivesTextScale(broken, { ...NARROW_COLUMN, knownEllipsised: ['Verifications'] }),
    ).toThrow();
    expect(() =>
      assertSurvivesTextScale(clipped, { ...NARROW_COLUMN, knownOpenWords: ['Verifications'] }),
    ).toThrow();
  });
});

describe('the nav bar survives every frame the apps draw on', () => {
  it.each(envelopes)('at %ipt wide and %ix', async (width, fontScale) => {
    const tree = await renderForLayout(
      <UseSmileIDSampleNavBar selectedId="products" onSelect={noop} onTokenPress={noop} />,
      { fontScale },
    );
    assertSurvivesTextScale(tree, { width, fontScale, knownOpenWords: tabOpenWords });
  });

  it('still needs every word it exempts, so the exemption cannot outlive the defect', async () => {
    // Comparing the set against a copy of itself would pin nothing: this asks whether each word still breaks.
    const tree = await renderForLayout(
      <UseSmileIDSampleNavBar selectedId="products" onSelect={noop} onTokenPress={noop} />,
      { fontScale: ENLARGED_FONT_SCALE },
    );
    const broken = textScaleFindings(tree, {
      width: NARROW_WIDTH,
      fontScale: ENLARGED_FONT_SCALE,
    }).split.map((it) => it.word);
    expect(tabOpenWords.filter((word) => !broken.some((it) => it.includes(word)))).toEqual([]);
  });
});

describe('every scale-sensitive state survives both frames at both scales', () => {
  it.each(Object.keys(scaleSensitive))('%s', async (state) => {
    for (const [width, fontScale] of envelopes) {
      const tree = await renderForLayout(scaleSensitive[state]!(), { fontScale });
      assertSurvivesTextScale(tree, { width, fontScale, knownOpenWords: openWords[state] });
    }
  });
});

describe('every recorded exemption still names a defect that is present', () => {
  it.each(Object.entries(openWords))('%s', async (state, words) => {
    // Without this, fixing the row leaves the exemption inert and silently muting the next regression.
    const broken: string[] = [];
    for (const [width, fontScale] of envelopes) {
      const tree = await renderForLayout(scaleSensitive[state]!(), { fontScale });
      broken.push(...textScaleFindings(tree, { width, fontScale }).split.map((it) => it.word));
    }
    expect(words.filter((word) => !broken.some((it) => it.includes(word)))).toEqual([]);
  });
});

describe('the selection bar wraps its action rather than crushing its own hint', () => {
  it('keeps the hint wider than the button it sits beside, at the narrowest frame and largest type', async () => {
    // A row whose text takes flexBasis 0 never wraps: it collapses instead, and the hint broke mid-word.
    const tree = await renderForLayout(
      <UseSmileIDSampleSelectionBar selectedCount={3} onRemove={noop} />,
      { fontScale: ENLARGED_FONT_SCALE },
    );
    const boxes = flattenLayout(layoutTree(tree, { width: NARROW_WIDTH, fontScale: ENLARGED_FONT_SCALE }));
    const hint = boxes.find((box) => box.text === 'Tap `Hide from List` to confirm');
    const action = boxes.find((box) => box.text === 'Hide from List');
    expect(hint!.width).toBeGreaterThan(action!.width);
  });
});
