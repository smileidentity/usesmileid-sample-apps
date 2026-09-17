import {
  smileBorderStrong,
  smileCardStrokeDark,
  smileCardStrokeLight,
  smileNavBarDark,
  smileNavBarLight,
  smileOffBlackDark,
  smileOffBlackLight,
  smileSoftBadgeFills,
  smileSurface2,
} from '../smile-product-hues';
import { darkColors, lightColors } from '../tokens';

/// One component's tokens, resolved for the active mode.
export type AvatarTokens = {
  readonly background: string;
  readonly text: string;
  readonly placeholderBackground: string;
  readonly placeholderIcon: string;
};

/// Colours the buttons draw: one background/text pair per enabled state.
export type ButtonTokens = {
  readonly primaryBackground: string;
  readonly primaryText: string;
  readonly disabledBackground: string;
  readonly disabledText: string;
};

export type InputTokens = {
  readonly background: string;
  readonly text: string;
  readonly placeholder: string;
  readonly border: string;
  readonly borderFocus: string;
  readonly borderError: string;
};

export type SearchTokens = InputTokens & { readonly icon: string };

/// The label/value pair on a details card.
export type DataFieldTokens = { readonly label: string; readonly value: string };

/// A filter chip's unselected paint; selected takes color.primary with its on-colour.
export type FilterChipTokens = { readonly background: string; readonly label: string };

/// Colours the cards draw, the section surfaces among them.
export type CardTokens = {
  readonly background: string;
  readonly border: string;
  readonly title: string;
  readonly body: string;
};

/// Colours the status badges draw: one background/text pair per role.
export type BadgeTokens = {
  readonly successBackground: string;
  readonly successText: string;
  readonly warningBackground: string;
  readonly warningText: string;
  readonly errorBackground: string;
  readonly errorText: string;
  readonly infoBackground: string;
  readonly infoText: string;
};

export type SmileColors = {
  readonly primary: string;
  readonly onPrimary: string;
  readonly secondary: string;
  readonly accent: string;
  readonly background: string;
  readonly surface: string;
  readonly surfaceAlt: string;
  readonly surfaceMuted: string;
  readonly border: string;
  readonly overlayScrim: string;
  readonly textTitle: string;
  readonly textBody: string;
  readonly textMuted: string;
  readonly textInverse: string;
  readonly textLink: string;
  readonly errorFill: string;
  readonly onError: string;
  readonly avatar: AvatarTokens;
  readonly button: ButtonTokens;
  readonly input: InputTokens;
  readonly search: SearchTokens;
  readonly badge: BadgeTokens;
  readonly dataField: DataFieldTokens;
  readonly filterChip: FilterChipTokens;
  readonly card: CardTokens;
  readonly offBlack: string;
  readonly navBar: string;
  readonly cardStroke: string;
  readonly borderStrong: string;
  readonly surface2: string;
  /// The cool-grey fill behind a leading tile and a tonal app-bar control, never the warm surface-alt.
  readonly surfaceTile: string;
};

/// Soft status tints, which no design-system `badge.*` pair carries, and the same in both schemes.
const softBadgeTokens = (): BadgeTokens => {
  const fill = (role: string) => {
    const pair = smileSoftBadgeFills[role];
    if (!pair) {
      throw new Error(`no soft badge fill for '${role}'; see spec/design-tokens.json → softBadgeFills`);
    }
    return pair;
  };
  return {
    successBackground: fill('success').background,
    successText: fill('success').text,
    warningBackground: fill('warning').background,
    warningText: fill('warning').text,
    errorBackground: fill('error').background,
    errorText: fill('error').text,
    infoBackground: fill('info').background,
    infoText: fill('info').text,
  };
};

