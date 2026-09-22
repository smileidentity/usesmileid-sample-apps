import { smileFontFamily } from './smile-fonts';
import { tokens } from '../tokens';

/// One resolved text style, as the props a React Native Text reads directly.
export type SmileTextStyle = {
  readonly fontFamily: string;
  readonly fontSize: number;
  readonly lineHeight: number;
  readonly letterSpacing: number;
  readonly marginTop: number;
  readonly marginBottom: number;
};

type TokenTextStyle = {
  readonly fontFamily: readonly string[];
  readonly fontWeight: number;
  readonly fontSize: string;
  readonly lineHeight: string;
  readonly letterSpacing: string;
};

const px = (value: string): number => Number.parseFloat(value);

/// DM Sans's hhea ascent plus descent, 992 + 310 over 1000 units, the same in all five weights.
const SMILE_FONT_HEIGHT_EM = 1.302;

/// Compose trims the leading above a text's first line and below its last; the negative margins do the same here.
const trimmed = (fontSize: number, lineHeight: number) => {
  // Half each way, because React Native centres the glyphs in the line as Compose's trimmed box does.
  const half = Math.max(0, lineHeight - fontSize * SMILE_FONT_HEIGHT_EM) / 2;
  return { marginTop: -half, marginBottom: -half };
};

/// Resolves one token style in DM Sans, the fallback the display ramp's unshipped Epilogue takes on every twin.
const style = (token: TokenTextStyle): SmileTextStyle => ({
  // No fontWeight: the family names the face, and a bold weight on Android swaps a loaded face for the system font.
  fontFamily: smileFontFamily(token.fontWeight),
  fontSize: px(token.fontSize),
  lineHeight: px(token.lineHeight),
  letterSpacing: px(token.letterSpacing),
  ...trimmed(px(token.fontSize), px(token.lineHeight)),
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
});

/// Re-resolves a style at a different size, keeping its line height unless told otherwise, so the trim follows.
export const atSize = (base: SmileTextStyle, fontSize: number, lineHeight = base.lineHeight): SmileTextStyle => ({
  ...base,
  fontSize,
  lineHeight,
  ...trimmed(fontSize, lineHeight),
});

/// A style for a Text that paints its own box, whose trim has to come off its padding instead.
export const untrimmed = (base: SmileTextStyle): SmileTextStyle => ({ ...base, marginTop: 0, marginBottom: 0 });
