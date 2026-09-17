import 'package:flutter/material.dart';

import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';

/// One component's tokens, resolved for the active mode.
@immutable
class UseSmileIDSampleAvatarTokens {
  /// Takes every fill the avatar draws, initialled or placeholder.
  const UseSmileIDSampleAvatarTokens({
    required this.background,
    required this.text,
    required this.placeholderBackground,
    required this.placeholderIcon,
  });

  /// The initialled avatar's fill, overridden per profile by the caller.
  final Color background;

  /// The initials themselves.
  final Color text;

  /// The fill behind a profile with no initials.
  final Color placeholderBackground;

  /// The placeholder glyph.
  final Color placeholderIcon;
}

/// Colours the buttons draw: one background/text pair per enabled state.
@immutable
class UseSmileIDSampleButtonTokens {
  /// Takes both pairs, because a disabled button is not a faded enabled one.
  const UseSmileIDSampleButtonTokens({
    required this.primaryBackground,
    required this.primaryText,
    required this.disabledBackground,
    required this.disabledText,
  });

  /// The primary action's fill.
  final Color primaryBackground;

  /// The primary action's label.
  final Color primaryText;

  /// The disabled fill, which resolves through a primitive and so stays light in dark mode.
  final Color disabledBackground;

  /// The disabled label.
  final Color disabledText;
}

/// Colours the text fields draw, including the focus and error borders.
@immutable
class UseSmileIDSampleInputTokens {
  /// Takes all three border states, because error outranks focus at the use site.
  const UseSmileIDSampleInputTokens({
    required this.background,
    required this.text,
    required this.placeholder,
    required this.border,
    required this.borderFocus,
    required this.borderError,
  });

  /// The field's fill.
  final Color background;

  /// The entered value.
  final Color text;

  /// The placeholder, and the leading glyph's tint.
  final Color placeholder;

  /// The resting border.
  final Color border;

  /// The border while focused, and the caret.
  final Color borderFocus;

  /// The border and the message while in error.
  final Color borderError;
}

/// Colours the search field draws — its own set, because the icon is part of the control.
@immutable
class UseSmileIDSampleSearchTokens {
  /// Takes the icon alongside the field, which the input tokens do not carry.
  const UseSmileIDSampleSearchTokens({
    required this.background,
    required this.text,
    required this.placeholder,
    required this.icon,
    required this.border,
    required this.borderFocus,
  });

  /// The field's fill.
  final Color background;

  /// The entered query.
  final Color text;

  /// The placeholder.
  final Color placeholder;

  /// The magnifier.
  final Color icon;

  /// The resting border.
  final Color border;

  /// The border while focused, and the caret.
  final Color borderFocus;
}

/// One background/text pair per feedback role the four job statuses map onto.
@immutable
class UseSmileIDSampleBadgeTokens {
  /// Takes four pairs, one per role, rather than a role-to-colour function.
  const UseSmileIDSampleBadgeTokens({
    required this.successBackground,
    required this.successText,
    required this.warningBackground,
    required this.warningText,
    required this.errorBackground,
    required this.errorText,
    required this.infoBackground,
    required this.infoText,
  });

  /// Clear.
  final Color successBackground;

  /// Clear's label.
  final Color successText;

  /// Attention.
  final Color warningBackground;

  /// Attention's label.
  final Color warningText;

  /// Blocked.
  final Color errorBackground;

  /// Blocked's label.
  final Color errorText;

  /// Processing.
  final Color infoBackground;

  /// Processing's label.
  final Color infoText;
}

/// Colours the label/value rows draw, with a distinct fill for a value that is a link.
@immutable
class UseSmileIDSampleDataFieldTokens {
  /// Takes the link fill separately, because a linked value is not styled by the row.
  const UseSmileIDSampleDataFieldTokens({
    required this.label,
    required this.value,
    required this.valueLink,
  });

  /// The row's label.
  final Color label;

  /// The row's value.
  final Color value;

  /// A value that is a link.
  final Color valueLink;
}

/// Colours the filter chips draw, counted value and divider included.
@immutable
class UseSmileIDSampleFilterChipTokens {
  /// Takes the count and divider, which the chip draws inside its own border.
  const UseSmileIDSampleFilterChipTokens({
    required this.background,
    required this.border,
    required this.label,
    required this.value,
    required this.divider,
  });

