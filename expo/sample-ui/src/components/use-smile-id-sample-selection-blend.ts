import { useEffect, useRef, useState } from 'react';
import { Animated } from 'react-native';

import { SMILE_DURATION_FAST_MS, useSmileIDSampleReducedMotion } from './use-smile-id-sample-press-feedback';

/// How far a picked state has eased in, 0 to 1 over duration-fast on each change, at once under reduced motion; [moving] while it eases.
export const useSmileIDSampleSelectionProgress = (selected: boolean): { progress: Animated.Value; moving: boolean } => {
  const reduced = useSmileIDSampleReducedMotion();
  const [progress] = useState(() => new Animated.Value(selected ? 1 : 0));
  // Derived during render, as React advises: easing from the change of [selected] until an ease finishes.
  const [prevSelected, setPrevSelected] = useState(selected);
  const [easing, setEasing] = useState(false);
  if (selected !== prevSelected) {
    setPrevSelected(selected);
    setEasing(!reduced);
  }
  if (reduced && easing) setEasing(false);
  const last = useRef(selected);
  useEffect(() => {
    const target = selected ? 1 : 0;
    const changed = selected !== last.current;
    last.current = selected;
    if (reduced || !changed) {
      progress.setValue(target);
      return undefined;
    }
    const run = Animated.timing(progress, { toValue: target, duration: SMILE_DURATION_FAST_MS, useNativeDriver: false });
    run.start(({ finished }) => {
      if (finished) setEasing(false);
    });
    return () => run.stop();
  }, [selected, reduced, progress]);
  return { progress, moving: easing };
};

/// A colour that follows [progress] from [from] to [to], interpolated by Animated rather than re-rendered; JS-driven, as Android ignores a native-driven text colour.
export const smileIDSampleSelectionColor = (progress: Animated.Value, from: string, to: string) =>
  progress.interpolate({ inputRange: [0, 1], outputRange: [from, to] });
