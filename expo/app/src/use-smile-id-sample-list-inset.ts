import { useSmileIDSampleTheme } from '@smileid/sample-ui';
import { useBottomTabBarHeight } from 'expo-router/tabs';

/// What a tab's list must reserve under the floating bar: the bar's own measured height, plus one gap.
export const useSmileIDSampleListInset = (): number => {
  const theme = useSmileIDSampleTheme();
  // Measured, never computed: the bar's height carries the label wrap and the gesture inset already.
  return useBottomTabBarHeight() + theme.dimens.spacing.md;
};
