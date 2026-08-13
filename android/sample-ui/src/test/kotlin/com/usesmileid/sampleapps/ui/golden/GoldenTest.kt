package com.usesmileid.sampleapps.ui.golden

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsNode
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.runComposeUiTest
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import com.github.takahirom.roborazzi.captureRoboImage
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import org.junit.Assert.assertEquals
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

/**
 * The golden and structural-predicate harness every composite test extends.
 *
 * Goldens exist because 24 of the 27 composites have no design-system contract, so once the pending
 * token fixes land there is nothing else that can tell us a composite still looks right. Recorded
 * with `./gradlew recordRoborazziDebug`, checked by `verifyRoborazziDebug` in `verify.sh`.
 *
 * Each capture runs its own [runComposeUiTest], because a compose test rule accepts `setContent`
 * once and every composite owes both a light and a dark golden.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [ROBOLECTRIC_SDK], qualifiers = "w411dp-h891dp-xhdpi")
@OptIn(ExperimentalTestApi::class)
abstract class GoldenTest {

    /** Both modes, since every composite owes a light and a dark golden. */
    protected fun goldens(name: String, content: @Composable () -> Unit) {
        capture("${name}_light", dark = false, content = content)
        capture("${name}_dark", dark = true, content = content)
    }

    private fun capture(name: String, dark: Boolean, content: @Composable () -> Unit) = runComposeUiTest {
        host(dark = dark, fontScale = 1f, content = content)
        onNodeWithTag(GOLDEN_ROOT).captureRoboImage("src/test/screenshots/$name.png")
    }

    /**
     * The font-scale predicate from the Definition of Done, as an assertion rather than an eyeball.
     *
     * Truncation is read from `didExceedMaxLines` and `didOverflowHeight`, not `hasVisualOverflow`:
     * the latter also reports true for centred text that fits, because `TextAlign.Center` widens the
     * paragraph to the incoming constraint while the node shrinks to its intrinsic width. Also fails
     * a composite that grows wider than the viewport, because a row of
     * label-plus-value-plus-trailing-control is the shape that does that at 2x.
     */
    protected fun assertSurvivesMaxFontScale(
        fontScale: Float = MAX_FONT_SCALE,
        checkWidth: Boolean = true,
        content: @Composable () -> Unit,
    ) = runComposeUiTest {
        host(dark = false, fontScale = fontScale, content = content)
        val root = onNodeWithTag(GOLDEN_ROOT).fetchSemanticsNode()
        val nodes = mutableListOf<SemanticsNode>().also { it.collectFrom(root) }

        val overflowing = nodes
            .filter { node -> node.textLayoutResults().any { it.isTruncated() } }
            .map { it.textOrEmpty() }
        assertEquals("text clipped or ellipsised at ${fontScale}x font scale", emptyList<String>(), overflowing)

        if (checkWidth) {
            val rootRight = root.boundsInRoot.right
            val tooWide = nodes
                .filter { it.boundsInRoot.right > rootRight + TOLERANCE_PX }
                .map { "${it.textOrEmpty()} (right=${it.boundsInRoot.right} > $rootRight)" }
            assertEquals("laid out wider than the viewport at ${fontScale}x font scale", emptyList<String>(), tooWide)
        }
    }

    /** Dumps every text node's layout, for working out whether an overflow is real. */
    protected fun describeTextLayout(fontScale: Float = MAX_FONT_SCALE, content: @Composable () -> Unit): String {
        var report = ""
        runComposeUiTest {
            host(dark = false, fontScale = fontScale, content = content)
            val root = onNodeWithTag(GOLDEN_ROOT).fetchSemanticsNode()
            report = mutableListOf<SemanticsNode>().also { it.collectFrom(root) }
                .flatMap { node -> node.textLayoutResults().map { node to it } }
                .joinToString("\n") { (node, layout) ->
                    "%-34s node=%s layout=%dx%d lines=%d truncated=%b".format(
                        node.textOrEmpty(),
                        node.size,
                        layout.size.width,
                        layout.size.height,
                        layout.lineCount,
                        layout.isTruncated(),
                    )
                }
        }
        return report
    }

    private fun ComposeUiTest.host(dark: Boolean, fontScale: Float, content: @Composable () -> Unit) {
        setContent {
            UseSmileIDSampleTheme(darkTheme = dark) {
                val density = LocalDensity.current
                CompositionLocalProvider(
                    LocalDensity provides Density(density = density.density, fontScale = fontScale),
                ) {
                    Box(
                        modifier = Modifier
                            .testTag(GOLDEN_ROOT)
                            .width(GOLDEN_WIDTH)
                            .background(UseSmileIDSampleTheme.colors.background)
                            .padding(SmileDimens.spacingMd),
                    ) {
                        Box(modifier = Modifier.fillMaxWidth()) { content() }
                    }
                }
            }
        }
    }

    private companion object {
        const val GOLDEN_ROOT = "golden_root"
        val GOLDEN_WIDTH = 411.dp

        /** Android's largest accessibility font scale — the one the no-clipping predicate means. */
        const val MAX_FONT_SCALE = 2f

        /** Sub-pixel rounding in layout, not a real overflow. */
        const val TOLERANCE_PX = 0.5f
    }
}

/** Robolectric ships no image for the compileSdk yet, so goldens render on the newest it has. */
internal const val ROBOLECTRIC_SDK = 36

private fun MutableList<SemanticsNode>.collectFrom(node: SemanticsNode) {
    add(node)
    node.children.forEach { collectFrom(it) }
}

private fun SemanticsNode.textLayoutResults(): List<TextLayoutResult> {
    val results = mutableListOf<TextLayoutResult>()
    config.getOrNull(SemanticsActions.GetTextLayoutResult)?.action?.invoke(results)
    return results
}

/** Ellipsised by a maxLines cap, or clipped by a height constraint. */
private fun TextLayoutResult.isTruncated(): Boolean = multiParagraph.didExceedMaxLines || didOverflowHeight

private fun SemanticsNode.textOrEmpty(): String =
    config.getOrNull(SemanticsProperties.Text)?.joinToString(" ") { it.text } ?: "<no text>"
