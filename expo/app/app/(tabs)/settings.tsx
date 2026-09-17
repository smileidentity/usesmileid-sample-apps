import {
  UseSmileIDSampleSectionLabel,
  UseSmileIDSampleTestIds,
  useSmileIDSampleTheme,
} from '@smileid/sample-ui';
import { View } from 'react-native';

/// The settings destination, which drives every other screen's configuration once U3 fills it in.
export default function SettingsScreen() {
  const theme = useSmileIDSampleTheme();

  return (
    <View
      testID={UseSmileIDSampleTestIds.SETTINGS_SCREEN}
      style={{ backgroundColor: theme.colors.background, flex: 1, padding: theme.dimens.spacing.md }}
    >
      <UseSmileIDSampleSectionLabel text="APPEARANCE" />
    </View>
  );
}
