package com.usesmileid.sampleapps.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.ReadOnlyComposable
import com.smileid.designsystem.SmileDimens

/** The Compose theme, built entirely from the vendored design-system tokens. */
@Composable
fun UseSmileIDSampleTheme(darkTheme: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    val colors = if (darkTheme) darkColors else lightColors
    CompositionLocalProvider(LocalUseSmileIDSampleColors provides colors) {
        MaterialTheme(
            colorScheme = colors.toMaterialColorScheme(darkTheme),
            shapes = shapes,
            typography = typography,
            content = content,
        )
    }
}

/** Token accessors for anything Material 3 has no slot for. */
object UseSmileIDSampleTheme {
    val colors: UseSmileIDSampleColors
        @Composable @ReadOnlyComposable get() = LocalUseSmileIDSampleColors.current

    val dimens = SmileDimens

    /** The full ramp, for the styles Material has no slot for. */
    val type = smileTypeStyles

    val shapes = UseSmileIDSampleShapes
}

/** One shape per named surface. The radius still comes from [SmileDimens]; this fixes where it is applied. */
object UseSmileIDSampleShapes {
    val card = RoundedCornerShape(SmileDimens.radiusSurface)
    val tile = RoundedCornerShape(SmileDimens.radiusLg)
    val field = RoundedCornerShape(SmileDimens.radiusField)
    val pill = RoundedCornerShape(SmileDimens.radiusPill)
    val chip = RoundedCornerShape(SmileDimens.radiusChip)
    val sheet = RoundedCornerShape(topStart = SmileDimens.radiusSheet, topEnd = SmileDimens.radiusSheet)
}

/** The SDK maps the same tokens onto the same slots, keeping host chrome and flow continuous. */
private fun UseSmileIDSampleColors.toMaterialColorScheme(darkTheme: Boolean) = if (darkTheme) {
    darkColorScheme(
        primary = primary,
        onPrimary = onPrimary,
        secondary = secondary,
        tertiary = accent,
        background = background,
        onBackground = textTitle,
        surface = surface,
        onSurface = textTitle,
        surfaceVariant = surfaceAlt,
        onSurfaceVariant = textBody,
        outline = border,
        error = errorFill,
        onError = onError,
        scrim = overlayScrim,
    )
} else {
    lightColorScheme(
        primary = primary,
        onPrimary = onPrimary,
        secondary = secondary,
        tertiary = accent,
        background = background,
        onBackground = textTitle,
        surface = surface,
        onSurface = textTitle,
        surfaceVariant = surfaceAlt,
        onSurfaceVariant = textBody,
        outline = border,
        error = errorFill,
        onError = onError,
        scrim = overlayScrim,
    )
}

private val shapes = Shapes(
    extraSmall = RoundedCornerShape(SmileDimens.radiusSm),
    small = RoundedCornerShape(SmileDimens.radiusSm),
    medium = RoundedCornerShape(SmileDimens.radiusMd),
    large = RoundedCornerShape(SmileDimens.radiusLg),
    extraLarge = RoundedCornerShape(SmileDimens.radiusXl),
)
