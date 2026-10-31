package com.usesmileid.sampleapps.android

import android.content.Intent
import android.net.Uri
import com.usesmileid.sampleapps.android.launch.playsLaunchIntro
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class LaunchIntroGateTest {

    @Test
    fun `a cold start from the launcher plays the intro`() {
        assertTrue(launcher().playsLaunchIntro(restored = false, animationsEnabled = true))
    }

    @Test
    fun `a restored activity goes straight to the app`() {
        assertFalse(launcher().playsLaunchIntro(restored = true, animationsEnabled = true))
    }

    @Test
    fun `turning animations off in the system skips it`() {
        assertFalse(launcher().playsLaunchIntro(restored = false, animationsEnabled = false))
    }

    @Test
    fun `a deep link lands on its destination without it`() {
        val link = Intent(Intent.ACTION_VIEW, Uri.parse("usesmileid-sample-android://settings"))

        assertFalse(link.playsLaunchIntro(restored = false, animationsEnabled = true))
    }

    @Test
    fun `an automation launch argument skips it`() {
        val automated = launcher().putExtra("probes", true)

        assertFalse(automated.playsLaunchIntro(restored = false, animationsEnabled = true))
    }

    @Test
    fun `an extra the platform adds on its own still plays it`() {
        val fromLauncher = launcher().putExtra("android.intent.extra.USER", 0)

        assertTrue(fromLauncher.playsLaunchIntro(restored = false, animationsEnabled = true))
    }

    @Test
    fun `no intent at all skips it`() {
        assertFalse((null as Intent?).playsLaunchIntro(restored = false, animationsEnabled = true))
    }

    private fun launcher() = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
}
