package com.usesmileid.sampleapps.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import com.usesmileid.presentation.theme.colors.AdaptiveColor
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario

/**
 * What a theme scenario hands the SDK's theme builder, field for field.
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
    /** A family the device can actually resolve, or the SDK keeps its own. */
    val fontFamily: FontFamily? = null,
)

/** What this scenario overrides, or null for the shipped branding. */
val UseSmileIDSampleThemeScenario.override: UseSmileIDSampleThemeOverride?
    get() = when (this) {
        UseSmileIDSampleThemeScenario.BrandDefault -> null

        UseSmileIDSampleThemeScenario.PartnerOverride -> {
            // Baseline Material3: a plausible partner palette that is nobody's brand, and no raw hex.
            val light = lightColorScheme()
            val dark = darkColorScheme()
            UseSmileIDSampleThemeOverride(
                primaryColor = AdaptiveColor(light = light.primary, dark = dark.primary),
                primaryForeground = AdaptiveColor(light = light.onPrimary, dark = dark.onPrimary),
                secondaryColor = AdaptiveColor(light = light.secondary, dark = dark.secondary),
                accentColor = AdaptiveColor(light = light.tertiary, dark = dark.tertiary),
                buttonShape = RoundedCornerShape(PARTNER_BUTTON_RADIUS),
            )
        }

        // Named Compose colours, deliberately outside every palette: this scenario exists to collide.
        // Monospace is a guaranteed system family, so the font override always resolves.
        UseSmileIDSampleThemeScenario.ClashingHost -> UseSmileIDSampleThemeOverride(
            primaryColor = AdaptiveColor(light = Color.Magenta, dark = Color.Magenta),
            primaryForeground = AdaptiveColor(light = Color.Yellow, dark = Color.Yellow),
            secondaryColor = AdaptiveColor(light = Color.Green, dark = Color.Green),
            accentColor = AdaptiveColor(light = Color.Red, dark = Color.Red),
            buttonShape = RoundedCornerShape(CLASHING_BUTTON_RADIUS),
            fontFamily = FontFamily.Monospace,
        )
    }

private val PARTNER_BUTTON_RADIUS = 4.dp
private val CLASHING_BUTTON_RADIUS = 24.dp
