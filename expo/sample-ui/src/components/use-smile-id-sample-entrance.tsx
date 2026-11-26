import { useEffect, useRef, useState, type ReactNode } from 'react';
import { Animated, Easing, type StyleProp, type ViewStyle } from 'react-native';

import { SMILE_DURATION_FAST_MS, useSmileIDSampleReducedMotion } from './use-smile-id-sample-press-feedback';

const RISE_MS = 220;
const FADE_SHARE_OF_RISE = 160 / 220;
const FAST_OUT_SLOW_IN = Easing.bezier(0.4, 0, 0.2, 1);

type Props = { children: ReactNode; style?: StyleProp<ViewStyle> };

/// Runs [progress] from 0 to 1 once on mount, unless reduced motion was asked for or not yet known then.
const useEntrance = (duration: number) => {
  const reduced = useSmileIDSampleReducedMotion();
  const [animates] = useState(!reduced);
  const [progress] = useState(() => new Animated.Value(animates ? 0 : 1));
  useEffect(() => {
    if (!animates) return undefined;
    const run = Animated.timing(progress, { toValue: 1, duration, easing: FAST_OUT_SLOW_IN, useNativeDriver: true });
    run.start();
    return () => run.stop();
  }, [animates, duration, progress]);
  return progress;
};

/// Content that rises its own height into place, fading in, when it first appears; the toast's own entrance.
export const UseSmileIDSampleRiseIn = ({ children, style }: Props) => {
  const progress = useEntrance(RISE_MS);
  const [height] = useState(() => new Animated.Value(0));
  return (
    <Animated.View
      onLayout={(event) => height.setValue(event.nativeEvent.layout.height)}
      style={[
        style,
        {
          opacity: progress.interpolate({ inputRange: [0, FADE_SHARE_OF_RISE, 1], outputRange: [0, 1, 1] }),
          transform: [{ translateY: Animated.multiply(Animated.subtract(1, progress), height) }],
        },
      ]}
    >
      {children}
    </Animated.View>
  );
};

/// Content that fades in over duration-fast when it first appears, as a list does when it replaces its loading state.
export const UseSmileIDSampleFadeIn = ({ children, style }: Props) => {
  const progress = useEntrance(SMILE_DURATION_FAST_MS);
  return <Animated.View style={[style, { opacity: progress }]}>{children}</Animated.View>;
};

/// An opacity that fades to [visible] over duration-fast on each change, and jumps under reduced motion.
export const useSmileIDSampleVisibilityFade = (visible: boolean): Animated.Value => {
  const reduced = useSmileIDSampleReducedMotion();
  const [opacity] = useState(() => new Animated.Value(visible ? 1 : 0));
  const shown = useRef(visible);
  useEffect(() => {
    const target = visible ? 1 : 0;
    const changed = visible !== shown.current;
    shown.current = visible;
    if (reduced || !changed) {
      opacity.setValue(target);
      return undefined;
    }
    const run = Animated.timing(opacity, { toValue: target, duration: SMILE_DURATION_FAST_MS, useNativeDriver: true });
    run.start();
    return () => run.stop();
  }, [visible, reduced, opacity]);
  return opacity;
};
