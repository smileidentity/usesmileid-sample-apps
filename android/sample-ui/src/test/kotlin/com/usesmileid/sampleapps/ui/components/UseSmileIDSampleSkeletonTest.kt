package com.usesmileid.sampleapps.ui.components

import android.provider.Settings
import androidx.compose.runtime.Recomposer
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import com.usesmileid.sampleapps.ui.golden.ROBOLECTRIC_SDK
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [ROBOLECTRIC_SDK])
class UseSmileIDSampleSkeletonTest {
    @get:Rule val compose = createComposeRule()

    @Before
    fun animationsOn() {
        Settings.Global.putFloat(RuntimeEnvironment.getApplication().contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f)
    }

    @Test
    fun the_pulse_repaints_the_rows_without_recomposing_them() {
        compose.mainClock.autoAdvance = false
        compose.setContent {
            UseSmileIDSampleTheme { UseSmileIDSampleSkeletonRows(announcement = "Loading", leadingCircle = true, testId = SKELETON) }
        }
        compose.mainClock.advanceTimeBy(100)
        val recompositions = recompositions()
        val before = barPixel()

        compose.mainClock.advanceTimeBy(200)

        assertEquals(recompositions, recompositions())
        assertNotEquals(before, barPixel())
    }

    private fun recompositions(): Long = Recomposer.runningRecomposers.value.sumOf { it.changeCount }

    private fun barPixel() = compose.onNodeWithTag(SKELETON).captureToImage().toPixelMap().let { it[it.width / 4, it.height / 12] }

    private companion object {
        const val SKELETON = "skeleton"
    }
}
