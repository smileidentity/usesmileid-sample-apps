import { useSmileIDSampleTheme } from '@smileid/sample-ui';
import type { ViewStyle } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

/// A notice's position: above `clearance`, else past the system bar, plus one gap.
export const useSmileIDSampleNoticeStyle = (clearance?: number): ViewStyle => {
  const theme = useSmileIDSampleTheme();
  const insets = useSafeAreaInsets();
  return {
    position: 'absolute',
    bottom: clearance ?? insets.bottom + theme.dimens.spacing.md,
    paddingHorizontal: theme.dimens.spacing.md,
  };
};
