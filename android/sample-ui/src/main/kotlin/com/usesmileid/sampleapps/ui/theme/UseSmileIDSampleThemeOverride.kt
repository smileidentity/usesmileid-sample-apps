package com.usesmileid.sampleapps.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import com.usesmileid.presentation.theme.colors.AdaptiveColor
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario

/**
 * What a theme scenario hands the SDK's theme configuration, field for field.
 *
 * Typed in the SDK's own [AdaptiveColor] rather than a parallel colour type, so the shell assigns
 * these straight across and a rename on either side is a compile error rather than a silent drift.
 */
data class UseSmileIDSampleThemeOverride(
    val primaryColor: AdaptiveColor,
    val primaryForeground: AdaptiveColor,
    val secondaryColor: AdaptiveColor,
    val accentColor: AdaptiveColor,
    val buttonShape: RoundedCornerShape,
    /** A family the app can actually resolve, or the SDK keeps its own. */
    val fontFamily: FontFamily? = null,
)

/** What this scenario overrides, or null for the shipped branding. */
val UseSmileIDSampleThemeScenario.override: UseSmileIDSampleThemeOverride?
    get() = when (this) {
        UseSmileIDSampleThemeScenario.BrandDefault -> null
        UseSmileIDSampleThemeScenario.PartnerOverride -> UseSmileIDSampleThemeOverride(
            primaryColor = AdaptiveColor(light = Indigo, dark = Indigo),
            primaryForeground = AdaptiveColor(light = Color.White, dark = Color.White),
            secondaryColor = AdaptiveColor(light = Teal, dark = Teal),
            accentColor = AdaptiveColor(light = Orange, dark = Orange),
            buttonShape = RoundedCornerShape(4.dp),
        )
        // Far from the defaults on every axis the override reaches; Monospace is a system face, so it always resolves.
        UseSmileIDSampleThemeScenario.ClashingHost -> UseSmileIDSampleThemeOverride(
            primaryColor = AdaptiveColor(light = ClashingPrimary, dark = ClashingPrimary),
            primaryForeground = AdaptiveColor(light = Color.Yellow, dark = Color.Yellow),
            secondaryColor = AdaptiveColor(light = ClashingSecondary, dark = ClashingSecondary),
            accentColor = AdaptiveColor(light = ClashingAccent, dark = ClashingAccent),
            buttonShape = RoundedCornerShape(24.dp),
            fontFamily = FontFamily.Monospace,
        )
    }

private val Indigo = Color(0xFF4B0082)
private val Teal = Color(0xFF008080)
private val Orange = Color(0xFFFF7F00)
private val ClashingPrimary = Color(red = 0.85f, green = 0f, blue = 0.5f)
private val ClashingSecondary = Color(red = 0.4f, green = 0.8f, blue = 0f)
private val ClashingAccent = Color(red = 0.9f, green = 0.3f, blue = 0f)
