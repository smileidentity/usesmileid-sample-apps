package com.usesmileid.sampleapps.ui.theme

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import com.smileid.designsystem.SmileColorDark
import com.smileid.designsystem.SmileColorLight
import com.smileid.designsystem.smileSoftBadgeFills
import com.smileid.designsystem.smileSurface2

/** One component's tokens, resolved for the active mode. */
@Immutable
data class AvatarTokens(val background: Color, val text: Color, val placeholderBackground: Color, val placeholderIcon: Color)

@Immutable
data class ButtonTokens(
    val primaryBackground: Color,
    val primaryText: Color,
    val disabledBackground: Color,
    val disabledText: Color,
)

@Immutable
data class InputTokens(
    val background: Color,
    val text: Color,
    val placeholder: Color,
    val border: Color,
    val borderFocus: Color,
    val borderError: Color,
)

@Immutable
data class SearchTokens(
    val background: Color,
    val text: Color,
    val placeholder: Color,
    val icon: Color,
    val border: Color,
    val borderFocus: Color,
)

@Immutable
data class BadgeTokens(
    val successBackground: Color,
    val successText: Color,
    val warningBackground: Color,
    val warningText: Color,
    val errorBackground: Color,
    val errorText: Color,
    val infoBackground: Color,
    val infoText: Color,
)

@Immutable
data class DataFieldTokens(val label: Color, val value: Color, val valueLink: Color)

@Immutable
data class FilterChipTokens(
    val background: Color,
    val border: Color,
    val label: Color,
    val value: Color,
    val divider: Color,
)

@Immutable
data class CardTokens(val background: Color, val border: Color, val title: Color, val body: Color)

@Immutable
data class BannerTokens(val background: Color, val border: Color, val title: Color, val text: Color)

/** The product and profile fills. Which hue belongs to which product is the designer's list, still outstanding, so callers pass one explicitly rather than this deciding. */
@Immutable
data class DecorativeTokens(
    val yellow: Color,
    val green: Color,
    val orange: Color,
    val bloodOrange: Color,
    val sky: Color,
    val pink: Color,
    val sand: Color,
    val darkGreen: Color,
    val deepRed: Color,
) {
    val all: List<Color> get() = listOf(yellow, green, orange, bloodOrange, sky, pink, sand, darkGreen, deepRed)
}

/** The semantic tier for one mode, plus the component tiers. Grouped here because [SmileColorLight] and [SmileColorDark] share no supertype, so a component cannot select between them by mode. */
@Immutable
data class UseSmileIDSampleColors(
    val background: Color,
    val surface: Color,
    val surfaceAlt: Color,
    val surfaceMuted: Color,
    /** The design's `color/surface-2`, paired here because it is generated light-only — see the `surface2` delta in `spec/design-tokens.json`. */
    val surfaceTile: Color,
    val border: Color,
    val overlayScrim: Color,
    val textTitle: Color,
    val textBody: Color,
    val textMuted: Color,
    val textInverse: Color,
    val textLink: Color,
    val primary: Color,
    val onPrimary: Color,
    val secondary: Color,
    val accent: Color,
    val focusRing: Color,
    val successFill: Color,
    val onSuccess: Color,
    val warningFill: Color,
    val onWarning: Color,
    val errorFill: Color,
    val onError: Color,
    val infoFill: Color,
    val onInfo: Color,
    val avatar: AvatarTokens,
    val button: ButtonTokens,
    val input: InputTokens,
    val search: SearchTokens,
    val badge: BadgeTokens,
    val dataField: DataFieldTokens,
    val filterChip: FilterChipTokens,
    val card: CardTokens,
    val banner: BannerTokens,
    val decorative: DecorativeTokens,
)

