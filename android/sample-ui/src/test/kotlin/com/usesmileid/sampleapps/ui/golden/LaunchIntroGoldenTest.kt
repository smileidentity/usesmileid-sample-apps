package com.usesmileid.sampleapps.ui.golden

import com.usesmileid.sampleapps.ui.screens.LaunchIntroFrame
import com.usesmileid.sampleapps.ui.screens.LaunchIntroTimeline
import org.junit.Test

/** The intro stopped on its two named frames; it draws on the dark scheme whatever the device's, so both baselines match. */
class LaunchIntroGoldenTest : GoldenTest() {

    @Test
    fun locked() = goldens("screen_launch_intro_locked") { LaunchIntroFrame(progress = { LaunchIntroTimeline.LOCKED }) }

    @Test
    fun logo() = goldens("screen_launch_intro_logo") { LaunchIntroFrame(progress = { 1f }) }
}
