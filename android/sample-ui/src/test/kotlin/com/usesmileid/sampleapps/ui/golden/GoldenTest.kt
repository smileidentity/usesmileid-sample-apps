package com.usesmileid.sampleapps.ui.golden

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsNode
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.Dp
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

    /** [interact] runs after the first composition, for a state only a gesture, focus or a held clock reaches. */
    protected fun goldens(
        name: String,
        // A second window makes Roborazzi capture the whole screen, so a narrower host leaves bare window in the shot.
        fullWindow: Boolean = false,
        interact: GoldenInteractions.() -> Unit = {},
        content: @Composable () -> Unit,
    ) {
        capture("${name}_light", dark = false, fullWindow, interact, content)
        capture("${name}_dark", dark = true, fullWindow, interact, content)
    }

    private fun capture(
        name: String,
        dark: Boolean,
        fullWindow: Boolean,
        interact: GoldenInteractions.() -> Unit,
        content: @Composable () -> Unit,
    ) = runComposeUiTest {
        host(dark = dark, fontScale = 1f, fullWindow = fullWindow, content = content)
        GoldenInteractions(this).interact()
        onNodeWithTag(GOLDEN_ROOT).captureRoboImage("src/test/screenshots/$name.png")
    }

    /** Fails on truncated text or a composite wider than the viewport. Not `hasVisualOverflow`, which is also true for centred text that fits. */
    protected fun assertSurvivesMaxFontScale(
        fontScale: Float = MAX_FONT_SCALE,
        checkWidth: Boolean = true,
        /** A sheet is its own window, so its content is not under [GOLDEN_ROOT] and must be named. */
        rootTestId: String = GOLDEN_ROOT,
        content: @Composable () -> Unit,
    ) = runComposeUiTest {
        host(dark = false, fontScale = fontScale, content = content)
        val root = onNodeWithTag(rootTestId).fetchSemanticsNode()
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

    /** Fails on a line break inside a word. `didExceedMaxLines` cannot see one: wrapped text never truncates. */
    protected fun assertBreaksBetweenWords(
        fontScale: Float = MAX_FONT_SCALE,
        content: @Composable () -> Unit,
    ) = runComposeUiTest {
        host(dark = false, fontScale = fontScale, content = content)
        val root = onNodeWithTag(GOLDEN_ROOT).fetchSemanticsNode()
        val nodes = mutableListOf<SemanticsNode>().also { it.collectFrom(root) }

        val split = nodes.flatMap { node ->
            val text = node.config.getOrNull(SemanticsProperties.Text)?.joinToString(" ") { it.text }
            if (text == null) emptyList() else node.textLayoutResults().flatMap { it.midWordBreaks(text) }
        }
        assertEquals("a word broke across lines at ${fontScale}x font scale", emptyList<String>(), split)
    }

    private fun ComposeUiTest.host(
        dark: Boolean,
        fontScale: Float,
        fullWindow: Boolean = false,
        content: @Composable () -> Unit,
    ) {
        setContent {
            UseSmileIDSampleTheme(darkTheme = dark) {
                val density = LocalDensity.current
                CompositionLocalProvider(
                    LocalDensity provides Density(density = density.density, fontScale = fontScale),
                ) {
                    Box(
                        modifier = Modifier
                            .testTag(GOLDEN_ROOT)
                            .then(if (fullWindow) Modifier.fillMaxSize() else Modifier.width(GOLDEN_WIDTH))
                            .background(UseSmileIDSampleTheme.colors.background)
                            .then(if (fullWindow) Modifier else Modifier.padding(SmileDimens.spacingMd)),
                    ) {
                        Box(modifier = Modifier.fillMaxWidth()) { content() }
                    }
                }
            }
        }
        // The v2 dispatcher queues composition, so settle before reading or capturing.
        waitForIdle()
    }

    protected companion object {
        const val GOLDEN_ROOT = "golden_root"

        /** The width of the phone these are verified on: 411dp hid a nav-bar clip that the device showed. */
        val GOLDEN_WIDTH = 393.dp

        /** Android's largest accessibility font scale — the one the no-clipping predicate means. */
        const val MAX_FONT_SCALE = 2f

        /** Sub-pixel rounding in layout, not a real overflow. */
        const val TOLERANCE_PX = 0.5f
    }
}

/** What a golden may do between composing and capturing, so no test has to hold the experimental test API open. */
@OptIn(ExperimentalTestApi::class)
class GoldenInteractions internal constructor(private val test: ComposeUiTest) {

    /** Held mid-drag rather than settled: a swipe row's settled anchors are only closed and dismissed. */
    fun dragLeft(testId: String, distance: Dp) {
        test.onNodeWithTag(testId).performTouchInput {
            down(center)
            moveBy(Offset(-distance.toPx(), 0f))
        }
        test.waitForIdle()
    }

    fun type(testId: String, text: String) = test.onNodeWithTag(testId).performTextInput(text)

    /** Stops the clock so a blinking caret has a phase the capture can name; pair with [advance]. */
    fun holdClock() {
        test.mainClock.autoAdvance = false
    }

    fun advance(millis: Long) = test.mainClock.advanceTimeBy(millis)
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

/** Each break that landed between two non-space characters, reported as the two halves it made. */
private fun TextLayoutResult.midWordBreaks(text: String): List<String> =
    (0 until lineCount - 1).mapNotNull { line ->
        val end = getLineEnd(line, visibleEnd = true)
        val splits = end in 1 until text.length && !text[end - 1].isWhitespace() && !text[end].isWhitespace()
        if (splits) "${text.substring(getLineStart(line), end)} | ${text.substring(end)}" else null
    }

private fun SemanticsNode.textOrEmpty(): String =
    config.getOrNull(SemanticsProperties.Text)?.joinToString(" ") { it.text } ?: "<no text>"
