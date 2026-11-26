import { Host, Switch } from '@expo/ui/jetpack-compose';
import { testID as testIDModifier } from '@expo/ui/jetpack-compose/modifiers';
import type { StyleProp, ViewStyle } from 'react-native';

import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

type Props = {
  checked: boolean;
  onCheckedChange?: ((checked: boolean) => void) | undefined;
  enabled?: boolean;
  testID?: string;
  style?: StyleProp<ViewStyle>;
};

/// Material 3's switch, the one the Compose app draws, since React Native's own is the older AppCompat control.
export const UseSmileIDSampleSwitch = ({
  checked,
  onCheckedChange,
  enabled = true,
  testID,
  style,
}: Props) => {
  const theme = useSmileIDSampleTheme();
  const { colors } = theme;

  return (
    <Host matchContents style={style}>
      <Switch
        value={checked}
        enabled={enabled}
        onCheckedChange={onCheckedChange}
        modifiers={testID === undefined ? [] : [testIDModifier(testID)]}
        colors={{
          checkedThumbColor: colors.surface,
          checkedTrackColor: colors.primary,
          checkedBorderColor: colors.primary,
          uncheckedThumbColor: colors.surface,
          uncheckedTrackColor: colors.border,
          uncheckedBorderColor: colors.border,
          disabledCheckedThumbColor: colors.surface,
          disabledCheckedTrackColor: colors.textMuted,
          disabledCheckedBorderColor: colors.textMuted,
          disabledUncheckedThumbColor: colors.surfaceMuted,
          disabledUncheckedTrackColor: colors.border,
          disabledUncheckedBorderColor: colors.border,
        }}
      />
    </Host>
  );
};
