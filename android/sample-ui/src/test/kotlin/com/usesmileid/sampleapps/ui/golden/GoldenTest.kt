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
import androidx.compose.ui.test.v2.runComposeUiTest
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

/** Records with `recordRoborazziDebug` and checks with `verifyRoborazziDebug`. One [runComposeUiTest] per capture, because a rule takes `setContent` once. */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [ROBOLECTRIC_SDK], qualifiers = "w411dp-h891dp-xhdpi")
@OptIn(ExperimentalTestApi::class)
abstract class GoldenTest {

    protected fun goldens(name: String, content: @Composable () -> Unit) {
        capture("${name}_light", dark = false, content = content)
        capture("${name}_dark", dark = true, content = content)
    }

    private fun capture(name: String, dark: Boolean, content: @Composable () -> Unit) = runComposeUiTest {
        host(dark = dark, fontScale = 1f, content = content)
        onNodeWithTag(GOLDEN_ROOT).captureRoboImage("src/test/screenshots/$name.png")
    }

    /** Fails on truncated text or a composite wider than the viewport. Not `hasVisualOverflow`, which is also true for centred text that fits. */
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
        // The v2 dispatcher queues composition, so settle before reading or capturing.
        waitForIdle()
    }

    private companion object {
        const val GOLDEN_ROOT = "golden_root"

        /** The width of the phone these are verified on: 411dp hid a nav-bar clip that the device showed. */
        val GOLDEN_WIDTH = 393.dp

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
