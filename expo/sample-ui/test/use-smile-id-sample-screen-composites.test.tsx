
import { UseSmileIDSampleFloatingTokenButton } from '../src/components/use-smile-id-sample-floating-token-button';
import { UseSmileIDSampleIcon } from '../src/components/use-smile-id-sample-icon';
import { UseSmileIDSampleJobRow } from '../src/components/use-smile-id-sample-job-row';
import { UseSmileIDSampleNavBar } from '../src/components/use-smile-id-sample-nav-bar';
import { UseSmileIDSampleProductCard } from '../src/components/use-smile-id-sample-product-card';
import { UseSmileIDSampleProductGrid } from '../src/components/use-smile-id-sample-product-grid';
import { UseSmileIDSampleScanGlyph } from '../src/components/use-smile-id-sample-scan-glyph';
import { UseSmileIDSampleScanSheet } from '../src/components/use-smile-id-sample-scan-sheet';
import { UseSmileIDSampleSectionHeader } from '../src/components/use-smile-id-sample-section-header';
import { UseSmileIDSampleSessionCard } from '../src/components/use-smile-id-sample-session-card';
import { UseSmileIDSampleSessionEndedBanner } from '../src/components/use-smile-id-sample-session-ended-banner';
import { UseSmileIDSampleSwipeAction } from '../src/components/use-smile-id-sample-swipe-action';
import { UseSmileIDSampleTokenRing } from '../src/components/use-smile-id-sample-token-ring';
import { smileIDSampleNavItems } from '../src/model/use-smile-id-sample-nav-item';
import {
  smileIDSampleProductHue,
  smileIDSampleProductIcon,
  smileIDSampleProducts,
} from '../src/model/use-smile-id-sample-product';
import { UseSmileIDSampleStatus } from '../src/model/use-smile-id-sample-status';
import { UseSmileIDSampleTestIds } from '../src/use-smile-id-sample-test-ids';
import { renderInTheme, schemes, styleTree } from './render-in-theme';
import { expectGoldens } from './paint/pixel-golden';

const noop = () => {};

const card = (index: number) => {
  const product = smileIDSampleProducts[index]!;
  return (
    <UseSmileIDSampleProductCard
      title={product.cardTitle}
      family={product.cardFamily}
      onPress={noop}
      hue={smileIDSampleProductHue(product)}
      icon={(tint) => <UseSmileIDSampleIcon name={smileIDSampleProductIcon(product)} tint={tint} />}
      ghost={(tint) => <UseSmileIDSampleIcon name={smileIDSampleProductIcon(product)} tint={tint} size={69} />}
    />
  );
};

type Case = { element: () => React.ReactElement };

/// Every state each screen composite declares in spec/components.json.
const cases: { component: string; states: Record<string, Case> }[] = [
  {
    component: 'ProductCard',
    states: {
      // The first two hues are fully opaque and must match across schemes; the rest composite.
      registration: { element: () => card(0) },
      auth: { element: () => card(1) },
      // The worst case for the max-font-scale predicate: a shortened title plus a family line.
      enhancedDocument: { element: () => card(3) },
      disabled: {
        element: () => (
          <UseSmileIDSampleProductCard
            title="Enhanced"
            family="KYC"
            onPress={noop}
            hue={smileIDSampleProductHue(smileIDSampleProducts[5]!)}
            enabled={false}
          />
        ),
      },
    },
  },
  {
    component: 'ProductGrid',
    states: {
      evenCount: { element: () => <UseSmileIDSampleProductGrid cells={[card(0), card(1)]} /> },
      // An odd count leaves a blank slot, which is a layout affordance rather than a placeholder card.
      oddCount: { element: () => <UseSmileIDSampleProductGrid cells={[card(0)]} /> },
    },
  },
  {
    component: 'SectionHeader',
    states: { default: { element: () => <UseSmileIDSampleSectionHeader text="Authentication" /> } },
  },
  {
    component: 'NavBar',
    states: {
      products: {
        element: () => (
          <UseSmileIDSampleNavBar selectedId="products" onSelect={noop} onTokenPress={noop} />
        ),
      },
      settings: {
        element: () => (
          <UseSmileIDSampleNavBar selectedId="settings" onSelect={noop} onTokenPress={noop} />
        ),
      },
      withSessionRing: {
        element: () => (
          <UseSmileIDSampleNavBar
            selectedId="products"
            onSelect={noop}
            onTokenPress={noop}
            sessionProgress={0.6}
          />
        ),
      },
    },
  },
  {
    component: 'TokenRing',
    states: {
      fresh: { element: () => <UseSmileIDSampleTokenRing progress={1} size={68} /> },
      counting: { element: () => <UseSmileIDSampleTokenRing progress={0.45} size={68} /> },
      expired: { element: () => <UseSmileIDSampleTokenRing progress={0} size={68} /> },
    },
  },
  {
    component: 'SessionCard',
    states: {
      default: { element: () => <UseSmileIDSampleSessionCard sessionId="a41f" remaining="7:42" /> },
    },
  },
  {
    component: 'SessionEndedBanner',
    states: { default: { element: () => <UseSmileIDSampleSessionEndedBanner onScan={noop} /> } },
  },
  {
    component: 'FloatingTokenButton',
    states: { default: { element: () => <UseSmileIDSampleFloatingTokenButton onPress={noop} /> } },
  },
  {
    component: 'ScanGlyph',
    states: { default: { element: () => <UseSmileIDSampleScanGlyph size={256} /> } },
  },
  {
    component: 'ScanSheet',
    states: { default: { element: () => <UseSmileIDSampleScanSheet onPaste={noop} onSimulate={noop} /> } },
  },
  {
    component: 'SwipeAction',
    states: {
      closed: {
        element: () => (
          <UseSmileIDSampleSwipeAction onAction={noop}>
            <UseSmileIDSampleJobRow
              product={smileIDSampleProducts[0]!}
              jobId="7d2f01aa…"
              time="13:03:41"
              status={UseSmileIDSampleStatus.Clear}
            />
          </UseSmileIDSampleSwipeAction>
        ),
      },
    },
  },
];

