import { useEffect, useRef, useState } from 'react';
import { Animated } from 'react-native';

import { SMILE_DURATION_FAST_MS, useSmileIDSampleReducedMotion } from './use-smile-id-sample-press-feedback';
import { smileMix } from '../theme/smile-color-math';

const HEX = /^#[0-9a-fA-F]{6}$/;

/// Blends an unpicked colour toward a picked one, returning each exactly at rest and snapping halfway when either is not `#RRGGBB`.
export const smileIDSampleSelectionColor = (from: string, to: string, picked: number): string => {
  if (picked <= 0) return from;
  if (picked >= 1) return to;
  if (!HEX.test(from) || !HEX.test(to)) return picked < 0.5 ? from : to;
  return smileMix(from, to, picked);
};

/// How far a picked state has eased in, 0 to 1 over duration-fast, instantly under reduced motion.
export const useSmileIDSampleSelectionBlend = (selected: boolean): number => {
  const reduced = useSmileIDSampleReducedMotion();
  const [value] = useState(() => new Animated.Value(selected ? 1 : 0));
  const [picked, setPicked] = useState(selected ? 1 : 0);

  useEffect(() => {
    const id = value.addListener(({ value: next }) => setPicked(next));
    return () => value.removeListener(id);
  }, [value]);

  const last = useRef(selected);
  useEffect(() => {
    const target = selected ? 1 : 0;
    const changed = selected !== last.current;
    last.current = selected;
    if (reduced || !changed) {
      value.setValue(target);
      return undefined;
    }
    const run = Animated.timing(value, { toValue: target, duration: SMILE_DURATION_FAST_MS, useNativeDriver: false });
    run.start();
    return () => run.stop();
  }, [selected, reduced, value]);

  return picked;
};
