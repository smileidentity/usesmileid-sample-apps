import {
  UseSmileIDSampleSectionLabel,
  UseSmileIDSampleTestIds,
  useSmileIDSampleTheme,
} from '@smileid/sample-ui';
import { View } from 'react-native';

/// The verifications destination. Its list is U3; this tranche proves the route and its id resolve.
export default function VerificationsScreen() {
  const theme = useSmileIDSampleTheme();

  return (
    <View
      testID={UseSmileIDSampleTestIds.VERIFICATIONS_SCREEN}
      style={{ backgroundColor: theme.colors.background, flex: 1, padding: theme.dimens.spacing.md }}
    >
      <UseSmileIDSampleSectionLabel text="VERIFICATIONS" />
    </View>
  );
}
