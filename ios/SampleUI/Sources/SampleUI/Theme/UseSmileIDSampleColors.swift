import SwiftUI

/// One component's tokens, resolved for the active mode.
public struct UseSmileIDSampleAvatarTokens: Equatable, Sendable {
  public let background: Color
  public let text: Color
  public let placeholderBackground: Color
  public let placeholderIcon: Color
}

/// Colours the buttons draw: one background/text pair per enabled state.
public struct UseSmileIDSampleButtonTokens: Equatable, Sendable {
  public let primaryBackground: Color
  public let primaryText: Color
  public let disabledBackground: Color
  public let disabledText: Color
}

/// Colours the text fields draw, including the focus and error borders.
public struct UseSmileIDSampleInputTokens: Equatable, Sendable {
  public let background: Color
  public let text: Color
  public let placeholder: Color
  public let border: Color
  public let borderFocus: Color
  public let borderError: Color
}

public struct UseSmileIDSampleSearchTokens: Equatable, Sendable {
  public let background: Color
  public let text: Color
  public let placeholder: Color
  public let icon: Color
  public let border: Color
  public let borderFocus: Color
}

/// One background/text pair per feedback role the four job statuses map onto.
public struct UseSmileIDSampleBadgeTokens: Equatable, Sendable {
  public let successBackground: Color
  public let successText: Color
  public let warningBackground: Color
  public let warningText: Color
  public let errorBackground: Color
  public let errorText: Color
  public let infoBackground: Color
  public let infoText: Color
}

public struct UseSmileIDSampleDataFieldTokens: Equatable, Sendable {
  public let label: Color
  public let value: Color
  public let valueLink: Color
}

public struct UseSmileIDSampleFilterChipTokens: Equatable, Sendable {
  public let background: Color
  public let border: Color
  public let label: Color
  public let value: Color
  public let divider: Color
}

public struct UseSmileIDSampleCardTokens: Equatable, Sendable {
  public let background: Color
  public let border: Color
  public let title: Color
  public let body: Color
}

public struct UseSmileIDSampleBannerTokens: Equatable, Sendable {
  public let background: Color
  public let border: Color
  public let title: Color
  public let text: Color
}

public struct UseSmileIDSampleDecorativeTokens: Equatable, Sendable {
  public let yellow: Color
  public let green: Color
  public let orange: Color
  public let bloodOrange: Color
  public let sky: Color
  public let pink: Color
  public let sand: Color
  public let darkGreen: Color
  public let deepRed: Color
}

/// Every colour the app draws, already resolved for one scheme.
///
/// Grouped here rather than read from `SmileColorLight` / `SmileColorDark` at the use site, because
/// those are two unrelated generated enums with no common type — a component cannot choose between
/// them itself. The Compose twin is `UseSmileIDSampleColors.kt` and the two carry the same fields.
public struct UseSmileIDSampleColors: Equatable, Sendable {
  public let background: Color
  public let surface: Color
  public let surfaceAlt: Color
  public let surfaceMuted: Color
  /// The design's `color/surface-2` — see the `surface2` delta in `spec/design-tokens.json`.
  public let surfaceTile: Color
  /// The design's warm `Off_black`, its strong foreground — not the cooler ``textTitle``.
  public let foreground: Color
  /// The floating nav bar's own fill: recessed from the page in dark, raised in light.
  public let navBar: Color
  /// One outline for every card and row. A PAIR, because `color.border` is near-white in both schemes.
  public let cardStroke: Color
  public let border: Color
  public let overlayScrim: Color
  public let textTitle: Color
  public let textBody: Color
  public let textMuted: Color
  public let textInverse: Color
  public let textLink: Color
  public let primary: Color
  public let onPrimary: Color
  public let secondary: Color
  public let accent: Color
  public let focusRing: Color
  public let successFill: Color
  public let onSuccess: Color
  public let warningFill: Color
  public let onWarning: Color
  public let errorFill: Color
  public let onError: Color
  public let infoFill: Color
  public let onInfo: Color
  public let avatar: UseSmileIDSampleAvatarTokens
  public let button: UseSmileIDSampleButtonTokens
  public let input: UseSmileIDSampleInputTokens
  public let search: UseSmileIDSampleSearchTokens
  public let badge: UseSmileIDSampleBadgeTokens
  public let dataField: UseSmileIDSampleDataFieldTokens
  public let filterChip: UseSmileIDSampleFilterChipTokens
  public let card: UseSmileIDSampleCardTokens
  public let banner: UseSmileIDSampleBannerTokens
  public let decorative: UseSmileIDSampleDecorativeTokens
}

/// Soft status tints, which no design-system `badge.*` pair carries. Generated from
/// `spec/design-tokens.json` → softBadgeFills, and the same in both schemes.
private func softBadgeTokens() -> UseSmileIDSampleBadgeTokens {
  func fill(_ role: String) -> SmileSoftBadgeFill {
    guard let fill = smileSoftBadgeFills[role] else {
      preconditionFailure("no soft badge fill for '\(role)'; see spec/design-tokens.json → softBadgeFills")
    }
    return fill
  }
  return UseSmileIDSampleBadgeTokens(
    successBackground: fill("success").background,
    successText: fill("success").text,
    warningBackground: fill("warning").background,
    warningText: fill("warning").text,
    errorBackground: fill("error").background,
    errorText: fill("error").text,
    infoBackground: fill("info").background,
    infoText: fill("info").text
  )
}

