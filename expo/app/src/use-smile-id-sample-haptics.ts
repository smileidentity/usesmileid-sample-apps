import type { UseSmileIDSampleHaptics } from '@smileid/sample-ui';
import * as Haptics from 'expo-haptics';

const quietly = (played: Promise<void>) => {
  played.catch(() => undefined);
};

const android = (type: Haptics.AndroidHaptics) => quietly(Haptics.performAndroidHapticsAsync(type));

/// The API level that added the segment and toggle constants; below it Android plays nothing for them.
const SEGMENT_AND_TOGGLE_API = 34;

/// The ticks sample-ui asks for on [os] at [apiLevel], with the fallbacks Compose uses before API 34; iOS's toggle is silent because UISwitch ticks itself.
export const smileIDSampleHapticsFor = (os: string, apiLevel: number): UseSmileIDSampleHaptics => {
  if (os !== 'android') {
    return { selection: () => quietly(Haptics.selectionAsync()), toggle: () => {} };
  }
  const modern = apiLevel >= SEGMENT_AND_TOGGLE_API;
  return {
    selection: () => android(modern ? Haptics.AndroidHaptics.Segment_Tick : Haptics.AndroidHaptics.Clock_Tick),
    toggle: (on) =>
      android(
        modern
          ? on
            ? Haptics.AndroidHaptics.Toggle_On
            : Haptics.AndroidHaptics.Toggle_Off
          : on
            ? Haptics.AndroidHaptics.Virtual_Key
            : Haptics.AndroidHaptics.Virtual_Key_Release,
      ),
  };
};
