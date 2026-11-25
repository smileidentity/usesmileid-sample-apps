import { createContext, useEffect, useState } from 'react';
import { AccessibilityInfo } from 'react-native';

/// The ticks the sample plays, which the app supplies because sample-ui ships no native code.
export type UseSmileIDSampleHaptics = {
  selection: () => void;
  toggle: (on: boolean) => void;
};

/// Silent until the app provides its haptics.
export const UseSmileIDSampleHapticsContext = createContext<UseSmileIDSampleHaptics>({
  selection: () => {},
  toggle: () => {},
});

/// The scale a product card draws at: smaller while held, unless it is disabled or motion is reduced.
export const smileIDSamplePressScale = (pressed: boolean, enabled: boolean, reduceMotion: boolean): number =>
  pressed && enabled && !reduceMotion ? PRESSED_SCALE : 1;

/// Whether the platform asks for reduced motion, kept current while the screen is up.
export const useSmileIDSampleReducedMotion = (): boolean => {
  const [reduced, setReduced] = useState(false);
  useEffect(() => {
    let live = true;
    void AccessibilityInfo.isReduceMotionEnabled().then((value) => {
      if (live) setReduced(value);
    });
    const subscription = AccessibilityInfo.addEventListener('reduceMotionChanged', setReduced);
    return () => {
      live = false;
      subscription.remove();
    };
  }, []);
  return reduced;
};

const PRESSED_SCALE = 0.97;
