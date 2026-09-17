import {
  ActivityIndicator,
  Pressable,
  StyleSheet,
  Text,
  View,
  type StyleProp,
  type ViewStyle,
} from 'react-native';

import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

type Props = {
  text: string;
  onPress: () => void;
  enabled?: boolean;
  loading?: boolean;
  testID?: string;
  style?: StyleProp<ViewStyle>;
};

/// The full-width primary action. A minimum height so the label wraps rather than clips, and loading refuses taps while keeping the enabled colours.
export const UseSmileIDSampleButton = ({
  text,
  onPress,
  enabled = true,
  loading = false,
  testID,
  style,
}: Props) => {
  const theme = useSmileIDSampleTheme();
  const interactive = enabled && !loading;
  const showDisabledColours = !enabled && !loading;

  return (
    <Pressable
      testID={testID}
      accessibilityRole="button"
      accessibilityState={{ disabled: !interactive, busy: loading }}
      disabled={!interactive}
      onPress={onPress}
      style={({ pressed }) => [
        styles.container,
        {
          minHeight: theme.dimens.size['control-lg'],
          borderRadius: theme.dimens.radius.control,
          paddingHorizontal: theme.dimens.button.paddingX,
          backgroundColor: showDisabledColours
            ? theme.colors.button.disabledBackground
            : theme.colors.button.primaryBackground,
          opacity: pressed && interactive ? PRESSED_OPACITY : 1,
        },
        style,
      ]}
    >
      <View style={styles.content}>
        {loading ? (
          <ActivityIndicator
            size="small"
            color={theme.colors.button.primaryText}
            style={{ width: theme.dimens.size['icon-md'], height: theme.dimens.size['icon-md'] }}
          />
        ) : (
          <Text
            style={[
              theme.type.buttonFont,
              styles.label,
              {
                color: showDisabledColours
                  ? theme.colors.button.disabledText
                  : theme.colors.button.primaryText,
                paddingVertical: theme.dimens.space[4],
              },
            ]}
          >
            {text}
          </Text>
        )}
      </View>
    </Pressable>
  );
};

/// Compose and SwiftUI both dim a pressed filled button; this is the same treatment, stated once.
const PRESSED_OPACITY = 0.85;

const styles = StyleSheet.create({
  container: { alignItems: 'center', justifyContent: 'center', width: '100%' },
  content: { alignItems: 'center', justifyContent: 'center' },
  label: { textAlign: 'center' },
});
