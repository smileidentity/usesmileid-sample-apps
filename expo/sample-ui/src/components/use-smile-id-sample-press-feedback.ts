import { useSyncExternalStore } from 'react';
import { AccessibilityInfo } from 'react-native';

/// The scale a product card draws at: smaller while held, unless it is disabled or motion is reduced.
export const smileIDSamplePressScale = (pressed: boolean, enabled: boolean, reduceMotion: boolean): number =>
  pressed && enabled && !reduceMotion ? PRESSED_SCALE : 1;

/// Reduced motion as last read; null only before the platform's first answer, which readers treat as reduced.
let reducedMotion: boolean | null = null;
const listeners = new Set<() => void>();
let stopWatching: (() => void) | null = null;

const publish = (value: boolean) => {
  reducedMotion = value;
  listeners.forEach((listener) => listener());
};

/// One platform query and one listener however many components read it, dropped with the last reader.
const subscribe = (listener: () => void) => {
  listeners.add(listener);
  if (stopWatching === null) {
    let live = true;
    let changed = false;
    void AccessibilityInfo.isReduceMotionEnabled().then((value) => {
      if (live && !changed) publish(value);
    });
    const subscription = AccessibilityInfo.addEventListener('reduceMotionChanged', (value) => {
      changed = true;
      publish(value);
    });
    stopWatching = () => {
      live = false;
      subscription.remove();
    };
  }
  return () => {
    listeners.delete(listener);
    if (listeners.size === 0) {
      stopWatching?.();
      stopWatching = null;
    }
  };
};

/// Whether the platform asks for reduced motion, kept current while the screen is up.
export const useSmileIDSampleReducedMotion = (): boolean =>
  useSyncExternalStore(subscribe, () => reducedMotion !== false);

/// The opacity a held card draws at when reduced motion stops the scale, so a press still shows.
export const smileIDSamplePressOpacity = (pressed: boolean, enabled: boolean, reduceMotion: boolean): number =>
  pressed && enabled && reduceMotion ? REDUCED_MOTION_PRESSED_OPACITY : 1;

const PRESSED_SCALE = 0.97;
const REDUCED_MOTION_PRESSED_OPACITY = 0.7;