  /// The chip's fill.
  final Color background;

  /// The chip's outline.
  final Color border;

  /// The chip's name.
  final Color label;

  /// The chip's count.
  final Color value;

  /// The rule between name and count.
  final Color divider;
}

/// Colours the cards draw, the section surfaces among them.
@immutable
class UseSmileIDSampleCardTokens {
  /// Takes both text roles, because a card's title and body are different tokens.
  const UseSmileIDSampleCardTokens({
    required this.background,
    required this.border,
    required this.title,
    required this.body,
  });

  /// The card's fill.
  final Color background;

  /// The card's outline.
  final Color border;

  /// The card's heading.
  final Color title;

  /// The card's prose.
  final Color body;
}

/// Colours the inline banners draw, the notices and callouts among them.
@immutable
class UseSmileIDSampleBannerTokens {
  /// Takes the same four roles as a card, resolved from the banner's own tokens.
  const UseSmileIDSampleBannerTokens({
    required this.background,
    required this.border,
    required this.title,
    required this.text,
  });

  /// The banner's fill.
  final Color background;

  /// The banner's outline.
  final Color border;

  /// The banner's heading.
  final Color title;

  /// The banner's prose.
  final Color text;
}

/// The product and profile fills; callers pass one explicitly rather than this deciding.
@immutable
class UseSmileIDSampleDecorativeTokens {
  /// Takes the nine decorative roles in the token source's own order.
  const UseSmileIDSampleDecorativeTokens({
    required this.yellow,
    required this.green,
    required this.orange,
    required this.bloodOrange,
    required this.sky,
    required this.pink,
    required this.sand,
    required this.darkGreen,
    required this.deepRed,
  });

  /// Decorative yellow.
  final Color yellow;

  /// Decorative green.
  final Color green;

  /// Decorative orange.
  final Color orange;

  /// Decorative blood orange.
  final Color bloodOrange;

  /// Decorative sky.
  final Color sky;

  /// Decorative pink.
  final Color pink;

  /// Decorative sand.
  final Color sand;

  /// Decorative dark green.
  final Color darkGreen;

  /// Decorative deep red.
  final Color deepRed;

  /// The nine in declaration order, which is how a product or profile indexes a stand-in hue.
  List<Color> get all => <Color>[
    yellow,
    green,
    orange,
    bloodOrange,
    sky,
    pink,
    sand,
    darkGreen,
    deepRed,
  ];
}