/// Exactly the token paths this theme reads, with string leaves so both schemes satisfy one type.
type SmileColorSource = {
  readonly color: {
    readonly primary: string;
    readonly 'on-primary': string;
    readonly secondary: string;
    readonly accent: string;
    readonly background: string;
    readonly surface: string;
    readonly 'surface-alt': string;
    readonly 'surface-muted': string;
    readonly border: string;
    readonly 'overlay-scrim': string;
    readonly text: {
      readonly title: string;
      readonly body: string;
      readonly muted: string;
      readonly inverse: string;
      readonly link: string;
    };
    readonly feedback: { readonly error: { readonly fill: string; readonly on: string } };
  };
  readonly avatar: {
    readonly bg: string;
    readonly text: string;
    readonly 'placeholder-bg': string;
    readonly 'placeholder-icon': string;
  };
  readonly button: {
    readonly primary: { readonly background: string; readonly text: string };
    readonly disabled: { readonly background: string; readonly text: string };
  };
  readonly input: {
    readonly background: string;
    readonly text: string;
    readonly placeholder: string;
    readonly border: string;
    readonly 'border-focus': string;
    readonly 'border-error': string;
  };
  readonly search: {
    readonly background: string;
    readonly text: string;
    readonly placeholder: string;
    readonly icon: string;
    readonly border: string;
    readonly 'border-focus': string;
  };
  readonly 'data-field': { readonly label: string; readonly value: string };
  readonly filter: { readonly 'chip-bg': string; readonly 'chip-label': string };
  readonly card: {
    readonly background: string;
    readonly border: string;
    readonly 'title-text': string;
    readonly 'body-text': string;
  };
};

const group = (
  source: SmileColorSource,
  offBlack: string,
  navBar: string,
  cardStroke: string,
  surfaceTile: string,
): SmileColors => ({
  primary: source.color.primary,
  onPrimary: source.color['on-primary'],
  secondary: source.color.secondary,
  accent: source.color.accent,
  background: source.color.background,
  surface: source.color.surface,
  surfaceAlt: source.color['surface-alt'],
  surfaceMuted: source.color['surface-muted'],
  border: source.color.border,
  overlayScrim: source.color['overlay-scrim'],
  textTitle: source.color.text.title,
  textBody: source.color.text.body,
  textMuted: source.color.text.muted,
  textInverse: source.color.text.inverse,
  textLink: source.color.text.link,
  errorFill: source.color.feedback.error.fill,
  onError: source.color.feedback.error.on,
  avatar: {
    background: source.avatar.bg,
    text: source.avatar.text,
    placeholderBackground: source.avatar['placeholder-bg'],
    placeholderIcon: source.avatar['placeholder-icon'],
  },
  button: {
    primaryBackground: source.button.primary.background,
    primaryText: source.button.primary.text,
    disabledBackground: source.button.disabled.background,
    disabledText: source.button.disabled.text,
  },
  input: {
    background: source.input.background,
    text: source.input.text,
    placeholder: source.input.placeholder,
    border: source.input.border,
    borderFocus: source.input['border-focus'],
    borderError: source.input['border-error'],
  },
  search: {
    background: source.search.background,
    text: source.search.text,
    placeholder: source.search.placeholder,
    icon: source.search.icon,
    border: source.search.border,
    borderFocus: source.search['border-focus'],
    borderError: source.input['border-error'],
  },
  badge: softBadgeTokens(),
  dataField: {
    label: source['data-field'].label,
    value: source['data-field'].value,
  },
  filterChip: {
    background: source.filter['chip-bg'],
    label: source.filter['chip-label'],
  },
  card: {
    background: source.card.background,
    border: source.card.border,
    title: source.card['title-text'],
    body: source.card['body-text'],
  },
  offBlack,
  navBar,
  cardStroke,
  borderStrong: smileBorderStrong,
  surface2: smileSurface2,
  surfaceTile,
});

export const smileLightColors: SmileColors = group(
  lightColors,
  smileOffBlackLight,
  smileNavBarLight,
  smileCardStrokeLight,
  smileSurface2,
);

export const smileDarkColors: SmileColors = group(
  darkColors,
  smileOffBlackDark,
  smileNavBarDark,
  smileCardStrokeDark,
  // surface-2 is a light cool grey with no dark counterpart, so dark takes the muted surface.
  darkColors.color['surface-muted'],
);
