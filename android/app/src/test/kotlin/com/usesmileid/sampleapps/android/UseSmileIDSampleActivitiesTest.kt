package com.usesmileid.sampleapps.android

import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.platform.AndroidUiDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.launch
import org.junit.Assert.assertTrue
import org.junit.FixMethodOrder
import org.junit.Rule
import org.junit.Test
import org.junit.rules.ExternalResource
import org.junit.rules.RuleChain
import org.junit.runner.RunWith
import org.junit.runners.MethodSorters
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowLooper
import java.util.concurrent.TimeUnit

/** Compose work one activity test leaves queued doesn't stall the next; the last test by name checks. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
@FixMethodOrder(MethodSorters.NAME_ASCENDING)
class UseSmileIDSampleActivitiesTest {
    private val activities = UseSmileIDSampleActivities()
    private val late = LateDispatch()

    @get:Rule
    val rules: RuleChain = RuleChain.outerRule(late).around(activities)

    @Test
    fun `an activity test can end with a Compose dispatch still queued`() {
        activities.build(UseSmileIDSampleActivity::class.java).setup()
        CoroutineScope(AndroidUiDispatcher.Main).launch { }
    }

    @Test
    fun `an activity test can end with a Compose dispatch arriving after its drain`() {
        activities.build(UseSmileIDSampleActivity::class.java).setup()
        late.dispatch = true
    }

    @Test
    fun `an activity test can end with a Compose frame arriving after its drain`() {
        activities.build(UseSmileIDSampleActivity::class.java).setup()
        late.frame = true
    }

    @Test
    fun `the next test's first frame still runs its effects`() {
        var ran = false
        var framed = false
        activities.build(ComponentActivity::class.java).setup().get().setContent {
            LaunchedEffect(Unit) {
                ran = true
                withFrameNanos { framed = true }
            }
        }
        ShadowLooper.idleMainLooper(FRAME_MILLIS, TimeUnit.MILLISECONDS)

        assertTrue("the first frame's effect never ran", ran)
        assertTrue("the effect never got a frame", framed)
    }

    private companion object {
        /** Long enough for one frame. */
        const val FRAME_MILLIS = 100L
    }

    /** Queues Compose work after [UseSmileIDSampleActivities] has drained. */
    private class LateDispatch : ExternalResource() {
        var dispatch = false
        var frame = false

        override fun after() {
            if (dispatch) CoroutineScope(AndroidUiDispatcher.Main).launch { }
            if (frame) {
                CoroutineScope(AndroidUiDispatcher.Main).launch(start = CoroutineStart.UNDISPATCHED) {
                    withFrameNanos { }
                }
            }
        }
    }
}
