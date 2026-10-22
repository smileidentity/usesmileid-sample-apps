package com.usesmileid.sampleapps.android.extension

import android.content.Intent
import com.usesmileid.sampleapps.android.UseSmileIDSampleActivity
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowLooper

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class UseSmileIDSampleLaunchOrderTest {
    private val calls = mutableListOf<String>()
    private val installed = useSmileIDSampleShellExtension

    @Before
    fun record() {
        useSmileIDSampleShellExtension = object : UseSmileIDSampleShellExtension {
            override fun onLaunch(intent: Intent) {
                calls += "onLaunch"
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
        ShadowLooper.idleMainLooper()

        assertEquals(listOf("onLaunch", "launchSession"), calls)
    }
}