describe.each(cases)('$component', ({ states }) => {
  describe.each(schemes)('$name', ({ dark }) => {
    it.each(Object.keys(states))('%s', async (state) => {
      await expectGoldens(states[state]!.element(), dark);
    });
  });
});

describe('screen-composite coverage', () => {
  it('covers every screen composite the buildOrder names', () => {
    expect(cases.map((entry) => entry.component)).toEqual([
      'ProductCard',
      'ProductGrid',
      'SectionHeader',
      'NavBar',
      'TokenRing',
      'SessionCard',
      'SessionEndedBanner',
      'FloatingTokenButton',
      'ScanGlyph',
      'ScanSheet',
      'SwipeAction',
    ]);
  });

  it('records both schemes for every state', () => {
    const total = cases.reduce((sum, entry) => sum + Object.keys(entry.states).length, 0);
    expect(total * schemes.length).toBe(38);
  });
});

describe('the product card', () => {
  it('brings a gradient stop drawn past the edge back inside it', async () => {
    // An SVG stop must land in 0..1, and the design runs the outer stop to 129%.
    const hue = smileIDSampleProductHue(smileIDSampleProducts[0]!);
    expect(hue.stopEnd).toBeGreaterThan(1);
    const tree = JSON.stringify(await styleTree(card(0), false));
    const offsets = [...tree.matchAll(/"offset":([\d.]+)/g)].map((m) => Number(m[1]));
    expect(offsets.filter((o) => o > 1)).toEqual([]);
  });

  it('paints an opaque hue identically in both schemes, and moves only its stroke', async () => {
    const opaque = smileIDSampleProductHue(smileIDSampleProducts[1]!);
    expect([opaque.fromAlpha, opaque.toAlpha]).toEqual([1, 1]);

    const light = JSON.stringify(await styleTree(card(1), false));
    const dark = JSON.stringify(await styleTree(card(1), true));
    // The hairline is the cardStroke pair and is meant to move; everything the hue paints is not.
    const withoutStroke = (tree: string) => tree.replace(/"borderColor":"#[0-9a-f]{6}"/g, '');
    expect(withoutStroke(light)).toEqual(withoutStroke(dark));
    expect(light).not.toEqual(dark);
  });

  it('leaves exactly two of the six hues fully opaque, and those are the ones that must match', () => {
    // A light/dark diff bigger than a stroke is correct on the four that composite against the page.
    const opaque = smileIDSampleProducts
      .map((product) => ({ id: product.id, hue: smileIDSampleProductHue(product) }))
      .filter(({ hue }) => hue.fromAlpha === 1 && hue.toAlpha === 1)
      .map(({ id }) => id);
    expect(opaque).toEqual(['smartSelfieAuth', 'biometricKyc']);
  });

  it('adapts the go pill rather than fixing it, which would leave it invisible on the darkest card', async () => {
    const one = JSON.stringify(await styleTree(card(0), false));
    const two = JSON.stringify(await styleTree(card(3), false));
    expect(one).not.toEqual(two);
  });
});

describe('the nav bar', () => {
  it('carries every nav id itself, because a custom bar gets no tabBarButtonTestID', async () => {
    const rendered = await renderInTheme(
      <UseSmileIDSampleNavBar selectedId="products" onSelect={noop} onTokenPress={noop} />,
      false,
    );
    const reached = [...smileIDSampleNavItems.map((item) => item.testID), UseSmileIDSampleTestIds.NAV_TOKEN];
    expect(reached.filter((id) => rendered.queryByTestId(id) === null)).toEqual([]);
  });

  it('marks only the selected tab as selected, which is what drives the tint', async () => {
    const rendered = await renderInTheme(
      <UseSmileIDSampleNavBar selectedId="settings" onSelect={noop} onTokenPress={noop} />,
      false,
    );
    const selected = smileIDSampleNavItems.filter(
      (item) => rendered.getByTestId(item.testID).props.accessibilityState?.selected === true,
    );
    expect(selected.map((item) => item.id)).toEqual(['settings']);
  });

  it('draws an icon above every label, which is the trap a port falls into', async () => {
    const tree = JSON.stringify(await styleTree(
      <UseSmileIDSampleNavBar selectedId="products" onSelect={noop} onTokenPress={noop} />,
      false,
    ));
    // Three tab marks plus the token mark: a text-only bar would carry none.
    expect((tree.match(/RNSVGSvgView/g) ?? []).length).toBe(4);
  });

  it('carries the ring only when a session is live', async () => {
    const without = JSON.stringify(await styleTree(
      <UseSmileIDSampleNavBar selectedId="products" onSelect={noop} onTokenPress={noop} />,
      false,
    ));
    const with_ = JSON.stringify(await styleTree(
      <UseSmileIDSampleNavBar
        selectedId="products"
        onSelect={noop}
        onTokenPress={noop}
        sessionProgress={0.6}
      />,
      false,
    ));
    expect((with_.match(/RNSVGSvgView/g) ?? []).length).toBe(5);
    expect(with_.length).toBeGreaterThan(without.length);
  });
});
