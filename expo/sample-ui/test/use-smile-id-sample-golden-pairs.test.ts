import { createElement } from 'react';
import { Text } from 'react-native';
import { createHash } from 'node:crypto';
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

import { smileDarkColors, smileLightColors } from '../src/theme/smile-colors';
import { useSmileIDSampleTheme } from '../src/theme/use-smile-id-sample-theme';
import { renderInTheme, schemes } from './render-in-theme';
import { scaleSensitive } from './scale-sensitive-states';

/// Two states whose baselines are byte-identical are not two baselines, so each pair that is
/// identical on purpose is named here and a new one fails — the cheapest dark-mode miss to ship.
const identicalOnPurpose: Record<string, string> = {
  'Avatar/initials': 'the fill is a profile hue and the initials are white, neither of which changes by scheme',
  'Avatar/row_size': 'same as Avatar/initials, at the size the profile row passes',
  'Button/disabled':
    'button.disabled.background points at a primitive so it cannot re-resolve for dark — the buttonDisabledBypassesSemanticTier delta',
  'SectionLabel/default': 'color.text.muted is the same grey in both schemes — the darkMuted delta',
  'StatusBadge/clear': 'the soft badge fills are specified as one pair per role, not per scheme',
  'StatusBadge/attention': 'the soft badge fills are specified as one pair per role, not per scheme',
  'StatusBadge/blocked': 'the soft badge fills are specified as one pair per role, not per scheme',
  'StatusBadge/processing': 'the soft badge fills are specified as one pair per role, not per scheme',
  'DateGroupHeader/withRelativeWord': 'the whole header is color.text.muted — the darkMuted delta',
  'DateGroupHeader/absoluteOnly': 'the whole header is color.text.muted — the darkMuted delta',
  'DataFieldRow/withStatusValue':
    'data-field.label is the muted grey and the value is pinned to a soft badge colour, so nothing in the row varies by scheme',
  'SelectTrigger/disabled':
    'the disabled button pair and input.border are all mode-invariant — the buttonDisabledBypassesSemanticTier and darkBorder deltas together',
  'TokenRing/fresh': 'the ring is one delta green on a faded copy of itself, neither per scheme',
  'TokenRing/counting': 'the ring is one delta green on a faded copy of itself, neither per scheme',
  'TokenRing/expired': 'the ring is one delta green on a faded copy of itself, neither per scheme',
};

/// Both suites record light-then-dark, so both are read the same way.
const snapshotFiles = [
  'use-smile-id-sample-primitives.test.tsx.snap',
  'use-smile-id-sample-composites.test.tsx.snap',
  'use-smile-id-sample-screen-composites.test.tsx.snap',
  'use-smile-id-sample-screens.test.tsx.snap',
  'use-smile-id-sample-verifications.test.tsx.snap',
  'use-smile-id-sample-forms.test.tsx.snap',
  'use-smile-id-sample-profiles-screens.test.tsx.snap',
];

const expectedStates = 136;

