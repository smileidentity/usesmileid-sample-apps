import type { TextStyle } from 'react-native';

import { smileFontFamily } from './smile-fonts';
import { tokens } from '../tokens';

type FontWeight = NonNullable<TextStyle['fontWeight']>;

/// One resolved text style, as the props a React Native Text reads directly.
export type SmileTextStyle = {
  readonly fontFamily: string;
  readonly fontWeight: FontWeight;
  readonly fontSize: number;
  readonly lineHeight: number;
  readonly letterSpacing: number;
};

type TokenTextStyle = {
  readonly fontFamily: readonly string[];
  readonly fontWeight: number;
  readonly fontSize: string;
  readonly lineHeight: string;
  readonly letterSpacing: string;
};

const px = (value: string): number => Number.parseFloat(value);

/// Resolves one token style. The display ramp names Epilogue first and it is not shipped, so every
/// style takes its DM Sans fallback — the same substitution the Compose and SwiftUI twins make.
const style = (token: TokenTextStyle): SmileTextStyle => ({
  fontFamily: smileFontFamily(token.fontWeight),
  fontWeight: String(token.fontWeight) as FontWeight,
  fontSize: px(token.fontSize),
  lineHeight: px(token.lineHeight),
  letterSpacing: px(token.letterSpacing),
});

const ramp = tokens['text-style'];

/// The whole ramp: the fourteen named styles plus the fifteen a component group owns.
export const smileType = {
  textStyleDisplayLg: style(ramp['display-lg']),
  textStyleDisplayMd: style(ramp['display-md']),
  textStyleHeadingPage: style(ramp['heading-page']),
  textStyleHeadingCard: style(ramp['heading-card']),
  textStyleHeadingSection: style(ramp['heading-section']),
  textStyleTitle: style(ramp.title),
  textStyleSubtitle: style(ramp.subtitle),
  textStyleBody: style(ramp.body),
  textStyleBodyStrong: style(ramp['body-strong']),
  textStyleBodySm: style(ramp['body-sm']),
  textStyleCaption: style(ramp.caption),
  textStyleOverline: style(ramp.overline),
  textStyleButton: style(ramp.button),
  textStyleButtonSm: style(ramp['button-sm']),
  avatarFont: style(tokens.avatar.font),
  badgeFont: style(tokens.badge.font),
  bannerTitleFont: style(tokens.banner['title-font']),
  bannerTextFont: style(tokens.banner['text-font']),
  buttonFont: style(tokens.button.font),
  cardTitleFont: style(tokens.card['title-font']),
  dataFieldLabelFont: style(tokens['data-field']['label-font']),
  dataFieldValueFont: style(tokens['data-field']['value-font']),
  filterChipFont: style(tokens.filter['chip-font']),
  inputFont: style(tokens.input.font),
  linkFont: style(tokens.link.font),
  searchFont: style(tokens.search.font),
  tableHeaderFont: style(tokens.table['header-font']),
  tableCellFont: style(tokens.table['cell-font']),
  tabFont: style(tokens.tab.font),
} as const;

export type SmileType = typeof smileType;

/// Re-resolves a style at a different weight, so an override cannot keep the old face.
export const atWeight = (base: SmileTextStyle, weight: number): SmileTextStyle => ({
  ...base,
  fontFamily: smileFontFamily(weight),
  fontWeight: String(weight) as FontWeight,
});
