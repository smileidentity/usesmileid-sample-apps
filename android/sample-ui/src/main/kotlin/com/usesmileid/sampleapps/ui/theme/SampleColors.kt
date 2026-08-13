package com.usesmileid.sampleapps.ui.theme

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import com.smileid.designsystem.SmileColorDark
import com.smileid.designsystem.SmileColorLight

/**
 * The design system's **semantic** colour tier, resolved for one mode.
 *
 * Only semantic tokens live here. Component tokens (`badge.*`, `input.*`, …) are read straight
 * from [SmileColorLight] / [SmileColorDark] by the component that owns them, and primitives are
 * never referenced from app code. See `spec/design-tokens.json`.
 */
@Immutable
data class SampleColors(
    val background: Color,
    val surface: Color,
    val surfaceAlt: Color,
    val surfaceMuted: Color,
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
)

internal val sampleLightColors = SampleColors(
    background = SmileColorLight.colorBackground,
    surface = SmileColorLight.colorSurface,
    surfaceAlt = SmileColorLight.colorSurfaceAlt,
    surfaceMuted = SmileColorLight.colorSurfaceMuted,
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
)

internal val sampleDarkColors = SampleColors(
    background = SmileColorDark.colorBackground,
    surface = SmileColorDark.colorSurface,
    surfaceAlt = SmileColorDark.colorSurfaceAlt,
    surfaceMuted = SmileColorDark.colorSurfaceMuted,
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
)

internal val LocalSampleColors = staticCompositionLocalOf { sampleLightColors }
