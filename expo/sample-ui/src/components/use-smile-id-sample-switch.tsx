import { Switch, type StyleProp, type ViewStyle } from 'react-native';

import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

type Props = {
  checked: boolean;
  onCheckedChange?: ((checked: boolean) => void) | undefined;
  enabled?: boolean;
  testID?: string;
  style?: StyleProp<ViewStyle>;
};

/// The platform switch styled from semantic tokens — deliberately not hand-drawn, since the design system has no switch contract (spec/components.json → Switch).
export const UseSmileIDSampleSwitch = ({
  checked,
  onCheckedChange,
  enabled = true,
  testID,
  style,
}: Props) => {
  const theme = useSmileIDSampleTheme();
  const trackOn = enabled ? theme.colors.primary : theme.colors.textMuted;
  const thumb = enabled || checked ? theme.colors.surface : theme.colors.surfaceMuted;

  return (
    <Switch
      testID={testID}
      value={checked}
      disabled={!enabled}
      onValueChange={onCheckedChange}
      trackColor={{ false: theme.colors.border, true: trackOn }}
      thumbColor={thumb}
      // The off track is settable here where SwiftUI's Toggle cannot set it, so this mapping follows
      // Android rather than iOS and carries the upstream darkBorder defect with it, deliberately.
      ios_backgroundColor={theme.colors.border}
      style={style}
    />
  );
};
