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
    // Named CSS colours, never a token and never a hex literal: a plausible partner palette has to
    // be nobody's brand, and reading one out of the design system would make it Smile ID's.
    case 'partnerOverride':
      return {
        primaryColor: { light: 'slateblue', dark: 'mediumpurple' },
        primaryForeground: { light: 'white', dark: 'black' },
        secondaryColor: { light: 'teal', dark: 'turquoise' },
        accentColor: { light: 'coral', dark: 'coral' },
        buttonShape: partnerButtonRadius,
      };
    // Deliberately outside every palette: this scenario exists to collide. Monospace is the one
    // family every platform resolves without bundling a font.
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
