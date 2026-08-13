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

/**
 * The sample apps' Compose theme, built entirely from the vendored design-system tokens.
 *
 * `SmileTokens.kt` is copied verbatim from the design system by
 * `scripts/sync_design_tokens.py`, which is why it keeps its upstream
 * `com.smileid.designsystem` package rather than one under this module.
 *
 * Deliberately not wired yet:
 * - **Typography.** The Compose token output emits type styles as comments only, because it
 *   needs font resources wired first, so there are no values to map. The DM Sans resources and
 *   the [MaterialTheme.typography] mapping land with the primitives (U1).
 * - **The SDK's `ThemeConfiguration`.** Theme *scenarios* drive that public override at the flow
 *   boundary; it is not where token values come from. See `spec/design-tokens.json`.
 */
@Composable
fun SampleTheme(darkTheme: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    val colors = if (darkTheme) sampleDarkColors else sampleLightColors
    CompositionLocalProvider(LocalSampleColors provides colors) {
        MaterialTheme(
            colorScheme = colors.toMaterialColorScheme(darkTheme),
            shapes = sampleShapes,
            content = content,
        )
    }
}

/** Token accessors for anything Material 3 has no slot for. Mirrors the `MaterialTheme` shape. */
object SampleTheme {
    val colors: SampleColors
        @Composable @ReadOnlyComposable get() = LocalSampleColors.current

    /** Spacing, radii, border widths and control sizes, straight from the token source. */
    val dimens = SmileDimens
}

/**
 * Maps the semantic tokens onto the Material 3 slots so stock Material components render
 * on-brand instead of falling back to the baseline purple palette. The SDK maps the same tokens
 * onto the same slots internally, which is what keeps host chrome and flow visually continuous.
 */
private fun SampleColors.toMaterialColorScheme(darkTheme: Boolean) = if (darkTheme) {
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

private val sampleShapes = Shapes(
    extraSmall = RoundedCornerShape(SmileDimens.radiusSm),
    small = RoundedCornerShape(SmileDimens.radiusSm),
    medium = RoundedCornerShape(SmileDimens.radiusMd),
    large = RoundedCornerShape(SmileDimens.radiusLg),
    extraLarge = RoundedCornerShape(SmileDimens.radiusXl),
)
