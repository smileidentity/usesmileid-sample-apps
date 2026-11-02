package com.usesmileid.sampleapps.android

import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.platform.AndroidUiDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import org.junit.Assert.assertTrue
import org.junit.FixMethodOrder
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.MethodSorters
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowLooper

/** A Compose dispatch still queued when one activity test ends doesn't stall the next test's first frame. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
@FixMethodOrder(MethodSorters.NAME_ASCENDING)
class UseSmileIDSampleActivitiesTest {
    @get:Rule
    val activities = UseSmileIDSampleActivities()

    @Test
    fun `an activity test can end with a Compose dispatch still queued`() {
        activities.build(UseSmileIDSampleActivity::class.java).setup()
        CoroutineScope(AndroidUiDispatcher.Main).launch { }
    }

    @Test
    fun `the next test's first frame still runs its effects`() {
        var ran = false
        activities.build(ComponentActivity::class.java).setup().get().setContent { LaunchedEffect(Unit) { ran = true } }
        ShadowLooper.idleMainLooper()

        assertTrue("the first frame's effect never ran", ran)
    }
}
