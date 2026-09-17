import { smileOffBlackLight } from '../smile-product-hues';
import { lightColors } from '../tokens';

/// The standard white-or-dark crossover: above it a fill carries dark ink, below it light.
const INK_CROSSOVER = 0.179;

type Rgb = { r: number; g: number; b: number };

const channels = (hex: string): Rgb => {
  const text = hex.trim().replace('#', '');
  if (text.length !== 6) {
    throw new Error(`${hex} is not a #RRGGBB colour`);
  }
  return {
    r: Number.parseInt(text.slice(0, 2), 16) / 255,
    g: Number.parseInt(text.slice(2, 4), 16) / 255,
    b: Number.parseInt(text.slice(4, 6), 16) / 255,
  };
};

/// WCAG relative luminance, which is what the Compose arbiter's `Color.luminance()` computes.
export const smileLuminance = (hex: string): number => {
  const { r, g, b } = channels(hex);
  const linear = (c: number) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);
  return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b);
};

/// The ink that contrasts with this fill: one scrim across six cards this different leaves marks invisible at both ends.
export const smileInkOn = (hex: string): string =>
  smileLuminance(hex) > INK_CROSSOVER ? smileOffBlackLight : lightColors.color.text.inverse;

/// Interpolates two colours, which is how a gradient stop drawn past the card's edge is brought back inside it.
export const smileMix = (from: string, to: string, fraction: number): string => {
  const a = channels(from);
  const b = channels(to);
  const t = Math.min(Math.max(fraction, 0), 1);
  const channel = (one: number, two: number) =>
    Math.round((one + (two - one) * t) * 255)
      .toString(16)
      .padStart(2, '0');
  return `#${channel(a.r, b.r)}${channel(a.g, b.g)}${channel(a.b, b.b)}`;
};

/// An `#RRGGBB` plus an alpha as the eight-digit form React Native reads directly.
export const smileWithAlpha = (hex: string, alpha: number): string => {
  const clamped = Math.min(Math.max(alpha, 0), 1);
  const byte = Math.round(clamped * 255)
    .toString(16)
    .padStart(2, '0');
  return `${hex.trim()}${byte}`;
};
