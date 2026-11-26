package com.usesmileid.sampleapps.ui.components

import android.content.Context
import android.provider.Settings
import androidx.compose.foundation.layout.Column
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshots.Snapshot
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.v2.runComposeUiTest
import com.smileid.designsystem.smileProductHues
import com.usesmileid.sampleapps.ui.golden.ROBOLECTRIC_SDK
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [ROBOLECTRIC_SDK], qualifiers = "w411dp-h891dp-xhdpi")
@OptIn(ExperimentalTestApi::class)
class UseSmileIDSampleFeedbackTest {

    @Test
    fun `a held card shrinks by three per cent`() {
        assertEquals(0.97f, useSmileIDSamplePressScale(pressed = true, enabled = true, reduceMotion = false))
    }

    @Test
    fun `a card at rest keeps its size`() {
        assertEquals(1f, useSmileIDSamplePressScale(pressed = false, enabled = true, reduceMotion = false))
    }

    @Test
    fun `a disabled card does not shrink`() {
        assertEquals(1f, useSmileIDSamplePressScale(pressed = true, enabled = false, reduceMotion = false))
    }

    @Test
    fun `a card does not shrink when the system removes animations`() {
        assertEquals(1f, useSmileIDSamplePressScale(pressed = true, enabled = true, reduceMotion = true))
    }

    @Test
    fun `a card shrinks while held and grows back on release`() = runComposeUiTest {
        mainClock.autoAdvance = false
        setContent {
            UseSmileIDSampleTheme {
                UseSmileIDSampleProductCard(
                    title = "Document",
                    family = "Verification",
                    onClick = {},
                    hue = requireNotNull(smileProductHues[UseSmileIDSampleProduct.DocumentVerification.id]),
                    testId = CARD,
                )
            }
        }
        mainClock.advanceTimeBy(1_000)
        val rest = onNodeWithTag(CARD).fetchSemanticsNode().boundsInRoot.width

        onNodeWithTag(CARD).performTouchInput { down(center) }
        mainClock.advanceTimeBy(1_000)
        val held = onNodeWithTag(CARD).fetchSemanticsNode().boundsInRoot.width

        onNodeWithTag(CARD).performTouchInput { up() }
        mainClock.advanceTimeBy(1_000)
        val released = onNodeWithTag(CARD).fetchSemanticsNode().boundsInRoot.width

        assertEquals(rest * 0.97f, held, 1f)
        assertEquals(rest, released, 0.5f)
    }

    @Test
    fun `a grid of cards watches the animation setting through one observer`() = runComposeUiTest {
        setContent {
            UseSmileIDSampleTheme {
                Column {
                    repeat(3) { index ->
                        UseSmileIDSampleProductCard(
                            title = "Document",
                            family = "Verification",
                            onClick = {},
                            hue = requireNotNull(smileProductHues[UseSmileIDSampleProduct.DocumentVerification.id]),
                            testId = "$CARD$index",
                        )
                    }
                }
            }
        }
        waitForIdle()

        val resolver = ApplicationProvider.getApplicationContext<Context>().contentResolver
        val observers = shadowOf(resolver).getContentObservers(Settings.Global.getUriFor(Settings.Global.ANIMATOR_DURATION_SCALE))
        assertEquals(1, observers.size)
    }

    @Test
    fun `a chip eases into its picked colour instead of snapping`() = runComposeUiTest {
        mainClock.autoAdvance = false
        var selected by mutableStateOf(false)
        var picked = Color.Unspecified
        var resting = Color.Unspecified
        setContent {
            UseSmileIDSampleTheme {
                picked = UseSmileIDSampleTheme.colors.primary
                resting = UseSmileIDSampleTheme.colors.filterChip.background
                UseSmileIDSampleFilterChip(label = "Clear", count = 2, selected = selected, onClick = {}, testId = CHIP)
            }
        }
        mainClock.advanceTimeBy(1_000)

        selected = true
        Snapshot.sendApplyNotifications()
        mainClock.advanceTimeBy(100)
        val midway = fill()
        mainClock.advanceTimeBy(1_000)
        val settled = fill()

        assertNotEquals(resting.toArgb(), midway)
        assertNotEquals(picked.toArgb(), midway)
        assertEquals(picked.toArgb(), settled)
    }

    @Test
    fun `a tab eases into its picked tint instead of snapping`() = runComposeUiTest {
        mainClock.autoAdvance = false
        var tab by mutableStateOf(UseSmileIDSampleNavItem.Products)
        var picked = Color.Unspecified
        setContent {
            UseSmileIDSampleTheme {
                picked = UseSmileIDSampleTheme.colors.primary
                UseSmileIDSampleNavBar(selected = tab, onSelect = {}, onTokenClick = {})
            }
        }
        mainClock.advanceTimeBy(1_000)
        val node = onNodeWithTag(UseSmileIDSampleNavItem.Verifications.testId)

        tab = UseSmileIDSampleNavItem.Verifications
        Snapshot.sendApplyNotifications()
        mainClock.advanceTimeBy(100)
        val midway = node.captureToImage().toPixelMap().let { map -> (0 until map.width).flatMap { x -> (0 until map.height).map { y -> map[x, y].toArgb() } }.toSet() }
        mainClock.advanceTimeBy(1_000)
        val settled = node.captureToImage().toPixelMap().let { map -> (0 until map.width).flatMap { x -> (0 until map.height).map { y -> map[x, y].toArgb() } }.toSet() }

        assertFalse(picked.toArgb() in midway)
        assertTrue(picked.toArgb() in settled)
    }

    private fun ComposeUiTest.fill(): Int {
        val map = onNodeWithTag(CHIP).captureToImage().toPixelMap()
        return map[(map.width * 0.12f).toInt(), map.height / 2].toArgb()
    }

    private companion object {
        const val CARD = "card"
        const val CHIP = "chip"
    }
}
