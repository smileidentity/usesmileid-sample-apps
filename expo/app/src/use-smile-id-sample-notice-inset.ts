import { useSmileIDSampleTheme } from '@smileid/sample-ui';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

/// Where a notice sits on a screen with no nav bar: past the system bar, which edge-to-edge draws over the route, plus one gap.
export const useSmileIDSampleNoticeInset = (): number => {
  const theme = useSmileIDSampleTheme();
  return useSafeAreaInsets().bottom + theme.dimens.spacing.md;
};
