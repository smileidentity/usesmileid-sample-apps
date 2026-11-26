import { act, fireEvent } from '@testing-library/react-native';
import { useState, type ReactElement } from 'react';
import { AccessibilityInfo, Animated, StyleSheet, Text } from 'react-native';

import {
  smileIDSamplePressOpacity,
  smileIDSamplePressScale,
  UseSmileIDSampleReducedMotionOverride,
  useSmileIDSampleReducedMotion,
} from '../src/components/use-smile-id-sample-press-feedback';
import { UseSmileIDSampleFilterChip } from '../src/components/use-smile-id-sample-filter-chip';
import { UseSmileIDSampleProductCard } from '../src/components/use-smile-id-sample-product-card';
import {
  UseSmileIDSampleFadeIn,
  UseSmileIDSampleRiseIn,
  useSmileIDSampleVisibilityFade,
} from '../src/components/use-smile-id-sample-entrance';
import { tokens } from '../src/tokens';
import { smileLightColors } from '../src/index';
import { smileIDSampleProductHue, smileIDSampleProducts } from '../src/model/use-smile-id-sample-product';
import { renderInTheme } from './render-in-theme';

/// Renders with the platform's reduced-motion answer, which each test here mocks, instead of the goldens' pinned one.
const renderLive = (element: ReactElement, dark: boolean) =>
  renderInTheme(
    <UseSmileIDSampleReducedMotionOverride.Provider value={undefined}>{element}</UseSmileIDSampleReducedMotionOverride.Provider>,
    dark,
  );

const noop = () => {};

/// A colour's red, green and blue, whether written as `#RRGGBB` or as the `rgba()` Animated interpolates to.
const rgb = (colour: string | undefined): number[] => {
  const text = String(colour);
  const hex = /^#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i.exec(text);
  if (hex) return hex.slice(1).map((part) => Number.parseInt(part, 16));
  return (text.match(/[\d.]+/g) ?? []).slice(0, 3).map(Number);
};

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
      const screen = await renderLive(card('card'), false);

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
      await renderLive(
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
      await renderLive(<Probe />, false);

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
      const screen = await renderLive(<Host />, false);
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

      expect(rgb(midway)).not.toEqual(rgb(resting));
      expect(rgb(midway)).not.toEqual(rgb(fillOf(screen)));
      expect(rgb(fillOf(screen))).toEqual(rgb(smileLightColors.primary));
    } finally {
      ask.mockRestore();
      listen.mockRestore();
      jest.useRealTimers();
    }
  });

});

describe('an entrance', () => {
  const settle = async () => {
    await act(async () => {
      await Promise.resolve();
    });
  };

  const mountLater = async (child: React.ReactElement, reduced: boolean) => {
    const ask = jest.spyOn(AccessibilityInfo, 'isReduceMotionEnabled').mockResolvedValue(reduced);
    const listen = jest
      .spyOn(AccessibilityInfo, 'addEventListener')
      .mockReturnValue({ remove: noop } as ReturnType<typeof AccessibilityInfo.addEventListener>);
    const timing = jest.spyOn(Animated, 'timing');
    let show = noop;
    const Host = () => {
      const [shown, setShown] = useState(false);
      show = () => setShown(true);
      return (
        <>
          <UseSmileIDSampleProductCard
            title="Document"
            family="Verification"
            hue={smileIDSampleProductHue(smileIDSampleProducts[0]!)}
            onPress={noop}
          />
          {shown ? child : null}
        </>
      );
    };
    await renderLive(<Host />, false);
    await settle();
    timing.mockClear();
    await act(async () => {
      show();
    });
    const durations = timing.mock.calls.map(([, config]) => config.duration);
    ask.mockRestore();
    listen.mockRestore();
    timing.mockRestore();
    return durations;
  };

  it('rises a bar in over the toast entrance', async () => {
    expect(await mountLater(<UseSmileIDSampleRiseIn><Text>bar</Text></UseSmileIDSampleRiseIn>, false)).toEqual([220]);
  });

  it('puts a bar straight in place under reduced motion', async () => {
    expect(await mountLater(<UseSmileIDSampleRiseIn><Text>bar</Text></UseSmileIDSampleRiseIn>, true)).toEqual([]);
  });

  it('fades content in over the fast duration', async () => {
    expect(await mountLater(<UseSmileIDSampleFadeIn><Text>rows</Text></UseSmileIDSampleFadeIn>, false)).toEqual([
      Number.parseFloat(tokens.duration.fast),
    ]);
  });
});

describe('a fade on change', () => {
  it('fades Select in when there is something to pick', async () => {
    const ask = jest.spyOn(AccessibilityInfo, 'isReduceMotionEnabled').mockResolvedValue(false);
    const listen = jest
      .spyOn(AccessibilityInfo, 'addEventListener')
      .mockReturnValue({ remove: noop } as ReturnType<typeof AccessibilityInfo.addEventListener>);
    const timing = jest.spyOn(Animated, 'timing');
    try {
      let reveal = noop;
      const Probe = () => {
        const [visible, setVisible] = useState(false);
        reveal = () => setVisible(true);
        const opacity = useSmileIDSampleVisibilityFade(visible);
        return <Animated.View style={{ opacity }} />;
      };
      await renderLive(<Probe />, false);
      await act(async () => {
        await Promise.resolve();
      });
      timing.mockClear();
      await act(async () => {
        reveal();
      });

      expect(timing.mock.calls.map(([, config]) => [config.toValue, config.duration])).toEqual([
        [1, Number.parseFloat(tokens.duration.fast)],
      ]);
    } finally {
      ask.mockRestore();
      listen.mockRestore();
      timing.mockRestore();
    }
  });
});
