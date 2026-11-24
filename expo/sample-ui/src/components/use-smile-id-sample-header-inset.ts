import { createContext, useContext } from 'react';
import { Platform } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

/// Whether the screen has a camera cutout along its top edge, which only the host's native code can read.
export const UseSmileIDSampleTopCutoutContext = createContext(false);

/// The top padding a screen's header takes: the safe area, plus a small gap under an Android phone's top camera cutout, which the status bar ends flush with where an iPhone's safe area leaves room.
export const useSmileIDSampleHeaderTopInset = (): number => {
  const { top } = useSafeAreaInsets();
  const underTopCutout = useContext(UseSmileIDSampleTopCutoutContext);
  const theme = useSmileIDSampleTheme();
  return top + (Platform.OS === 'android' && top > 0 && underTopCutout ? theme.dimens.spacing.sm : 0);
};
