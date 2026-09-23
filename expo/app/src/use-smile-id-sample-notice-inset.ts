import { useSmileIDSampleTheme } from '@smileid/sample-ui';
import type { ViewStyle } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

/// Where a notice sits: above `clearance` when a tab's nav bar is under it, else past the system bar edge-to-edge draws over the route, plus one gap.
export const useSmileIDSampleNoticeStyle = (clearance?: number): ViewStyle => {
  const theme = useSmileIDSampleTheme();
  const insets = useSafeAreaInsets();
  return {
    position: 'absolute',
    bottom: clearance ?? insets.bottom + theme.dimens.spacing.md,
    paddingHorizontal: theme.dimens.spacing.md,
  };
};
