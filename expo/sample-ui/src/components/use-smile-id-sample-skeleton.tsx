import { useEffect, useRef, useState } from 'react';
import { AccessibilityInfo, Animated, StyleSheet, View } from 'react-native';

import { tokens } from '../tokens';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

/// Rows show only after this long, so a fast answer never flashes a skeleton.
export const SKELETON_DELAY_MS = 300;

/// Once shown, rows stay at least this long.
export const SKELETON_MINIMUM_MS = 400;

/// One pulse, from the design system's `skeleton.duration`.
const PULSE_MS = Number.parseFloat(tokens.skeleton.duration);

/// Six widths so the rows do not read as a table.
const WIDTHS = ['72%', '48%', '64%', '56%', '80%', '40%'] as const;

/// Where a country row's flag goes.
const FLAG_SIZE = 19;

/// The bar a text line becomes.
const BAR_HEIGHT = 12;

/// Whether the rows draw for a list whose loading state is `loading`, under the 300 ms delay and 400 ms minimum.
export const useSmileIDSampleSkeletonGate = (loading: boolean, now: () => number = Date.now): boolean => {
  const [visible, setVisible] = useState(false);
  const shownAt = useRef<number | null>(null);

  useEffect(() => {
    let timer: ReturnType<typeof setTimeout> | undefined;
    if (loading && !visible) {
      timer = setTimeout(() => {
        shownAt.current = now();
        setVisible(true);
      }, SKELETON_DELAY_MS);
    } else if (!loading && visible) {
      const left = SKELETON_MINIMUM_MS - (now() - (shownAt.current ?? 0));
      if (left > 0) timer = setTimeout(() => setVisible(false), left);
      else setVisible(false);
    }
    return () => clearTimeout(timer);
  }, [loading, visible, now]);

  return visible;
};

type Props = {
  /// What a screen reader hears, e.g. "Loading countries".
  announcement: string;
  leadingCircle?: boolean;
  testID?: string;
};

/// Six OptionRow-shaped placeholders; one element to accessibility, still under reduced motion.
export const UseSmileIDSampleSkeletonRows = ({ announcement, leadingCircle = false, testID }: Props) => {
  const theme = useSmileIDSampleTheme();
  const [pulse] = useState(() => new Animated.Value(0));

  useEffect(() => {
    let loop: Animated.CompositeAnimation | undefined;
    let cancelled = false;
    void AccessibilityInfo.isReduceMotionEnabled().then((reduced) => {
      if (cancelled || reduced) return;
      loop = Animated.loop(
        Animated.sequence([
          Animated.timing(pulse, {
            toValue: 1,
            duration: PULSE_MS,
            useNativeDriver: false,
          }),
          Animated.timing(pulse, {
            toValue: 0,
            duration: PULSE_MS,
            useNativeDriver: false,
          }),
        ]),
      );
      loop.start();
    });
    return () => {
      cancelled = true;
      loop?.stop();
    };
  }, [pulse]);

  const fill = pulse.interpolate({
    inputRange: [0, 1],
    outputRange: [theme.colors.skeleton, theme.colors.skeletonHighlight],
  });

  return (
    <View testID={testID} accessible accessibilityLabel={announcement}>
      {WIDTHS.map((width) => (
        <View
          key={width}
          style={[
            styles.row,
            {
              minHeight: theme.dimens.size['control-md'],
              paddingHorizontal: theme.dimens.spacing.sm,
              columnGap: theme.dimens.spacing.sm,
            },
          ]}
        >
          {leadingCircle ? (
            <Animated.View
              style={{
                width: FLAG_SIZE,
                height: FLAG_SIZE,
                borderRadius: FLAG_SIZE / 2,
                backgroundColor: fill,
              }}
            />
          ) : null}
          <View style={styles.barColumn}>
            <Animated.View
              style={{
                width: width,
                height: BAR_HEIGHT,
                borderRadius: theme.dimens.radius.field,
                backgroundColor: fill,
              }}
            />
          </View>
        </View>
      ))}
    </View>
  );
};

const styles = StyleSheet.create({
  row: { alignItems: 'center', flexDirection: 'row', width: '100%' },
  barColumn: { flex: 1 },
});
