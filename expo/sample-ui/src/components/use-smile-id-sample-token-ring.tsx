import { StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';
import Svg, { Circle } from 'react-native-svg';

import { smileTokenRing, smileTokenRingTrackOpacity } from '../smile-product-hues';
import { smileWithAlpha } from '../theme/smile-color-math';

const RING_THICKNESS = 4;

type Props = {
  /// 1 is a fresh session and 0 expired, driven by remaining time against an absolute deadline.
  progress: number;
  size: number;
  style?: StyleProp<ViewStyle>;
};

/// The countdown ring: green rather than primary, and driven by remaining time rather than a fixed duration.
export const UseSmileIDSampleTokenRing = ({ progress, size, style }: Props) => {
  const clamped = Math.min(Math.max(progress, 0), 1);
  const radius = (size - RING_THICKNESS) / 2;
  const circumference = 2 * Math.PI * radius;

  return (
    <View style={[{ width: size, height: size }, style]} pointerEvents="none">
      <Svg width={size} height={size}>
        <Circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          stroke={smileWithAlpha(smileTokenRing, smileTokenRingTrackOpacity)}
          strokeWidth={RING_THICKNESS}
          fill="none"
        />
        <Circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          stroke={smileTokenRing}
          strokeWidth={RING_THICKNESS}
          strokeLinecap="round"
          fill="none"
          strokeDasharray={`${circumference} ${circumference}`}
          strokeDashoffset={circumference * (1 - clamped)}
          // Starts at twelve o'clock and sweeps clockwise, which a dash offset alone does not do.
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
        />
      </Svg>
    </View>
  );
};

export const smileTokenRingThickness = RING_THICKNESS;

export const smileTokenRingStyles = StyleSheet.create({
  behind: { position: 'absolute' },
});
