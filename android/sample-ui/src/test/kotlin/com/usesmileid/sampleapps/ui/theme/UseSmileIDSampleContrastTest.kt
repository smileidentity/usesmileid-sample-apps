package com.usesmileid.sampleapps.ui.theme

import androidx.compose.ui.graphics.Color
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow

/**
 * Every fill must keep what is drawn on it legible, in both modes — which the golden lane cannot
 * assert, because a screenshot only fails when it changes.
 */
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
