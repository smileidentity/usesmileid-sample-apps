import { Platform } from 'react-native';

import { tokens } from '../tokens';

/// Strips the CSS unit the token source carries, because React Native sizes are unitless numbers.
const px = (value: string): number => {
  const parsed = Number.parseFloat(value);
  if (Number.isNaN(parsed)) {
    throw new Error(`design token ${value} is not a length this platform can use`);
  }
  return parsed;
};

const mapPx = <T extends object>(group: T): { [K in keyof T]: number } => {
  const out = {} as { [K in keyof T]: number };
  for (const [key, value] of Object.entries(group)) {
    out[key as keyof T] = px(value as string);
  }
  return out;
};

/// Material's minimum touch target, which Compose's `minimumInteractiveComponentSize` enforces.
const MATERIAL_TOUCH_TARGET = 48;
/// Apple's Human Interface Guidelines minimum hit target.
const APPLE_TOUCH_TARGET = 44;

/// A shadow the token source expresses in CSS, as the props React Native's two platforms each read.
const shadow = (value: { color: string; offsetY: string; blur: string }) => ({
  shadowColor: value.color,
  shadowOffset: { width: 0, height: px(value.offsetY) },
  shadowOpacity: 1,
  shadowRadius: px(value.blur),
  elevation: px(value.blur),
});

/// The dimension scale, group by group under the design system's own keys so a use site is greppable upstream.
export const smileDimens = {
  space: mapPx(tokens.space),
  radius: mapPx(tokens.radius),
  borderWidth: mapPx(tokens['border-width']),
  size: mapPx(tokens.size),
  spacing: mapPx(tokens.spacing),
  avatar: {
    radius: px(tokens.avatar.radius),
    sizeSm: px(tokens.avatar['size-sm']),
    sizeMd: px(tokens.avatar['size-md']),
    sizeLg: px(tokens.avatar['size-lg']),
  },
  badge: {
    radius: px(tokens.badge.radius),
    paddingX: px(tokens.badge['padding-x']),
    paddingY: px(tokens.badge['padding-y']),
  },
  button: {
    radius: px(tokens.button.radius),
    paddingX: px(tokens.button['padding-x']),
    paddingY: px(tokens.button['padding-y']),
    height: px(tokens.button.height),
  },
  input: {
    radius: px(tokens.input.radius),
    paddingX: px(tokens.input['padding-x']),
    height: px(tokens.input.height),
  },
  search: {
    radius: px(tokens.search.radius),
    paddingX: px(tokens.search['padding-x']),
    gap: px(tokens.search.gap),
    height: px(tokens.search.height),
  },
  /// The platform's own minimum touch target.
  touchTarget: Platform.OS === 'android' ? MATERIAL_TOUCH_TARGET : APPLE_TOUCH_TARGET,
  elevation: {
    card: shadow(tokens.elevation.card),
    floating: shadow(tokens.elevation.floating),
  },
} as const;

export type SmileDimens = typeof smileDimens;
