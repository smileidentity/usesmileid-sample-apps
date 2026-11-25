import { act, fireEvent } from '@testing-library/react-native';
import type { ReactElement } from 'react';
import { Animated } from 'react-native';

import { UseSmileIDSampleFilterChip } from '../src/components/use-smile-id-sample-filter-chip';
import {
  UseSmileIDSampleHapticsContext,
  smileIDSamplePressScale,
  type UseSmileIDSampleHaptics,
} from '../src/components/use-smile-id-sample-press-feedback';
import { UseSmileIDSampleNavBar } from '../src/components/use-smile-id-sample-nav-bar';
import { UseSmileIDSampleProductCard } from '../src/components/use-smile-id-sample-product-card';
import { UseSmileIDSampleSwitch } from '../src/components/use-smile-id-sample-switch';
import { smileIDSampleProductHue, smileIDSampleProducts } from '../src/model/use-smile-id-sample-product';
import { UseSmileIDSampleTestIds } from '../src/use-smile-id-sample-test-ids';
import { renderInTheme } from './render-in-theme';

const recorder = () => {
  const played: string[] = [];
  const haptics: UseSmileIDSampleHaptics = {
    selection: () => played.push('selection'),
    toggle: (on) => played.push(on ? 'toggle-on' : 'toggle-off'),
  };
  return { played, haptics };
};

const withHaptics = (haptics: UseSmileIDSampleHaptics, element: ReactElement) => (
  <UseSmileIDSampleHapticsContext.Provider value={haptics}>{element}</UseSmileIDSampleHapticsContext.Provider>
);

const noop = () => {};

describe('a product card press', () => {
  it('shrinks a held card to 0.97', () => {
    expect(smileIDSamplePressScale(true, true, false)).toBe(0.97);
  });

  it('keeps a card at rest at full size', () => {
    expect(smileIDSamplePressScale(false, true, false)).toBe(1);
  });

  it('leaves a disabled card at full size', () => {
    expect(smileIDSamplePressScale(true, false, false)).toBe(1);
  });

  it('leaves a card at full size under reduced motion', () => {
    expect(smileIDSamplePressScale(true, true, true)).toBe(1);
  });

  it('animates the card down while held and back on release', async () => {
    const timing = jest.spyOn(Animated, 'timing');
    const screen = await renderInTheme(
      <UseSmileIDSampleProductCard
        title="Document"
        family="Verification"
        hue={smileIDSampleProductHue(smileIDSampleProducts[0]!)}
        onPress={noop}
        testID="card"
      />,
      false,
    );
    const targets = () => timing.mock.calls.map(([, config]) => config.toValue);

    await act(async () => {
      fireEvent(screen.getByTestId('card'), 'pressIn');
    });
    await act(async () => {
      fireEvent(screen.getByTestId('card'), 'pressOut');
    });

    expect(targets()).toEqual([0.97, 1]);
    timing.mockRestore();
  });
});

describe('a selection tick', () => {
  it('plays once when another chip is picked', async () => {
    const { played, haptics } = recorder();
    const screen = await renderInTheme(
      withHaptics(haptics, <UseSmileIDSampleFilterChip label="Failed" count={2} selected={false} onPress={noop} testID="chip" />),
      false,
    );

    await fireEvent.press(screen.getByTestId('chip'));

    expect(played).toEqual(['selection']);
  });

  it('stays quiet when the chip already picked is tapped', async () => {
    const { played, haptics } = recorder();
    const screen = await renderInTheme(
      withHaptics(haptics, <UseSmileIDSampleFilterChip label="All" count={4} selected onPress={noop} testID="chip" />),
      false,
    );

    await fireEvent.press(screen.getByTestId('chip'));

    expect(played).toEqual([]);
  });

  it('plays once when another tab is opened', async () => {
    const { played, haptics } = recorder();
    const screen = await renderInTheme(
      withHaptics(haptics, <UseSmileIDSampleNavBar selectedId="products" onSelect={noop} onTokenPress={noop} />),
      false,
    );

    await fireEvent.press(screen.getByTestId(UseSmileIDSampleTestIds.NAV_VERIFICATIONS));

    expect(played).toEqual(['selection']);
  });

  it('stays quiet when the open tab is tapped', async () => {
    const { played, haptics } = recorder();
    const screen = await renderInTheme(
      withHaptics(haptics, <UseSmileIDSampleNavBar selectedId="products" onSelect={noop} onTokenPress={noop} />),
      false,
    );

    await fireEvent.press(screen.getByTestId(UseSmileIDSampleTestIds.NAV_PRODUCTS));

    expect(played).toEqual([]);
  });

  it('leaves the iOS switch to UISwitch, which ticks on its own', async () => {
    const { played, haptics } = recorder();
    const screen = await renderInTheme(
      withHaptics(haptics, <UseSmileIDSampleSwitch checked={false} onCheckedChange={noop} testID="switch" />),
      false,
    );

    await fireEvent(screen.getByTestId('switch'), 'valueChange', true);

    expect(played).toEqual([]);
  });
});
