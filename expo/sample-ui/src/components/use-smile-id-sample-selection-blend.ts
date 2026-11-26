import { useEffect, useRef, useState } from 'react';
import { Animated } from 'react-native';

import { SMILE_DURATION_FAST_MS, useSmileIDSampleReducedMotion } from './use-smile-id-sample-press-feedback';

/// How far a picked state has eased in, 0 to 1 over duration-fast on each change, at once under reduced motion; [moving] while it eases.
export const useSmileIDSampleSelectionProgress = (selected: boolean): { progress: Animated.Value; moving: boolean } => {
  const reduced = useSmileIDSampleReducedMotion();
  const [progress] = useState(() => new Animated.Value(selected ? 1 : 0));
  const [settled, setSettled] = useState(selected);
  // Settled during render, as React advises for state derived from props: no animation will report it.
  if (reduced && settled !== selected) setSettled(selected);
  const last = useRef(selected);
  useEffect(() => {
    const target = selected ? 1 : 0;
    const changed = selected !== last.current;
    last.current = selected;
    if (reduced || !changed) {
      progress.setValue(target);
      return undefined;
    }
    const run = Animated.timing(progress, { toValue: target, duration: SMILE_DURATION_FAST_MS, useNativeDriver: true });
    run.start(() => setSettled(selected));
    return () => run.stop();
  }, [selected, reduced, progress]);
  return { progress, moving: !reduced && selected !== settled };
};

/// A colour that follows [progress] from [from] to [to], interpolated on the native driver rather than re-rendered.
export const smileIDSampleSelectionColor = (progress: Animated.Value, from: string, to: string) =>
  progress.interpolate({ inputRange: [0, 1], outputRange: [from, to] });
