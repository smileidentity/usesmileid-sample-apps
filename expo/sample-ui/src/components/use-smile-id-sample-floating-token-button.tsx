import { Pressable, StyleSheet, type StyleProp, type ViewStyle } from 'react-native';

import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';
import { UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

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
        theme.dimens.elevation.floating,
        { width: size, height: size, borderRadius: size / 2, backgroundColor: theme.colors.primary },
        style,
      ]}
    >
      <UseSmileIDSampleIcon name="tokenScan" tint={theme.colors.onPrimary} />
    </Pressable>
  );
};

const styles = StyleSheet.create({
  button: { alignItems: 'center', justifyContent: 'center' },
});
