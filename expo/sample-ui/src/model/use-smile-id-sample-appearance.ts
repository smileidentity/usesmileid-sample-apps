import { type UseSmileIDSampleStrings } from '../use-smile-id-sample-strings';

/// The app's theme choice; System follows the device's own theme.
export const UseSmileIDSampleAppearance = {
  System: 'system',
  Light: 'light',
  Dark: 'dark',
} as const;

export type UseSmileIDSampleAppearance =
  (typeof UseSmileIDSampleAppearance)[keyof typeof UseSmileIDSampleAppearance];

/// The sheet's rows in order.
export const smileIDSampleAppearances: readonly UseSmileIDSampleAppearance[] = [
  UseSmileIDSampleAppearance.System,
  UseSmileIDSampleAppearance.Light,
  UseSmileIDSampleAppearance.Dark,
];

/// Whether the app renders dark, given the device's own theme.
export const smileIDSampleAppearanceIsDark = (
  appearance: UseSmileIDSampleAppearance,
  deviceDark: boolean,
): boolean => (appearance === UseSmileIDSampleAppearance.System ? deviceDark : appearance === UseSmileIDSampleAppearance.Dark);

/// System names the device's theme, never the one the app renders, so the row says why it looks as it does.
export const smileIDSampleAppearanceLabel = (
  appearance: UseSmileIDSampleAppearance,
  deviceDark: boolean,
  strings: UseSmileIDSampleStrings,
): string => {
  switch (appearance) {
    case UseSmileIDSampleAppearance.System:
      return deviceDark ? strings.appearanceSystemDark : strings.appearanceSystemLight;
    case UseSmileIDSampleAppearance.Light:
      return strings.appearanceLight;
    case UseSmileIDSampleAppearance.Dark:
      return strings.appearanceDark;
  }
};