internal val lightColors = UseSmileIDSampleColors(
    background = SmileColorLight.colorBackground,
    surface = SmileColorLight.colorSurface,
    surfaceAlt = SmileColorLight.colorSurfaceAlt,
    surfaceMuted = SmileColorLight.colorSurfaceMuted,
    surfaceTile = smileSurface2,
    border = SmileColorLight.colorBorder,
    overlayScrim = SmileColorLight.colorOverlayScrim,
    textTitle = SmileColorLight.colorTextTitle,
    textBody = SmileColorLight.colorTextBody,
    textMuted = SmileColorLight.colorTextMuted,
    textInverse = SmileColorLight.colorTextInverse,
    textLink = SmileColorLight.colorTextLink,
    primary = SmileColorLight.colorPrimary,
    onPrimary = SmileColorLight.colorOnPrimary,
    secondary = SmileColorLight.colorSecondary,
    accent = SmileColorLight.colorAccent,
    focusRing = SmileColorLight.colorFocusRing,
    successFill = SmileColorLight.colorFeedbackSuccessFill,
    onSuccess = SmileColorLight.colorFeedbackSuccessOn,
    warningFill = SmileColorLight.colorFeedbackWarningFill,
    onWarning = SmileColorLight.colorFeedbackWarningOn,
    errorFill = SmileColorLight.colorFeedbackErrorFill,
    onError = SmileColorLight.colorFeedbackErrorOn,
    infoFill = SmileColorLight.colorFeedbackInfoFill,
    onInfo = SmileColorLight.colorFeedbackInfoOn,
    avatar = AvatarTokens(
        background = SmileColorLight.avatarBg,
        text = SmileColorLight.avatarText,
        placeholderBackground = SmileColorLight.avatarPlaceholderBg,
        placeholderIcon = SmileColorLight.avatarPlaceholderIcon,
    ),
    button = ButtonTokens(
        primaryBackground = SmileColorLight.buttonPrimaryBackground,
        primaryText = SmileColorLight.buttonPrimaryText,
        disabledBackground = SmileColorLight.buttonDisabledBackground,
        disabledText = SmileColorLight.buttonDisabledText,
    ),
    input = InputTokens(
        background = SmileColorLight.inputBackground,
        text = SmileColorLight.inputText,
        placeholder = SmileColorLight.inputPlaceholder,
        border = SmileColorLight.inputBorder,
        borderFocus = SmileColorLight.inputBorderFocus,
        borderError = SmileColorLight.inputBorderError,
    ),
    search = SearchTokens(
        background = SmileColorLight.searchBackground,
        text = SmileColorLight.searchText,
        placeholder = SmileColorLight.searchPlaceholder,
        icon = SmileColorLight.searchIcon,
        border = SmileColorLight.searchBorder,
        borderFocus = SmileColorLight.searchBorderFocus,
    ),
    badge = softBadgeTokens(),
    dataField = DataFieldTokens(
        label = SmileColorLight.dataFieldLabel,
        value = SmileColorLight.dataFieldValue,
        valueLink = SmileColorLight.dataFieldValueLink,
    ),
    filterChip = FilterChipTokens(
        background = SmileColorLight.filterChipBg,
        border = SmileColorLight.filterChipBorder,
        label = SmileColorLight.filterChipLabel,
        value = SmileColorLight.filterChipValue,
        divider = SmileColorLight.filterChipDivider,
    ),
    card = CardTokens(
        background = SmileColorLight.cardBackground,
        border = SmileColorLight.cardBorder,
        title = SmileColorLight.cardTitleText,
        body = SmileColorLight.cardBodyText,
    ),
    banner = BannerTokens(
        background = SmileColorLight.bannerBg,
        border = SmileColorLight.bannerBorder,
        title = SmileColorLight.bannerTitle,
        text = SmileColorLight.bannerText,
    ),
    decorative = DecorativeTokens(
        yellow = SmileColorLight.colorDecorativeYellow,
        green = SmileColorLight.colorDecorativeGreen,
        orange = SmileColorLight.colorDecorativeOrange,
        bloodOrange = SmileColorLight.colorDecorativeBloodOrange,
        sky = SmileColorLight.colorDecorativeSky,
        pink = SmileColorLight.colorDecorativePink,
        sand = SmileColorLight.colorDecorativeSand,
        darkGreen = SmileColorLight.colorDecorativeDarkGreen,
        deepRed = SmileColorLight.colorDecorativeDeepRed,
    ),
)

