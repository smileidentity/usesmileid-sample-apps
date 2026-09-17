/// The five DM Sans weights the ramp resolves against, keyed by the token source's own numbers.
export const smileFontFaces = {
  400: 'DMSans-Regular',
  500: 'DMSans-Medium',
  600: 'DMSans-SemiBold',
  700: 'DMSans-Bold',
  800: 'DMSans-ExtraBold',
} as const;

export type SmileFontWeight = keyof typeof smileFontFaces;

/// What the host registers with expo-font: the key is the family a style names, so a rename drops a weight.
export const smileFontAssets: Readonly<Record<string, number>> = {
  'DMSans-Regular': require('../../assets/fonts/DMSans-Regular.ttf'),
  'DMSans-Medium': require('../../assets/fonts/DMSans-Medium.ttf'),
  'DMSans-SemiBold': require('../../assets/fonts/DMSans-SemiBold.ttf'),
  'DMSans-Bold': require('../../assets/fonts/DMSans-Bold.ttf'),
  'DMSans-ExtraBold': require('../../assets/fonts/DMSans-ExtraBold.ttf'),
};

/// A face per weight, because a custom family on React Native selects nothing by numeric weight.
export const smileFontFamily = (weight: number): string => {
  const face = smileFontFaces[weight as SmileFontWeight];
  if (!face) {
    throw new Error(`no DM Sans face is bundled for weight ${weight}`);
  }
  return face;
};
