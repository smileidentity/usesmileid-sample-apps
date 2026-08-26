package com.usesmileid.sampleapps.ui.theme

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import com.smileid.designsystem.SmileColorLight
import com.smileid.designsystem.smileOffBlackLight
import com.smileid.designsystem.smileProductHues
import com.smileid.designsystem.smileTokenSessionGradient
import com.smileid.designsystem.smileTokenSessionGradientAlpha
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow

/** Every fill keeps its foreground legible in both modes — which a golden cannot assert, because it only fails when it changes. */
class UseSmileIDSampleContrastTest {

    @Test
    fun `an icon glyph is legible on its tile in both modes`() = eachScheme { name, colors ->
        assertContrast("$name: glyph on icon tile", colors.textTitle, colors.surfaceTile, TEXT_MINIMUM)
    }

    @Test
    fun `an icon tile is distinguishable from the surface behind it`() = eachScheme { name, colors ->
        assertContrast("$name: icon tile against card", colors.surfaceTile, colors.surface, CONTAINER_MINIMUM)
    }

    @Test
    fun `body and title text are legible on every surface they are drawn on`() = eachScheme { name, colors ->
        listOf("surface" to colors.surface, "background" to colors.background, "surfaceAlt" to colors.surfaceAlt)
            .forEach { (surfaceName, surface) ->
                assertContrast("$name: title on $surfaceName", colors.textTitle, surface, TEXT_MINIMUM)
                assertContrast("$name: body on $surfaceName", colors.textBody, surface, TEXT_MINIMUM)
            }
    }

    /** Dark must read without the shadow; light is near-white on near-white and rides on it. */
    @Test
    fun `the nav bar stays distinguishable from the page it floats over`() {
        assertContrast("light: nav bar against page", lightColors.navBar, lightColors.background, DISTINCT)
        assertContrast("dark: nav bar against page", darkColors.navBar, darkColors.background, CONTAINER_MINIMUM)
    }

    @Test
    fun `muted text stays above the large-text bar`() = eachScheme { name, colors ->
        assertContrast("$name: muted on surface", colors.textMuted, colors.surface, LARGE_TEXT_MINIMUM)
    }

    /**
     * The gradient-backed cards, which no token pair above describes — which is how the session card
     * shipped near-black ink on its own fill in dark. The label sits over the gradient's FIRST stop and
     * takes the ink that contrasts with it, so this is held to real AA rather than a floor.
     */
    @Test
    fun `product card text is legible on every hue in both modes`() = eachScheme { name, colors ->
        smileProductHues.forEach { (product, hue) ->
            val fill = hue.from.copy(alpha = hue.fromAlpha).over(colors.background)
            val minimum = if (product in MID_TONE_FILLS) LARGE_TEXT_MINIMUM else TEXT_MINIMUM
            assertContrast("$name: card label on $product", fill.inkOn(), fill, minimum)
        }
    }

    @Test
    fun `session card text is legible on its gradient in both modes`() = eachScheme { name, colors ->
        smileTokenSessionGradient.forEachIndexed { index, stop ->
            assertContrast(
                "$name: session text on stop $index",
                SmileColorLight.colorTextInverse,
                stop.copy(alpha = smileTokenSessionGradientAlpha[index]).over(colors.background),
                DESIGN_INK_FLOOR,
            )
        }
    }

    private fun eachScheme(check: (String, UseSmileIDSampleColors) -> Unit) {
        check("light", lightColors)
        check("dark", darkColors)
    }

    private fun assertContrast(what: String, foreground: Color, background: Color, minimum: Double) {
        val ratio = contrastRatio(foreground, background)
        assertTrue(
            "$what is ${"%.2f".format(ratio)}:1, below the ${"%.2f".format(minimum)}:1 minimum",
            ratio >= minimum,
        )
    }

    private companion object {
        /** WCAG AA for body text. */
        const val TEXT_MINIMUM = 4.5

        /** WCAG AA for large text and UI components. */
        const val LARGE_TEXT_MINIMUM = 3.0

        /** Not WCAG: a container only has to be seen. The design's surface-2 on white is 1.13:1. */
        const val CONTAINER_MINIMUM = 1.08

        /** The card's own white-or-dark crossover. */
        const val INK_CROSSOVER = 0.179f

        /**
         * Fills so near the crossover that NEITHER ink clears AA — 3.55:1 is the best available on
         * Enhanced KYC's sky blue over the dark page, so only design can move it. Should stay one entry.
         */
        val MID_TONE_FILLS = setOf("enhancedKyc")

        /** Not the same colour. Light's bar is near-white on near-white and rides on its shadow. */
        const val DISTINCT = 1.02

        /** Not WCAG either: the design's own worst case, the amber Registration card at 1.76:1. */
        const val DESIGN_INK_FLOOR = 1.75

        /** Source-over: a translucent card stop shows the page through it. */
        fun Color.over(background: Color): Color = Color(
            red = red * alpha + background.red * (1f - alpha),
            green = green * alpha + background.green * (1f - alpha),
            blue = blue * alpha + background.blue * (1f - alpha),
        )

        /** Mirrors the card's own rule, so the test fails if the two ever disagree. */
        fun Color.inkOn(): Color =
            if (luminance() > INK_CROSSOVER) smileOffBlackLight else SmileColorLight.colorTextInverse

        fun contrastRatio(a: Color, b: Color): Double {
            val la = relativeLuminance(a)
            val lb = relativeLuminance(b)
            return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
        }

        fun relativeLuminance(color: Color) =
            0.2126 * channel(color.red) + 0.7152 * channel(color.green) + 0.0722 * channel(color.blue)

        fun channel(value: Float): Double {
            val v = value.toDouble()
            return if (v <= 0.03928) v / 12.92 else ((v + 0.055) / 1.055).pow(2.4)
        }
    }
}
