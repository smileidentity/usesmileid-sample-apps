import {
  UseSmileIDSampleSectionLabel,
  UseSmileIDSampleTestIds,
  useSmileIDSampleTheme,
} from '@smileid/sample-ui';
import { View } from 'react-native';

/// The products destination. Its grid is U3; this tranche proves the route and its id resolve.
export default function ProductsScreen() {
  const theme = useSmileIDSampleTheme();

  return (
    <View
      testID={UseSmileIDSampleTestIds.PRODUCTS_SCREEN}
      style={{ backgroundColor: theme.colors.background, flex: 1, padding: theme.dimens.spacing.md }}
    >
      <UseSmileIDSampleSectionLabel text="AUTHENTICATION" />
    </View>
  );
}
