import type { AdaptiveColor } from '@smileid/usesmileid';

/// A theme scenario stated in the SDK's own types, so the host is a straight assignment.
export type UseSmileIDSampleThemeOverride = {
  readonly primaryColor: AdaptiveColor;
  readonly primaryForeground: AdaptiveColor;
  readonly secondaryColor: AdaptiveColor;
  readonly accentColor: AdaptiveColor;
  readonly buttonShape: number;
  /// The family every SDK screen draws in, or absent to keep the SDK's own.
  readonly fontFamily?: string;
};

/// What each theme scenario overrides, or null for the ship state.
export const smileIDSampleThemeOverride = (themeId: string): UseSmileIDSampleThemeOverride | null => {
  switch (themeId) {
    // Named CSS colours, never a token: a partner palette has to be nobody's brand.
    case 'partnerOverride':
      return {
        primaryColor: { light: 'slateblue', dark: 'mediumpurple' },
        primaryForeground: { light: 'white', dark: 'black' },
        secondaryColor: { light: 'teal', dark: 'turquoise' },
        accentColor: { light: 'coral', dark: 'coral' },
        buttonShape: partnerButtonRadius,
      };
    // Outside every palette, to collide; monospace resolves everywhere without bundling a font.
    case 'clashingHost':
      return {
        primaryColor: { light: 'magenta', dark: 'magenta' },
        primaryForeground: { light: 'yellow', dark: 'yellow' },
        secondaryColor: { light: 'lime', dark: 'lime' },
        accentColor: { light: 'red', dark: 'red' },
        buttonShape: clashingButtonRadius,
        fontFamily: 'monospace',
      };
    default:
      return null;
  }
};

const partnerButtonRadius = 4;
const clashingButtonRadius = 24;
