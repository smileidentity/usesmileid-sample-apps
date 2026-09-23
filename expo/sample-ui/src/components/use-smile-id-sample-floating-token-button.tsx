import { Platform, Pressable, StyleSheet, type StyleProp, type ViewStyle } from 'react-native';

import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';
import { UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

/// The Compose button's `shadowElevation`, 4dp, which Android draws natively; iOS takes the design's floating shadow.
export const SMILE_TOKEN_FLOAT_ELEVATION = 4;

type Props = {
  onPress: () => void;
  style?: StyleProp<ViewStyle>;
};

/// The floating affordance that reaches the token session from inside a form.
export const UseSmileIDSampleFloatingTokenButton = ({ onPress, style }: Props) => {
  const theme = useSmileIDSampleTheme();
  // The design draws 46; space48 is that rounded onto the scale and is also the platform minimum.
  const size = theme.dimens.space[48];

  return (
    <Pressable
      testID={UseSmileIDSampleTestIds.TOKEN_FLOAT}
      accessibilityRole="button"
      accessibilityLabel="Token session"
      onPress={onPress}
      style={[
        styles.button,
        Platform.OS === 'android' ? { elevation: SMILE_TOKEN_FLOAT_ELEVATION } : theme.dimens.elevation.floating,
        {
          width: size,
          height: size,
          borderRadius: size / 2,
          // A bordered surface like the nav bar's token control, not a primary-filled FAB.
          backgroundColor: theme.colors.surface,
          borderWidth: theme.dimens.borderWidth.thin,
          borderColor: theme.colors.border,
        },
        style,
      ]}
    >
      <UseSmileIDSampleIcon name="tokenScan" tint={theme.colors.textTitle} />
    </Pressable>
  );
};

const styles = StyleSheet.create({
  button: { alignItems: 'center', justifyContent: 'center' },
});
