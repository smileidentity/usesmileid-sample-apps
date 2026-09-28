import type { ButtonSlot } from '@smileid/usesmileid';
import { Pressable, StyleSheet, Text } from 'react-native';

import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';
import { UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';
import { UseSmileIDSampleButton } from './use-smile-id-sample-button';

type Props = {
  /// The slot's action; the SDK keeps deciding what the tap does.
  onPress: () => void;
  /// Whether the slot allows the tap.
  enabled?: boolean;
};

/// The sample's own continue button, drawn by the SDK in its continue slots while Custom continue is on.
export const UseSmileIDSampleCustomContinueButton = ({ onPress, enabled = true }: Props) => (
  <UseSmileIDSampleButton
    text={CUSTOM_CONTINUE_LABEL}
    onPress={onPress}
    enabled={enabled}
    testID={UseSmileIDSampleTestIds.CUSTOM_CONTINUE}
  />
);

/// The sample's own cancel button, for the SDK's cancel slots: the continue button's outlined twin.
export const UseSmileIDSampleCustomCancelButton = ({ onPress, enabled = true }: Props) => {
  const theme = useSmileIDSampleTheme();
  const colour = enabled ? theme.colors.button.primaryBackground : theme.colors.button.disabledText;
  return (
    <Pressable
      testID={UseSmileIDSampleTestIds.CUSTOM_CANCEL}
      accessibilityRole="button"
      accessibilityState={{ disabled: !enabled }}
      disabled={!enabled}
      onPress={onPress}
      style={({ pressed }) => [
        styles.container,
        {
          minHeight: theme.dimens.size['control-lg'],
          borderRadius: theme.dimens.radius.control,
          paddingHorizontal: theme.dimens.button.paddingX,
          borderWidth: theme.dimens.borderWidth.thin,
          borderColor: enabled ? colour : theme.colors.button.disabledBackground,
          opacity: pressed && enabled ? PRESSED_OPACITY : 1,
        },
      ]}
    >
      <Text style={[theme.type.buttonFont, styles.label, { color: colour, paddingVertical: theme.dimens.space[4] }]}>
        {CUSTOM_CANCEL_LABEL}
      </Text>
    </Pressable>
  );
};

/// The continue slots' content; the SDK's scope decides what the tap does and when it is allowed.
export const useSmileIDSampleCustomContinueSlot: ButtonSlot = ({ onClick, enabled }) => (
  <UseSmileIDSampleCustomContinueButton onPress={onClick} enabled={enabled} />
);

/// The cancel slots' content.
export const useSmileIDSampleCustomCancelSlot: ButtonSlot = ({ onClick, enabled }) => (
  <UseSmileIDSampleCustomCancelButton onPress={onClick} enabled={enabled} />
);

/// The continue button's label, which names it for a demo audience.
export const CUSTOM_CONTINUE_LABEL = 'Custom continue';

/// The cancel button's label.
export const CUSTOM_CANCEL_LABEL = 'Custom cancel';

/// The primary button's pressed dim, so the outlined twin answers a tap the same way.
const PRESSED_OPACITY = 0.85;

const styles = StyleSheet.create({
  container: { alignItems: 'center', alignSelf: 'stretch', justifyContent: 'center' },
  label: { textAlign: 'center' },
});
