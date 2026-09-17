import { PixelRatio, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';

import { smileProfileHues } from '../smile-product-hues';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

/// The design draws a rounded square at 12, not the circle `avatar.radius` carries — node 5206:2904.
const AVATAR_RADIUS = 12;

type Props = {
  initials: string;
  size?: number;
  containerColor?: string;
  testID?: string;
  style?: StyleProp<ViewStyle>;
};

/// Initials in a rounded square, or a placeholder without them. The size scales with the font scale, because wrapping the initials renders an ellipse at 2x.
export const UseSmileIDSampleAvatar = ({ initials, size, containerColor, testID, style }: Props) => {
  const theme = useSmileIDSampleTheme();
  const hasInitials = initials.trim().length > 0;
  const base = size ?? theme.dimens.space[40];
  const diameter = base * PixelRatio.getFontScale();
  const fill = containerColor ?? smileProfileHues[0];

  return (
    <View
      testID={testID}
      style={[
        styles.container,
        {
          width: diameter,
          height: diameter,
          borderRadius: AVATAR_RADIUS,
          backgroundColor: hasInitials ? fill : theme.colors.avatar.placeholderBackground,
        },
        style,
      ]}
    >
      <Text
        style={[
          theme.type.avatarFont,
          { color: hasInitials ? theme.colors.avatar.text : theme.colors.avatar.placeholderIcon },
          styles.label,
        ]}
      >
        {hasInitials ? initials : '?'}
      </Text>
    </View>
  );
};

/// The avatar fill for a profile at [profileIndex], cycled. Position, not a hash of the initials, which reproduces no design order.
export const avatarColorForProfile = (profileIndex: number): string => {
  const index = Math.max(0, profileIndex) % smileProfileHues.length;
  return smileProfileHues[index] as string;
};

const styles = StyleSheet.create({
  container: { alignItems: 'center', justifyContent: 'center', overflow: 'hidden' },
  label: { textAlign: 'center' },
});
