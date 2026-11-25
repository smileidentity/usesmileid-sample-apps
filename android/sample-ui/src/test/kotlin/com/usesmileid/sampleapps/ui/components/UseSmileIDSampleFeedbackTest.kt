package com.usesmileid.sampleapps.ui.components

import android.content.Context
import android.provider.Settings
import androidx.compose.foundation.layout.Column
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.hapticfeedback.HapticFeedback
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.v2.runComposeUiTest
import com.smileid.designsystem.smileProductHues
import com.usesmileid.sampleapps.ui.golden.ROBOLECTRIC_SDK
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [ROBOLECTRIC_SDK], qualifiers = "w411dp-h891dp-xhdpi")
@OptIn(ExperimentalTestApi::class)
class UseSmileIDSampleFeedbackTest {

    private class RecordingHaptics : HapticFeedback {
        val played = mutableListOf<HapticFeedbackType>()
        override fun performHapticFeedback(hapticFeedbackType: HapticFeedbackType) {
            played += hapticFeedbackType
        }
    }

    @Composable
    private fun Host(haptics: HapticFeedback, content: @Composable () -> Unit) {
        UseSmileIDSampleTheme {
            CompositionLocalProvider(LocalHapticFeedback provides haptics, content = content)
        }
    }

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
    fun `picking another chip ticks once`() = runComposeUiTest {
        val haptics = RecordingHaptics()
        setContent {
            Host(haptics) {
                UseSmileIDSampleFilterChip(label = "Failed", count = 2, selected = false, onClick = {}, testId = CHIP)
            }
        }

        onNodeWithTag(CHIP).performClick()

        assertEquals(listOf(HapticFeedbackType.SegmentTick), haptics.played)
    }

    @Test
    fun `tapping the chip already picked does not tick`() = runComposeUiTest {
        val haptics = RecordingHaptics()
        setContent {
            Host(haptics) {
                UseSmileIDSampleFilterChip(label = "All", count = 4, selected = true, onClick = {}, testId = CHIP)
            }
        }

        onNodeWithTag(CHIP).performClick()

        assertEquals(emptyList<HapticFeedbackType>(), haptics.played)
    }

    @Test
    fun `moving to another tab ticks once`() = runComposeUiTest {
        val haptics = RecordingHaptics()
        setContent {
            Host(haptics) {
                UseSmileIDSampleNavBar(selected = UseSmileIDSampleNavItem.Products, onSelect = {}, onTokenClick = {})
            }
        }

        onNodeWithTag(UseSmileIDSampleNavItem.Verifications.testId).performClick()

        assertEquals(listOf(HapticFeedbackType.SegmentTick), haptics.played)
    }

    @Test
    fun `tapping the tab already open does not tick`() = runComposeUiTest {
        val haptics = RecordingHaptics()
        setContent {
            Host(haptics) {
                UseSmileIDSampleNavBar(selected = UseSmileIDSampleNavItem.Products, onSelect = {}, onTokenClick = {})
            }
        }

        onNodeWithTag(UseSmileIDSampleNavItem.Products.testId).performClick()

        assertEquals(emptyList<HapticFeedbackType>(), haptics.played)
    }

    @Test
    fun `turning a switch on ticks on`() = runComposeUiTest {
        val haptics = RecordingHaptics()
        setContent {
            Host(haptics) {
                UseSmileIDSampleSwitch(checked = false, onCheckedChange = {}, testId = SWITCH)
            }
        }

        onNodeWithTag(SWITCH).performClick()

        assertEquals(listOf(HapticFeedbackType.ToggleOn), haptics.played)
    }

    @Test
    fun `turning a switch off ticks off`() = runComposeUiTest {
        val haptics = RecordingHaptics()
        setContent {
            Host(haptics) {
                UseSmileIDSampleSwitch(checked = true, onCheckedChange = {}, testId = SWITCH)
            }
        }

        onNodeWithTag(SWITCH).performClick()

        assertEquals(listOf(HapticFeedbackType.ToggleOff), haptics.played)
    }

    @Test
    fun `a disabled switch does not tick`() = runComposeUiTest {
        val haptics = RecordingHaptics()
        setContent {
            Host(haptics) {
                UseSmileIDSampleSwitch(checked = false, onCheckedChange = {}, enabled = false, testId = SWITCH)
            }
        }

        onNodeWithTag(SWITCH).performClick()

        assertEquals(emptyList<HapticFeedbackType>(), haptics.played)
    }

    private companion object {
        const val CARD = "card"
        const val CHIP = "chip"
        const val SWITCH = "switch"
    }
}
