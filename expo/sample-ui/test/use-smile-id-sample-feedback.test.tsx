import { act, fireEvent } from '@testing-library/react-native';
import { useState } from 'react';
import { AccessibilityInfo, Animated, StyleSheet } from 'react-native';

import {
  smileIDSamplePressOpacity,
  smileIDSamplePressScale,
  useSmileIDSampleReducedMotion,
} from '../src/components/use-smile-id-sample-press-feedback';
import { UseSmileIDSampleFilterChip } from '../src/components/use-smile-id-sample-filter-chip';
import { UseSmileIDSampleProductCard } from '../src/components/use-smile-id-sample-product-card';
import { smileIDSampleSelectionColor } from '../src/components/use-smile-id-sample-selection-blend';
import { smileMix } from '../src/theme/smile-color-math';
import { smileLightColors } from '../src/index';
import { smileIDSampleProductHue, smileIDSampleProducts } from '../src/model/use-smile-id-sample-product';
import { renderInTheme } from './render-in-theme';

const noop = () => {};

const card = (testID: string) => (
  <UseSmileIDSampleProductCard
    title="Document"
    family="Verification"
    hue={smileIDSampleProductHue(smileIDSampleProducts[0]!)}
    onPress={noop}
    testID={testID}
  />
);

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

  it('dims a held card under reduced motion instead of shrinking it', () => {
    expect(smileIDSamplePressOpacity(true, true, true)).toBe(0.7);
    expect(smileIDSamplePressOpacity(true, true, false)).toBe(1);
    expect(smileIDSamplePressOpacity(false, true, true)).toBe(1);
  });

  it('animates the card down while held and back on release', async () => {
    const timing = jest.spyOn(Animated, 'timing');
    try {
      const screen = await renderInTheme(card('card'), false);

      await act(async () => {
        fireEvent(screen.getByTestId('card'), 'pressIn');
      });
      await act(async () => {
        fireEvent(screen.getByTestId('card'), 'pressOut');
      });

      expect(timing.mock.calls.map(([, config]) => config.toValue)).toEqual([0.97, 1]);
    } finally {
      timing.mockRestore();
    }
  });

  it('asks the platform about reduced motion once for a whole grid', async () => {
    const listen = jest.spyOn(AccessibilityInfo, 'addEventListener');
    try {
      await renderInTheme(
        <>
          {card('first')}
          {card('second')}
          {card('third')}
        </>,
        false,
      );

      expect(listen.mock.calls.filter(([event]) => event === 'reduceMotionChanged')).toHaveLength(1);
    } finally {
      listen.mockRestore();
    }
  });
});

describe('the reduced-motion reading', () => {
  it('keeps a change that lands before the first answer', async () => {
    let answer: (value: boolean) => void = noop;
    let change: (value: boolean) => void = noop;
    const ask = jest
      .spyOn(AccessibilityInfo, 'isReduceMotionEnabled')
      .mockReturnValue(new Promise<boolean>((resolve) => (answer = resolve)));
    const listen = jest.spyOn(AccessibilityInfo, 'addEventListener').mockImplementation((_event, handler) => {
      change = handler as (value: boolean) => void;
      return { remove: noop } as ReturnType<typeof AccessibilityInfo.addEventListener>;
    });
    try {
      const seen: boolean[] = [];
      const Probe = () => {
        seen.push(useSmileIDSampleReducedMotion());
        return null;
      };
      await renderInTheme(<Probe />, false);

      await act(async () => change(false));
      await act(async () => answer(true));

      expect(seen.at(-1)).toBe(false);
    } finally {
      ask.mockRestore();
      listen.mockRestore();
    }
  });
});

describe('a picked colour', () => {
  const chip = (selected: boolean) => (
    <UseSmileIDSampleFilterChip label="Clear" count={2} selected={selected} onPress={noop} testID="chip" />
  );
  const fillOf = (screen: Awaited<ReturnType<typeof renderInTheme>>) => {
    const pill = screen.getByTestId('chip').children[0] as unknown as { props: { style: unknown } };
    return (StyleSheet.flatten(pill.props.style as never) as { backgroundColor?: string }).backgroundColor;
  };

  it('eases a chip into its picked fill instead of snapping', async () => {
    jest.useFakeTimers();
    const ask = jest.spyOn(AccessibilityInfo, 'isReduceMotionEnabled').mockResolvedValue(false);
    const listen = jest
      .spyOn(AccessibilityInfo, 'addEventListener')
      .mockReturnValue({ remove: noop } as ReturnType<typeof AccessibilityInfo.addEventListener>);
    try {
      let pick = noop;
      const Host = () => {
        const [selected, setSelected] = useState(false);
        pick = () => setSelected(true);
        return chip(selected);
      };
      const screen = await renderInTheme(<Host />, false);
      await act(async () => {
        await Promise.resolve();
      });
      const resting = fillOf(screen);
      await act(async () => {
        pick();
      });
      await act(async () => {
        jest.advanceTimersByTime(100);
      });
      const midway = fillOf(screen);
      await act(async () => {
        jest.advanceTimersByTime(1_000);
      });

      expect(midway).not.toBe(resting);
      expect(midway).not.toBe(fillOf(screen));
      expect(fillOf(screen)).toBe(smileLightColors.primary);
    } finally {
      ask.mockRestore();
      listen.mockRestore();
      jest.useRealTimers();
    }
  });

  const { primary, onPrimary } = smileLightColors;

  it('blends two colours and returns the exact ends at rest', () => {
    expect(smileIDSampleSelectionColor(onPrimary, primary, 0)).toBe(onPrimary);
    expect(smileIDSampleSelectionColor(onPrimary, primary, 1)).toBe(primary);
    expect(smileIDSampleSelectionColor(onPrimary, primary, 0.5)).toBe(smileMix(onPrimary, primary, 0.5));
  });

  it('snaps colours it cannot blend at the halfway point', () => {
    const translucent = 'rgba(0, 0, 0, 0.5)';
    expect(smileIDSampleSelectionColor(translucent, primary, 0.4)).toBe(translucent);
    expect(smileIDSampleSelectionColor(translucent, primary, 0.6)).toBe(primary);
  });
});
