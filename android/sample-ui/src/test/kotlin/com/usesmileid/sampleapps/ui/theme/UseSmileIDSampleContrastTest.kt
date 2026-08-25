package com.usesmileid.sampleapps.ui.theme

import androidx.compose.ui.graphics.Color
import com.smileid.designsystem.SmileColorLight
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

    @Test
    fun `muted text stays above the large-text bar`() = eachScheme { name, colors ->
        assertContrast("$name: muted on surface", colors.textMuted, colors.surface, LARGE_TEXT_MINIMUM)
    }

    /**
     * The gradient-backed cards, which no token pair above describes — which is how the session card
     * shipped `colors.surface` ink, black on its own fill in dark, for as long as dark mode has existed.
     * Translucent stops composite against the page, so each is checked over the scheme's background.
     *
     * Held to [DESIGN_INK_FLOOR], not [TEXT_MINIMUM]: 14 of these 28 stops are below AA and the frame is
     * final as drawn, so this guards against getting WORSE rather than certifying the values. See the
     * `cardInkContrast` delta for the measured table and the ask.
     */
    @Test
    fun `product card text is legible on every hue in both modes`() = eachScheme { name, colors ->
        smileProductHues.forEach { (product, hue) ->
            listOf("from" to hue.from.copy(alpha = hue.fromAlpha), "to" to hue.to.copy(alpha = hue.toAlpha))
                .forEach { (stop, fill) ->
                    assertContrast(
                        "$name: card text on $product's $stop stop",
                        SmileColorLight.colorTextInverse,
                        fill.over(colors.background),
                        DESIGN_INK_FLOOR,
                    )
                }
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

        /**
         * Not WCAG either: the design's own worst case, the opaque amber Registration card at 1.76:1.
         * A regression floor, not a standard — raise it as design raises the values.
         */
        const val DESIGN_INK_FLOOR = 1.75

        /** Source-over: a translucent card stop shows the page through it. */
        fun Color.over(background: Color): Color = Color(
            red = red * alpha + background.red * (1f - alpha),
            green = green * alpha + background.green * (1f - alpha),
            blue = blue * alpha + background.blue * (1f - alpha),
        )

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