/// The semantic tier for one mode plus the component tiers, grouped because the two generated token
/// holders share no supertype and a widget cannot select between them by mode.
@immutable
class UseSmileIDSampleColors extends ThemeExtension<UseSmileIDSampleColors> {
  /// Takes every role a screen can reach, so nothing reads a generated holder directly.
  const UseSmileIDSampleColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceMuted,
    required this.surfaceTile,
    required this.foreground,
    required this.navBar,
    required this.cardStroke,
    required this.border,
    required this.overlayScrim,
    required this.textTitle,
    required this.textBody,
    required this.textMuted,
    required this.textInverse,
    required this.textLink,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.accent,
    required this.focusRing,
    required this.successFill,
    required this.onSuccess,
    required this.warningFill,
    required this.onWarning,
    required this.errorFill,
    required this.onError,
    required this.infoFill,
    required this.onInfo,
    required this.avatar,
    required this.button,
    required this.input,
    required this.search,
    required this.badge,
    required this.dataField,
    required this.filterChip,
    required this.card,
    required this.banner,
    required this.decorative,
  });

  /// The page behind everything.
  final Color background;

  /// A raised surface on the page.
  final Color surface;

  /// The warm alternate surface.
  final Color surfaceAlt;

  /// The muted surface a disabled control sits on.
  final Color surfaceMuted;

  /// The design's `color/surface-2`, generated light-only — see the `surface2` delta.
  final Color surfaceTile;

  /// The design's warm `Off_black`, its strong foreground — not the cooler [textTitle].
  final Color foreground;

  /// The floating nav bar's own fill, recessed in dark and raised in light.
  final Color navBar;

  /// One outline for every card and row. A pair, because `color.border` does not change per mode.
  final Color cardStroke;

  /// The semantic border, which carries the recorded `darkBorder` defect.
  final Color border;

  /// The scrim behind a modal.
  final Color overlayScrim;

  /// Title text.
  final Color textTitle;

  /// Body text.
  final Color textBody;

  /// Muted text, which carries the recorded `darkMuted` finding.
  final Color textMuted;

  /// Text on an inverted surface.
  final Color textInverse;

  /// Link text.
  final Color textLink;

  /// The brand primary.
  final Color primary;

  /// Text and glyphs on [primary].
  final Color onPrimary;

  /// The brand secondary.
  final Color secondary;

  /// The brand accent.
  final Color accent;

  /// The focus ring.
  final Color focusRing;

  /// The success feedback fill.
  final Color successFill;

  /// Text on [successFill].
  final Color onSuccess;

  /// The warning feedback fill.
  final Color warningFill;

  /// Text on [warningFill].
  final Color onWarning;

  /// The error feedback fill.
  final Color errorFill;

  /// Text on [errorFill].
  final Color onError;

  /// The info feedback fill.
  final Color infoFill;

  /// Text on [infoFill].
  final Color onInfo;

  /// The avatar's own tokens.
  final UseSmileIDSampleAvatarTokens avatar;

  /// The buttons' own tokens.
  final UseSmileIDSampleButtonTokens button;

  /// The text fields' own tokens.
  final UseSmileIDSampleInputTokens input;

  /// The search field's own tokens.
  final UseSmileIDSampleSearchTokens search;

  /// The status badges' own tokens, generated from one spec entry rather than the saturated pairs.
  final UseSmileIDSampleBadgeTokens badge;

  /// The label/value rows' own tokens.
  final UseSmileIDSampleDataFieldTokens dataField;

  /// The filter chips' own tokens.
  final UseSmileIDSampleFilterChipTokens filterChip;

  /// The cards' own tokens.
  final UseSmileIDSampleCardTokens card;

  /// The inline banners' own tokens.
  final UseSmileIDSampleBannerTokens banner;

  /// The decorative fills a product or profile indexes into.
  final UseSmileIDSampleDecorativeTokens decorative;

  @override
  UseSmileIDSampleColors copyWith() => this;

  /// A step, not a blend: the Compose twin swaps schemes outright, so an interpolated mode would
  /// put the two apps in states no token source describes.
  @override
  UseSmileIDSampleColors lerp(UseSmileIDSampleColors? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

/// The soft status tints, which no design-system `badge.*` pair carries, and the same in both schemes.
UseSmileIDSampleBadgeTokens softBadgeTokens() {
  SmileSoftBadgeFill fill(String role) {
    final SmileSoftBadgeFill? pair = smileSoftBadgeFills[role];
    if (pair == null) {
      throw StateError(
        "no soft badge fill for '$role'; see spec/design-tokens.json → softBadgeFills",
      );
    }
    return pair;
  }

  return UseSmileIDSampleBadgeTokens(
    successBackground: fill('success').background,
    successText: fill('success').text,
    warningBackground: fill('warning').background,
    warningText: fill('warning').text,
    errorBackground: fill('error').background,
    errorText: fill('error').text,
    infoBackground: fill('info').background,
    infoText: fill('info').text,
  );
}

/// The two resolved schemes. Selected by brightness in the theme, never by a widget.
abstract final class UseSmileIDSampleColorSchemes {
  /// The light scheme.
  static final UseSmileIDSampleColors light = UseSmileIDSampleColors(
    background: SmileColorLight.colorBackground,
    surface: SmileColorLight.colorSurface,
    surfaceAlt: SmileColorLight.colorSurfaceAlt,
    surfaceMuted: SmileColorLight.colorSurfaceMuted,
    surfaceTile: smileSurface2,
    foreground: smileOffBlackLight,
    navBar: smileNavBarLight,
    cardStroke: smileCardStrokeLight,
    border: SmileColorLight.colorBorder,
    overlayScrim: SmileColorLight.colorOverlayScrim,
    textTitle: SmileColorLight.colorTextTitle,
    textBody: SmileColorLight.colorTextBody,
    textMuted: SmileColorLight.colorTextMuted,
    textInverse: SmileColorLight.colorTextInverse,
    textLink: SmileColorLight.colorTextLink,
    primary: SmileColorLight.colorPrimary,
    onPrimary: SmileColorLight.colorOnPrimary,
    secondary: SmileColorLight.colorSecondary,
    accent: SmileColorLight.colorAccent,
    focusRing: SmileColorLight.colorFocusRing,
    successFill: SmileColorLight.colorFeedbackSuccessFill,
    onSuccess: SmileColorLight.colorFeedbackSuccessOn,
    warningFill: SmileColorLight.colorFeedbackWarningFill,
    onWarning: SmileColorLight.colorFeedbackWarningOn,
    errorFill: SmileColorLight.colorFeedbackErrorFill,
    onError: SmileColorLight.colorFeedbackErrorOn,
    infoFill: SmileColorLight.colorFeedbackInfoFill,
    onInfo: SmileColorLight.colorFeedbackInfoOn,
    avatar: UseSmileIDSampleAvatarTokens(
      background: SmileColorLight.avatarBg,
      text: SmileColorLight.avatarText,
      placeholderBackground: SmileColorLight.avatarPlaceholderBg,
      placeholderIcon: SmileColorLight.avatarPlaceholderIcon,
    ),
    button: UseSmileIDSampleButtonTokens(
      primaryBackground: SmileColorLight.buttonPrimaryBackground,
      primaryText: SmileColorLight.buttonPrimaryText,
      disabledBackground: SmileColorLight.buttonDisabledBackground,
      disabledText: SmileColorLight.buttonDisabledText,
    ),
    input: UseSmileIDSampleInputTokens(
      background: SmileColorLight.inputBackground,
      text: SmileColorLight.inputText,
      placeholder: SmileColorLight.inputPlaceholder,
      border: SmileColorLight.inputBorder,
      borderFocus: SmileColorLight.inputBorderFocus,
      borderError: SmileColorLight.inputBorderError,
    ),
    search: UseSmileIDSampleSearchTokens(
      background: SmileColorLight.searchBackground,
      text: SmileColorLight.searchText,
      placeholder: SmileColorLight.searchPlaceholder,
      icon: SmileColorLight.searchIcon,
      border: SmileColorLight.searchBorder,
      borderFocus: SmileColorLight.searchBorderFocus,
    ),
    badge: softBadgeTokens(),
    dataField: UseSmileIDSampleDataFieldTokens(
      label: SmileColorLight.dataFieldLabel,
      value: SmileColorLight.dataFieldValue,
      valueLink: SmileColorLight.dataFieldValueLink,
    ),
    filterChip: UseSmileIDSampleFilterChipTokens(
      background: SmileColorLight.filterChipBg,
      border: SmileColorLight.filterChipBorder,
      label: SmileColorLight.filterChipLabel,
      value: SmileColorLight.filterChipValue,
      divider: SmileColorLight.filterChipDivider,
    ),
    card: UseSmileIDSampleCardTokens(
      background: SmileColorLight.cardBackground,
      border: SmileColorLight.cardBorder,
      title: SmileColorLight.cardTitleText,
      body: SmileColorLight.cardBodyText,
    ),
    banner: UseSmileIDSampleBannerTokens(
      background: SmileColorLight.bannerBg,
      border: SmileColorLight.bannerBorder,
      title: SmileColorLight.bannerTitle,
      text: SmileColorLight.bannerText,
    ),
    decorative: UseSmileIDSampleDecorativeTokens(
      yellow: SmileColorLight.colorDecorativeYellow,
      green: SmileColorLight.colorDecorativeGreen,
      orange: SmileColorLight.colorDecorativeOrange,
      bloodOrange: SmileColorLight.colorDecorativeBloodOrange,
      sky: SmileColorLight.colorDecorativeSky,
      pink: SmileColorLight.colorDecorativePink,
      sand: SmileColorLight.colorDecorativeSand,
      darkGreen: SmileColorLight.colorDecorativeDarkGreen,
      deepRed: SmileColorLight.colorDecorativeDeepRed,
    ),
  );

  /// The dark scheme.
  static final UseSmileIDSampleColors dark = UseSmileIDSampleColors(
    background: SmileColorDark.colorBackground,
    surface: SmileColorDark.colorSurface,
    surfaceAlt: SmileColorDark.colorSurfaceAlt,
    surfaceMuted: SmileColorDark.colorSurfaceMuted,
    surfaceTile: SmileColorDark.colorSurfaceMuted,
    foreground: smileOffBlackDark,
    navBar: smileNavBarDark,
    cardStroke: smileCardStrokeDark,
    border: SmileColorDark.colorBorder,
    overlayScrim: SmileColorDark.colorOverlayScrim,
    textTitle: SmileColorDark.colorTextTitle,
    textBody: SmileColorDark.colorTextBody,
    textMuted: SmileColorDark.colorTextMuted,
    textInverse: SmileColorDark.colorTextInverse,
    textLink: SmileColorDark.colorTextLink,
    primary: SmileColorDark.colorPrimary,
    onPrimary: SmileColorDark.colorOnPrimary,
    secondary: SmileColorDark.colorSecondary,
    accent: SmileColorDark.colorAccent,
    focusRing: SmileColorDark.colorFocusRing,
    successFill: SmileColorDark.colorFeedbackSuccessFill,
    onSuccess: SmileColorDark.colorFeedbackSuccessOn,
    warningFill: SmileColorDark.colorFeedbackWarningFill,
    onWarning: SmileColorDark.colorFeedbackWarningOn,
    errorFill: SmileColorDark.colorFeedbackErrorFill,
    onError: SmileColorDark.colorFeedbackErrorOn,
    infoFill: SmileColorDark.colorFeedbackInfoFill,
    onInfo: SmileColorDark.colorFeedbackInfoOn,
    avatar: UseSmileIDSampleAvatarTokens(
      background: SmileColorDark.avatarBg,
      text: SmileColorDark.avatarText,
      placeholderBackground: SmileColorDark.avatarPlaceholderBg,
      placeholderIcon: SmileColorDark.avatarPlaceholderIcon,
    ),
    button: UseSmileIDSampleButtonTokens(
      primaryBackground: SmileColorDark.buttonPrimaryBackground,
      primaryText: SmileColorDark.buttonPrimaryText,
      disabledBackground: SmileColorDark.buttonDisabledBackground,
      disabledText: SmileColorDark.buttonDisabledText,
    ),
    input: UseSmileIDSampleInputTokens(
      background: SmileColorDark.inputBackground,
      text: SmileColorDark.inputText,
      placeholder: SmileColorDark.inputPlaceholder,
      border: SmileColorDark.inputBorder,
      borderFocus: SmileColorDark.inputBorderFocus,
      borderError: SmileColorDark.inputBorderError,
    ),
    search: UseSmileIDSampleSearchTokens(
      background: SmileColorDark.searchBackground,
      text: SmileColorDark.searchText,
      placeholder: SmileColorDark.searchPlaceholder,
      icon: SmileColorDark.searchIcon,
      border: SmileColorDark.searchBorder,
      borderFocus: SmileColorDark.searchBorderFocus,
    ),
    badge: softBadgeTokens(),
    dataField: UseSmileIDSampleDataFieldTokens(
      label: SmileColorDark.dataFieldLabel,
      value: SmileColorDark.dataFieldValue,
      valueLink: SmileColorDark.dataFieldValueLink,
    ),
    filterChip: UseSmileIDSampleFilterChipTokens(
      background: SmileColorDark.filterChipBg,
      border: SmileColorDark.filterChipBorder,
      label: SmileColorDark.filterChipLabel,
      value: SmileColorDark.filterChipValue,
      divider: SmileColorDark.filterChipDivider,
    ),
    card: UseSmileIDSampleCardTokens(
      background: SmileColorDark.cardBackground,
      border: SmileColorDark.cardBorder,
      title: SmileColorDark.cardTitleText,
      body: SmileColorDark.cardBodyText,
    ),
    banner: UseSmileIDSampleBannerTokens(
      background: SmileColorDark.bannerBg,
      border: SmileColorDark.bannerBorder,
      title: SmileColorDark.bannerTitle,
      text: SmileColorDark.bannerText,
    ),
    decorative: UseSmileIDSampleDecorativeTokens(
      yellow: SmileColorDark.colorDecorativeYellow,
      green: SmileColorDark.colorDecorativeGreen,
      orange: SmileColorDark.colorDecorativeOrange,
      bloodOrange: SmileColorDark.colorDecorativeBloodOrange,
      sky: SmileColorDark.colorDecorativeSky,
      pink: SmileColorDark.colorDecorativePink,
      sand: SmileColorDark.colorDecorativeSand,
      darkGreen: SmileColorDark.colorDecorativeDarkGreen,
      deepRed: SmileColorDark.colorDecorativeDeepRed,
    ),
  );
}
