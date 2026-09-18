import { StyleSheet } from 'react-native';

import { avatarColorForProfile } from '../src/components/use-smile-id-sample-avatar';
import { UseSmileIDSampleNavBar } from '../src/components/use-smile-id-sample-nav-bar';
import { smileIDSampleNavItems } from '../src/model/use-smile-id-sample-nav-item';
import { UseSmileIDSampleTestIds } from '../src/use-smile-id-sample-test-ids';
import { ProductsScreen } from '../src/screens/products-screen';
import { SettingsScreen } from '../src/screens/settings-screen';
import { VerificationsScreen } from '../src/screens/verifications-screen';
import { smileIDSampleSettingsDefaults } from '../src/state/use-smile-id-sample-settings';
import { layoutTree, type RenderedNode } from './layout/layout-tree';
import { loadLayoutEngine, renderForLayout } from './layout/render-for-layout';
import { NARROW_WIDTH, WIDE_WIDTH } from './layout/text-scale';
import { DESIGN_FONT_SCALE, ENLARGED_FONT_SCALE, PINNED_BOTTOM_INSET } from './render-in-theme';

const noop = () => {};

const bar = (selectedId = 'products') => (
  <UseSmileIDSampleNavBar selectedId={selectedId} onSelect={noop} onTokenPress={noop} />
);

const barHeight = async (width: number, fontScale: number, selectedId = 'products') => {
  const tree = await renderForLayout(bar(selectedId), { fontScale });
  return layoutTree(tree, { width, fontScale }).height;
};

const screens = {
  products: (bottomInset?: number) => (
    <ProductsScreen
      state={{ initials: 'KA', avatarColor: avatarColorForProfile(0) }}
      onProductPress={noop}
      onProfilePress={noop}
      onScanPress={noop}
      bottomInset={bottomInset}
    />
  ),
  verifications: (bottomInset?: number) => (
    <VerificationsScreen
      state={{ jobs: [], nowMillis: 0 }}
      onJobPress={noop}
      onRemove={noop}
      bottomInset={bottomInset}
    />
  ),
  settings: (bottomInset?: number) => (
    <SettingsScreen
      state={{
        settings: smileIDSampleSettingsDefaults,
        organisation: 'UpTech Finance',
        initials: 'KA',
        versionLabel: 'Smile ID · 1.0.0',
      }}
      onSettingChange={noop}
      onProfilePress={noop}
      onNavRowPress={noop}
      onSignOut={noop}
      bottomInset={bottomInset}
    />
  ),
};

/// The node carrying a given test id, which is how a screen's own list is told from one nested inside it.
const byTestID = (node: RenderedNode, testID: string): Exclude<RenderedNode, string> | undefined => {
  if (node === null || typeof node === 'string') return undefined;
  if (node.props.testID === testID) return node;
  for (const child of node.children ?? []) {
    const found = byTestID(child, testID);
    if (found) return found;
  }
  return undefined;
};

/// Each screen's own list, named so a ScrollView nested inside one cannot be measured by mistake.
const screenIds = {
  products: UseSmileIDSampleTestIds.PRODUCTS_SCREEN,
  verifications: UseSmileIDSampleTestIds.VERIFICATIONS_SCREEN,
  settings: UseSmileIDSampleTestIds.SETTINGS_SCREEN,
} as const;

/// What the scrolled-to-end list actually clears: the padding the content container reserves.
/// Read off the rendered tree, not a laid-out box — no width or scale can change what the prop says.
const reservedBottom = async (element: React.ReactElement, testID: string) => {
  const scroll = byTestID(await renderForLayout(element), testID);
  if (!scroll) throw new Error(`no scrolling list is tagged ${testID} to read a reserve from`);
  // The padding sits on the content-container PROP, not on the child's own style: reading the child reads 0.
  const style = StyleSheet.flatten(scroll.props.contentContainerStyle as never) as {
    paddingBottom?: number;
  };
  return style?.paddingBottom ?? 0;
};

beforeAll(async () => {
  await loadLayoutEngine();
});

describe('the nav bar is taller than any formula over its token predicts', () => {
  it.each([
    [NARROW_WIDTH, DESIGN_FONT_SCALE, 127],
    [NARROW_WIDTH, ENLARGED_FONT_SCALE, 191],
    [WIDE_WIDTH, DESIGN_FONT_SCALE, 111],
    [WIDE_WIDTH, ENLARGED_FONT_SCALE, 159],
  ])('measures %ipt wide at %ix as %ipt tall', async (width, fontScale, expected) => {
    expect(await barHeight(width, fontScale)).toBe(expected);
  });

  it('grows with the scale at both widths, which is the term a fixed reserve cannot see', async () => {
    for (const width of [NARROW_WIDTH, WIDE_WIDTH]) {
      const design = await barHeight(width, DESIGN_FONT_SCALE);
      const enlarged = await barHeight(width, ENLARGED_FONT_SCALE);
      expect({ width, grew: enlarged > design }).toEqual({ width, grew: true });
    }
  });

  it('is the same height whichever tab is selected, so one root measures every one of them', async () => {
    // Flutter's own clearance test was caught measuring a single tab; here selection moves only the tint.
    for (const width of [NARROW_WIDTH, WIDE_WIDTH]) {
      const heights = [];
      for (const item of smileIDSampleNavItems) {
        heights.push(await barHeight(width, ENLARGED_FONT_SCALE, item.id));
      }
      expect(new Set(heights).size).toBe(1);
    }
  });
});

describe('the gesture inset is inside the reserve exactly once', () => {
  it('carries the bottom inset in the bar itself, so a screen must not add it again', async () => {
    for (const width of [NARROW_WIDTH, WIDE_WIDTH]) {
      const withInset = layoutTree(await renderForLayout(bar(), {}), { width }).height;
      const without = layoutTree(await renderForLayout(bar(), { insets: { bottom: 0 } }), {
        width,
      }).height;
      expect({ width, difference: withInset - without }).toEqual({
        width,
        difference: PINNED_BOTTOM_INSET,
      });
    }
  });

});

describe('the bar keeps growing past the scale the predicate is written against', () => {
  it('is taller again at 3x, which iOS Dynamic Type reaches and a recorded number would not follow', async () => {
    // Only the growth is assertable here: whether a host's reserve tracks it is the shell's own test.
    for (const width of [NARROW_WIDTH, WIDE_WIDTH]) {
      const enlarged = await barHeight(width, ENLARGED_FONT_SCALE);
      expect({ width, grew: (await barHeight(width, 3)) > enlarged }).toEqual({ width, grew: true });
    }
  });
});

describe('a screen reserves exactly what its host passes, and nothing by itself', () => {
  // Comparing a reserve DERIVED from the bar against the bar proves only that a gap is positive, so
  // these assert the forwarding contract instead; whether the shipped reserve clears the bar is
  // expo/app/test/use-smile-id-sample-nav-bar-host.test.tsx, against the real hook.
  it.each(Object.keys(screens) as (keyof typeof screens)[])(
    'leaves the %s list running under the bar when the host passes nothing',
    async (screen) => {
      expect(await reservedBottom(screens[screen](), screenIds[screen])).toBe(0);
    },
  );

  it.each(Object.keys(screens) as (keyof typeof screens)[])(
    'forwards the host inset into the %s scroll content untouched',
    async (screen) => {
      expect(await reservedBottom(screens[screen](207), screenIds[screen])).toBe(207);
    },
  );
});
