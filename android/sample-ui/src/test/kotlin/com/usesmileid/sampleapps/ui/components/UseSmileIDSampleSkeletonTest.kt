package com.usesmileid.sampleapps.ui.components

import androidx.compose.runtime.Recomposer
import androidx.compose.ui.test.junit4.createComposeRule
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class UseSmileIDSampleSkeletonTest {
    @get:Rule val compose = createComposeRule()

    @Test
    fun the_pulse_does_not_recompose_the_rows_each_frame() {
        compose.mainClock.autoAdvance = false
        compose.setContent {
            UseSmileIDSampleTheme { UseSmileIDSampleSkeletonRows(announcement = "Loading", leadingCircle = true) }
        }
        compose.mainClock.advanceTimeBy(1_000)
        val settled = recompositions()

        compose.mainClock.advanceTimeBy(1_000)

        assertEquals(settled, recompositions())
    }

    private fun recompositions(): Long = Recomposer.runningRecomposers.value.sumOf { it.changeCount }
}
