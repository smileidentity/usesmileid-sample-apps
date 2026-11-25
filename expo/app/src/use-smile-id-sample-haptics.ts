import type { UseSmileIDSampleHaptics } from '@smileid/sample-ui';
import * as Haptics from 'expo-haptics';

const quietly = (played: Promise<void>) => {
  played.catch(() => undefined);
};

/// The ticks sample-ui asks for, played through expo-haptics on [os] with the types the native apps use.
export const smileIDSampleHapticsFor = (os: string): UseSmileIDSampleHaptics =>
  os === 'android'
    ? {
        selection: () => quietly(Haptics.performAndroidHapticsAsync(Haptics.AndroidHaptics.Segment_Tick)),
        toggle: (on) =>
          quietly(Haptics.performAndroidHapticsAsync(on ? Haptics.AndroidHaptics.Toggle_On : Haptics.AndroidHaptics.Toggle_Off)),
      }
    : {
        selection: () => quietly(Haptics.selectionAsync()),
        toggle: () => quietly(Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light)),
      };
