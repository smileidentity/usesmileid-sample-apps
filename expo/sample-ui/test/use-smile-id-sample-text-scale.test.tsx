import { Text } from 'react-native';

import { UseSmileIDSampleNavBar } from '../src/components/use-smile-id-sample-nav-bar';
import { UseSmileIDSampleSelectionBar } from '../src/components/use-smile-id-sample-selection-bar';
import { loadLayoutEngine, renderForLayout } from './layout/render-for-layout';
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

/// The job id the Flutter twin records for the same row; a column too narrow for one hex id is the design's.
const jobIdOpenWords = ['7d2f01aa-4b1c'];

/// Still broken, so its entry cannot quietly outlive the defect: the pairing test below reds when it is fixed.
const stillBroken = ['selection_bar'];

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

  it('records only the three tab labels, and only because the Flutter twin records them', () => {
    expect(tabOpenWords).toEqual(['Products', 'Verifications', 'Settings']);
  });
});

describe('every scale-sensitive state survives both frames at both scales', () => {
  const states = Object.keys(scaleSensitive).filter((state) => !stillBroken.includes(state));

  it.each(states)('%s', async (state) => {
    for (const [width, fontScale] of envelopes) {
      const tree = await renderForLayout(scaleSensitive[state]!(), { fontScale });
      assertSurvivesTextScale(tree, { width, fontScale, knownOpenWords: jobIdOpenWords });
    }
  });
});

describe('the selection bar is excluded because it is still broken, not because it is exempt', () => {
  it('crushes its own hint rather than wrapping, which the Flutter twin does not', async () => {
    // `flex: 1` sets flexBasis 0, so the wrapping row never wraps: the text collapses beside the button.
    const tree = await renderForLayout(
      <UseSmileIDSampleSelectionBar selectedCount={3} onRemove={noop} />,
      { fontScale: ENLARGED_FONT_SCALE },
    );
    const found = textScaleFindings(tree, {
      width: NARROW_WIDTH,
      fontScale: ENLARGED_FONT_SCALE,
    });
    expect(found.split.map((it) => it.word)).toContain('selected');
  });
});