public extension UseSmileIDSampleColors {
  static let light = UseSmileIDSampleColors(
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
      placeholderIcon: SmileColorLight.avatarPlaceholderIcon
    ),
    button: UseSmileIDSampleButtonTokens(
      primaryBackground: SmileColorLight.buttonPrimaryBackground,
      primaryText: SmileColorLight.buttonPrimaryText,
      disabledBackground: SmileColorLight.buttonDisabledBackground,
      disabledText: SmileColorLight.buttonDisabledText
    ),
    input: UseSmileIDSampleInputTokens(
      background: SmileColorLight.inputBackground,
      text: SmileColorLight.inputText,
      placeholder: SmileColorLight.inputPlaceholder,
      border: SmileColorLight.inputBorder,
      borderFocus: SmileColorLight.inputBorderFocus,
      borderError: SmileColorLight.inputBorderError
    ),
    search: UseSmileIDSampleSearchTokens(
      background: SmileColorLight.searchBackground,
      text: SmileColorLight.searchText,
      placeholder: SmileColorLight.searchPlaceholder,
      icon: SmileColorLight.searchIcon,
      border: SmileColorLight.searchBorder,
      borderFocus: SmileColorLight.searchBorderFocus
    ),
    badge: softBadgeTokens(),
    dataField: UseSmileIDSampleDataFieldTokens(
      label: SmileColorLight.dataFieldLabel,
      value: SmileColorLight.dataFieldValue,
      valueLink: SmileColorLight.dataFieldValueLink
    ),
    filterChip: UseSmileIDSampleFilterChipTokens(
      background: SmileColorLight.filterChipBg,
      border: SmileColorLight.filterChipBorder,
      label: SmileColorLight.filterChipLabel,
      value: SmileColorLight.filterChipValue,
      divider: SmileColorLight.filterChipDivider
    ),
    card: UseSmileIDSampleCardTokens(
      background: SmileColorLight.cardBackground,
      border: SmileColorLight.cardBorder,
      title: SmileColorLight.cardTitleText,
      body: SmileColorLight.cardBodyText
    ),
    banner: UseSmileIDSampleBannerTokens(
      background: SmileColorLight.bannerBg,
      border: SmileColorLight.bannerBorder,
      title: SmileColorLight.bannerTitle,
      text: SmileColorLight.bannerText
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
      deepRed: SmileColorLight.colorDecorativeDeepRed
    )
  )

  static let dark = UseSmileIDSampleColors(
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
      placeholderIcon: SmileColorDark.avatarPlaceholderIcon
    ),
    button: UseSmileIDSampleButtonTokens(
      primaryBackground: SmileColorDark.buttonPrimaryBackground,
      primaryText: SmileColorDark.buttonPrimaryText,
      disabledBackground: SmileColorDark.buttonDisabledBackground,
      disabledText: SmileColorDark.buttonDisabledText
    ),
    input: UseSmileIDSampleInputTokens(
      background: SmileColorDark.inputBackground,
      text: SmileColorDark.inputText,
      placeholder: SmileColorDark.inputPlaceholder,
      border: SmileColorDark.inputBorder,
      borderFocus: SmileColorDark.inputBorderFocus,
      borderError: SmileColorDark.inputBorderError
    ),
    search: UseSmileIDSampleSearchTokens(
      background: SmileColorDark.searchBackground,
      text: SmileColorDark.searchText,
      placeholder: SmileColorDark.searchPlaceholder,
      icon: SmileColorDark.searchIcon,
      border: SmileColorDark.searchBorder,
      borderFocus: SmileColorDark.searchBorderFocus
    ),
    badge: softBadgeTokens(),
    dataField: UseSmileIDSampleDataFieldTokens(
      label: SmileColorDark.dataFieldLabel,
      value: SmileColorDark.dataFieldValue,
      valueLink: SmileColorDark.dataFieldValueLink
    ),
    filterChip: UseSmileIDSampleFilterChipTokens(
      background: SmileColorDark.filterChipBg,
      border: SmileColorDark.filterChipBorder,
      label: SmileColorDark.filterChipLabel,
      value: SmileColorDark.filterChipValue,
      divider: SmileColorDark.filterChipDivider
    ),
    card: UseSmileIDSampleCardTokens(
      background: SmileColorDark.cardBackground,
      border: SmileColorDark.cardBorder,
      title: SmileColorDark.cardTitleText,
      body: SmileColorDark.cardBodyText
    ),
    banner: UseSmileIDSampleBannerTokens(
      background: SmileColorDark.bannerBg,
      border: SmileColorDark.bannerBorder,
      title: SmileColorDark.bannerTitle,
      text: SmileColorDark.bannerText
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
      deepRed: SmileColorDark.colorDecorativeDeepRed
    )
  )
}
