import { act, fireEvent } from '@testing-library/react-native';
import { AccessibilityInfo, Animated } from 'react-native';

import {
  smileIDSamplePressOpacity,
  smileIDSamplePressScale,
  useSmileIDSampleReducedMotion,
} from '../src/components/use-smile-id-sample-press-feedback';
import { UseSmileIDSampleProductCard } from '../src/components/use-smile-id-sample-product-card';
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