internal val darkColors = UseSmileIDSampleColors(
    background = SmileColorDark.colorBackground,
    surface = SmileColorDark.colorSurface,
    surfaceAlt = SmileColorDark.colorSurfaceAlt,
    surfaceMuted = SmileColorDark.colorSurfaceMuted,
    // Recessed against the dark card the way surface-2 is against a white one.
    surfaceTile = SmileColorDark.colorSurfaceMuted,
    border = SmileColorDark.colorBorder,
    overlayScrim = SmileColorDark.colorOverlayScrim,
    textTitle = SmileColorDark.colorTextTitle,
    textBody = SmileColorDark.colorTextBody,
    textMuted = SmileColorDark.colorTextMuted,
    textInverse = SmileColorDark.colorTextInverse,
    textLink = SmileColorDark.colorTextLink,
    primary = SmileColorDark.colorPrimary,
    onPrimary = SmileColorDark.colorOnPrimary,
    secondary = SmileColorDark.colorSecondary,
    accent = SmileColorDark.colorAccent,
    focusRing = SmileColorDark.colorFocusRing,
    successFill = SmileColorDark.colorFeedbackSuccessFill,
    onSuccess = SmileColorDark.colorFeedbackSuccessOn,
    warningFill = SmileColorDark.colorFeedbackWarningFill,
    onWarning = SmileColorDark.colorFeedbackWarningOn,
    errorFill = SmileColorDark.colorFeedbackErrorFill,
    onError = SmileColorDark.colorFeedbackErrorOn,
    infoFill = SmileColorDark.colorFeedbackInfoFill,
    onInfo = SmileColorDark.colorFeedbackInfoOn,
    avatar = AvatarTokens(
        background = SmileColorDark.avatarBg,
        text = SmileColorDark.avatarText,
        placeholderBackground = SmileColorDark.avatarPlaceholderBg,
        placeholderIcon = SmileColorDark.avatarPlaceholderIcon,
    ),
    button = ButtonTokens(
        primaryBackground = SmileColorDark.buttonPrimaryBackground,
        primaryText = SmileColorDark.buttonPrimaryText,
        disabledBackground = SmileColorDark.buttonDisabledBackground,
        disabledText = SmileColorDark.buttonDisabledText,
    ),
    input = InputTokens(
        background = SmileColorDark.inputBackground,
        text = SmileColorDark.inputText,
        placeholder = SmileColorDark.inputPlaceholder,
        border = SmileColorDark.inputBorder,
        borderFocus = SmileColorDark.inputBorderFocus,
        borderError = SmileColorDark.inputBorderError,
    ),
    search = SearchTokens(
        background = SmileColorDark.searchBackground,
        text = SmileColorDark.searchText,
        placeholder = SmileColorDark.searchPlaceholder,
        icon = SmileColorDark.searchIcon,
        border = SmileColorDark.searchBorder,
        borderFocus = SmileColorDark.searchBorderFocus,
    ),
    badge = softBadgeTokens(),
    dataField = DataFieldTokens(
        label = SmileColorDark.dataFieldLabel,
        value = SmileColorDark.dataFieldValue,
        valueLink = SmileColorDark.dataFieldValueLink,
    ),
    filterChip = FilterChipTokens(
        background = SmileColorDark.filterChipBg,
        border = SmileColorDark.filterChipBorder,
        label = SmileColorDark.filterChipLabel,
        value = SmileColorDark.filterChipValue,
        divider = SmileColorDark.filterChipDivider,
    ),
    card = CardTokens(
        background = SmileColorDark.cardBackground,
        border = SmileColorDark.cardBorder,
        title = SmileColorDark.cardTitleText,
        body = SmileColorDark.cardBodyText,
    ),
    banner = BannerTokens(
        background = SmileColorDark.bannerBg,
        border = SmileColorDark.bannerBorder,
        title = SmileColorDark.bannerTitle,
        text = SmileColorDark.bannerText,
    ),
    decorative = DecorativeTokens(
        yellow = SmileColorDark.colorDecorativeYellow,
        green = SmileColorDark.colorDecorativeGreen,
        orange = SmileColorDark.colorDecorativeOrange,
        bloodOrange = SmileColorDark.colorDecorativeBloodOrange,
        sky = SmileColorDark.colorDecorativeSky,
        pink = SmileColorDark.colorDecorativePink,
        sand = SmileColorDark.colorDecorativeSand,
        darkGreen = SmileColorDark.colorDecorativeDarkGreen,
        deepRed = SmileColorDark.colorDecorativeDeepRed,
    ),
)

/** Soft status tints, which no design-system `badge.*` pair carries. Generated from `spec/design-tokens.json` → softBadgeFills, and the same in both schemes. */
private fun softBadgeTokens(): BadgeTokens {
    fun fill(role: String) = requireNotNull(smileSoftBadgeFills[role]) {
        "no soft badge fill for '$role'; see spec/design-tokens.json → softBadgeFills"
    }
    return BadgeTokens(
        successBackground = fill("success").background,
        successText = fill("success").text,
        warningBackground = fill("warning").background,
        warningText = fill("warning").text,
        errorBackground = fill("error").background,
        errorText = fill("error").text,
        infoBackground = fill("info").background,
        infoText = fill("info").text,
    )
}

internal val LocalUseSmileIDSampleColors = staticCompositionLocalOf { lightColors }
