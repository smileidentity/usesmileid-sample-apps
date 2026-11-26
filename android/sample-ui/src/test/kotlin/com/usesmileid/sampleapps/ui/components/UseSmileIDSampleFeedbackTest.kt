package com.usesmileid.sampleapps.ui.components

import android.content.Context
import android.provider.Settings
import androidx.compose.foundation.layout.Column
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onNodeWithTag
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

    private companion object {
        const val CARD = "card"
    }
}
