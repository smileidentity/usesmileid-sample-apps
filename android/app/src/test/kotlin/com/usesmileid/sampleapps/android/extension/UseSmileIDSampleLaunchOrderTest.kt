package com.usesmileid.sampleapps.android.extension

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import com.usesmileid.sampleapps.android.UseSmileIDSampleActivity
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import java.util.concurrent.TimeUnit
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowLooper

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class UseSmileIDSampleLaunchOrderTest {
    private val calls = mutableListOf<String>()
    private val intents = mutableListOf<Intent>()
    private val installed = useSmileIDSampleShellExtension

    @Before
    fun record() {
        useSmileIDSampleShellExtensionLaunched = false
        useSmileIDSampleShellExtension = object : UseSmileIDSampleShellExtension {
            override fun onLaunch(intent: Intent) {
                calls += "onLaunch"
                intents += intent
            }

            override fun launchSession(): UseSmileIDSampleTokenSession? {
                calls += "launchSession"
                return null
            }
        }
    }

    @After
    fun restore() {
        useSmileIDSampleShellExtension = installed
    }

    @Test
    fun `onLaunch runs before the shell asks for the launch session`() {
        Robolectric.buildActivity(UseSmileIDSampleActivity::class.java).setup()
        idleThroughFirstFrame()

        assertEquals(listOf("onLaunch", "launchSession"), calls)
    }

    @Test
    fun `a process restored from saved state still runs onLaunch`() {
        Robolectric.buildActivity(UseSmileIDSampleActivity::class.java).setup(Bundle())
        idleThroughFirstFrame()

        assertEquals("onLaunch", calls.first())
    }

    @Test
    fun `a recreation in the same process does not run onLaunch again`() {
        Robolectric.buildActivity(UseSmileIDSampleActivity::class.java).setup().recreate()
        idleThroughFirstFrame()

        assertEquals(1, calls.count { it == "onLaunch" })
    }

    @Test
    fun `a second launch in the same process runs onLaunch with its own intent`() {
        val second = Intent(Intent.ACTION_VIEW, Uri.parse("usesmileid-sample-android://?probes=true"))
        Robolectric.buildActivity(UseSmileIDSampleActivity::class.java).setup().pause().stop().destroy()
        Robolectric.buildActivity(UseSmileIDSampleActivity::class.java, second).setup()
        idleThroughFirstFrame()

        assertEquals(2, intents.size)
        assertEquals(second.data, intents.last().data)
    }

    /** The shell's effects start on its first frame, which an idle without time can leave unrun after another activity's test. */
    private fun idleThroughFirstFrame() = ShadowLooper.idleMainLooper(FRAME_MILLIS, TimeUnit.MILLISECONDS)

    private companion object {
        /** Long enough for one frame. */
        const val FRAME_MILLIS = 100L
    }
}