const readPairs = () => {
  const pairs = new Map<string, { light?: string; dark?: string }>();
  for (const file of snapshotFiles) {
    const source = readFileSync(join(__dirname, 'goldens', file), 'utf8');
    const entries = /exports\[`([^`]+)`\] = `([\s\S]*?)`;\n/g;
    let match = entries.exec(source);
    while (match !== null) {
      const name = match[1] ?? '';
      const parsed = name.match(/^(\S+) (light|dark) (.+) 1$/);
      if (parsed) {
        const id = `${parsed[1]}/${parsed[3]}`;
        const existing = pairs.get(id) ?? {};
        pairs.set(id, { ...existing, [parsed[2] as 'light' | 'dark']: match[2] });
      }
      match = entries.exec(source);
    }
  }
  return pairs;
};

describe('the recorded goldens', () => {
  const pairs = readPairs();

  it('records both schemes for every state', () => {
    const halves = [...pairs.entries()].filter(([, v]) => !v.light || !v.dark).map(([id]) => id);
    expect(halves).toEqual([]);
  });

  it('records every state both suites declare', () => {
    expect(pairs.size).toBe(expectedStates);
  });

  it('has no identical light and dark pair that is not explained', () => {
    const identical = [...pairs.entries()]
      .filter(([, v]) => v.light === v.dark)
      .map(([id]) => id)
      .sort();
    expect(identical).toEqual(Object.keys(identicalOnPurpose).sort());
  });

  it('has no explained pair that has since started differing, which would make the note stale', () => {
    const differing = Object.keys(identicalOnPurpose).filter((id) => {
      const pair = pairs.get(id);
      return pair !== undefined && pair.light !== pair.dark;
    });
    expect(differing).toEqual([]);
  });

  it('names a recorded state for every explained pair, so a renamed state cannot orphan its note', () => {
    expect(Object.keys(identicalOnPurpose).filter((id) => !pairs.has(id))).toEqual([]);
  });

  it('carries no light-scheme page colour into a dark baseline', () => {
    // The Flutter port recorded a whole dark suite that was silently light.
    const lightPageOnly = [smileLightColors.background, smileLightColors.surfaceMuted];
    const leaked = [...pairs.entries()]
      .filter(([, pair]) => lightPageOnly.some((colour) => (pair.dark ?? '').includes(colour)))
      .map(([id]) => id);
    expect(leaked).toEqual([]);
  });
});

/// An interaction state must differ from its base, or the event never landed and the pair records it twice.
const interactionStates: readonly (readonly [string, string])[] = [
  ['Button/enabled', 'Button/pressed'],
  ['TextInput/filled', 'TextInput/focused'],
  ['TextInput/error', 'TextInput/error_focused'],
  ['SearchField/filled', 'SearchField/focused'],
  ['FilterChip/default', 'FilterChip/pressed'],
  ['KeyValueEditRow/filled', 'KeyValueEditRow/focused'],
];

describe('a state reached by interaction', () => {
  const pairs = readPairs();

  it('differs from the state it starts in, in both schemes', () => {
    const unchanged: string[] = [];
    for (const [base, reached] of interactionStates) {
      const from = pairs.get(base);
      const to = pairs.get(reached);
      expect({ base, found: from !== undefined && to !== undefined }).toEqual({ base, found: true });
      if (from?.light === to?.light || from?.dark === to?.dark) unchanged.push(reached);
    }
    expect(unchanged).toEqual([]);
  });
});

/// Two states whose trees match in one scheme are one baseline posing as two: the fixture or the
/// renderer is blind to the axis the state varies, so a regression on that axis cannot fail.
const identicalStatesOnPurpose: Record<string, string> = {};

describe('two states in one scheme', () => {
  const pairs = readPairs();
  const twins = (): string[] => {
    const found: string[] = [];
    for (const scheme of ['light', 'dark'] as const) {
      const seen = new Map<string, string>();
      for (const [id, pair] of [...pairs.entries()].sort(([a], [b]) => a.localeCompare(b))) {
        const tree = pair[scheme];
        if (tree === undefined) continue;
        const first = seen.get(tree);
        if (first === undefined) seen.set(tree, id);
        else found.push(`${first} == ${id}`);
      }
    }
    return [...new Set(found)].sort();
  };

  it('never share a tree unless the pair is explained', () => {
    expect(twins().filter((twin) => !(twin in identicalStatesOnPurpose))).toEqual([]);
  });

  it('has no explained pair that has since started differing, which would make the note stale', () => {
    const live = new Set(twins());
    expect(Object.keys(identicalStatesOnPurpose).filter((twin) => !live.has(twin))).toEqual([]);
  });
});

/// Light and dark pictures that match although their trees differ.
const identicalInPixelsOnPurpose: Record<string, string> = {
  'Switch/on': 'the native switch is drawn as a placeholder, so its tint never reaches the picture',
  'Switch/off': 'the native switch is drawn as a placeholder, so its tint never reaches the picture',
  'Switch/disabled_on': 'the native switch is drawn as a placeholder, so its tint never reaches the picture',
  'Switch/disabled_off': 'the native switch is drawn as a placeholder, so its tint never reaches the picture',
};

/// Two states whose pictures match although their trees differ.
const pixelTwinsOnPurpose: Record<string, string> = {
  'JobRow/default == SwipeAction/closed': 'a closed swipe draws the row alone; only the gesture wrapper differs',
  'KeyValueEditRow/filled == KeyValueEditRow/focused':
    'the edit row draws no focus state, so the focused tree differs only by the testID the interaction needs',
  'TextInput/error == TextInput/error_focused':
    'the error border outranks focus by design, so the focused tree differs only by the testID the interaction needs',
};

/// Each suite's PNGs, read as `component/state` pairs.
const readPixelPairs = (files: readonly string[]) => {
  const pairs = new Map<string, { light?: string; dark?: string }>();
  for (const file of files) {
    const dir = join(__dirname, 'goldens', file.replace(/\.test\.tsx\.snap$/, ''));
    for (const png of readdirSync(dir).filter((name) => name.endsWith('.png'))) {
      const parsed = png.match(/^([^.]+)\.(light|dark)\.(.+)\.png$/);
      if (!parsed) throw new Error(`${png} is not named <component>.<light|dark>.<state>.png`);
      const id = `${parsed[1]}/${parsed[3]}`;
      const digest = createHash('sha256').update(readFileSync(join(dir, png))).digest('hex');
      pairs.set(id, { ...pairs.get(id), [parsed[2] as 'light' | 'dark']: digest });
    }
  }
  return pairs;
};

/// Every pair of distinct states that painted the same picture in one scheme, as `first == second`.
const twinsIn = (pairs: ReadonlyMap<string, { light?: string; dark?: string }>): string[] => {
  const found: string[] = [];
  for (const scheme of ['light', 'dark'] as const) {
    const seen = new Map<string, string>();
    for (const [id, pair] of [...pairs.entries()].sort(([a], [b]) => a.localeCompare(b))) {
      const digest = pair[scheme];
      if (digest === undefined) continue;
      const first = seen.get(digest);
      if (first === undefined) seen.set(digest, id);
      else found.push(`${first} == ${id}`);
    }
  }
  return [...new Set(found)].sort();
};

describe('the recorded pixel goldens', () => {
  const trees = readPairs();
  const pixels = readPixelPairs(snapshotFiles);

  it('paint exactly the states the style trees record, in both schemes', () => {
    const halves = (map: ReadonlyMap<string, { light?: string; dark?: string }>) =>
      [...map.entries()].filter(([, v]) => v.light !== undefined && v.dark !== undefined).map(([id]) => id).sort();
    expect(halves(pixels)).toEqual(halves(trees));
    expect(pixels.size).toBe(expectedStates);
  });

  it('paint a light and dark pair alike only where the trees match or the painter is explained', () => {
    const identical = [...pixels.entries()].filter(([, v]) => v.light === v.dark).map(([id]) => id).sort();
    expect(identical).toEqual(
      [...Object.keys(identicalOnPurpose), ...Object.keys(identicalInPixelsOnPurpose)].sort(),
    );
  });

  it('explain a pixel-only light and dark match that the trees really do tell apart', () => {
    const stale = Object.keys(identicalInPixelsOnPurpose).filter((id) => {
      const tree = trees.get(id);
      return tree === undefined || tree.light === tree.dark;
    });
    expect(stale).toEqual([]);
  });

  it('never paint two states alike unless the pair is explained', () => {
    const explained = { ...identicalStatesOnPurpose, ...pixelTwinsOnPurpose };
    expect(twinsIn(pixels).filter((twin) => !(twin in explained))).toEqual([]);
  });

  it('has no explained pixel twin that has since started differing, which would make the note stale', () => {
    const live = new Set(twinsIn(pixels));
    expect(Object.keys(pixelTwinsOnPurpose).filter((twin) => !live.has(twin))).toEqual([]);
  });

  it('paint every interaction state differently from its base, unless the pair is explained', () => {
    const unchanged = interactionStates
      .filter(([base, reached]) => !(`${base} == ${reached}` in pixelTwinsOnPurpose))
      .filter(([base, reached]) => {
        const from = pixels.get(base);
        const to = pixels.get(reached);
        return from?.light === to?.light || from?.dark === to?.dark;
      })
      .map(([, reached]) => reached);
    expect(unchanged).toEqual([]);
  });

  it('paint every enlarged state in both schemes, one picture per recorded tree', () => {
    const enlarged = readdirSync(join(__dirname, 'goldens', 'use-smile-id-sample-font-scale'));
    expect(enlarged.filter((name) => name.endsWith('.png')).length).toBe(
      Object.keys(scaleSensitive).length * schemes.length,
    );
  });
});

describe('the theme provider', () => {
  it('reaches the components with the scheme the harness pins, not the runner default', async () => {
    // Through the provider: comparing the two palettes passes with the provider ignoring `dark`.
    for (const { dark } of schemes) {
      const rendered = await renderInTheme(createElement(BackgroundProbe), dark);
      expect(rendered.getByTestId('probe').props.children).toBe(
        (dark ? smileDarkColors : smileLightColors).background,
      );
    }
    expect(smileLightColors.background).not.toEqual(smileDarkColors.background);
  });
});

const BackgroundProbe = () => createElement(Text, { testID: 'probe' }, useSmileIDSampleTheme().colors.background);
