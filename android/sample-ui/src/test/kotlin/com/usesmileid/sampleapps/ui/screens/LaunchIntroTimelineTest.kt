package com.usesmileid.sampleapps.ui.screens

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class LaunchIntroTimelineTest {

    @Test
    fun `the first frame is an empty screen`() {
        val pose = LaunchIntroTimeline.pose(0f)

        assertEquals(0f, pose.markAlpha)
        assertEquals(0f, pose.wordmarkReveal)
    }

    @Test
    fun `the logo starts unlocked, at its own size`() {
        val pose = LaunchIntroTimeline.pose(LaunchIntroTimeline.APPEARED)

        assertEquals(1f, pose.markAlpha)
        assertEquals(1f, pose.markScale)
        assertEquals(0f, pose.shackleLock)
    }

    @Test
    fun `the lock shuts while the name is still unrolling`() {
        val pose = LaunchIntroTimeline.pose(LaunchIntroTimeline.LOCKED)

        assertEquals(1f, pose.shackleLock)
        assertEquals(0f, pose.shackleLift)
        assertTrue("the name is part-way out", pose.wordmarkReveal > 0f && pose.wordmarkReveal < 1f)
    }

    @Test
    fun `the last frame is the logo at rest, unlocked again`() {
        assertEquals(LaunchIntroPose.Rest, LaunchIntroTimeline.pose(1f))
    }

    @Test
    fun `the shackle only ever lifts, never sinks into the body`() {
        val lifts = (0..1000).map { LaunchIntroTimeline.pose(it / 1000f).shackleLift }

        assertTrue(lifts.all { it >= 0f })
    }

    @Test
    fun `progress outside the timeline is clamped`() {
        assertEquals(LaunchIntroTimeline.pose(0f), LaunchIntroTimeline.pose(-1f))
        assertEquals(LaunchIntroTimeline.pose(1f), LaunchIntroTimeline.pose(2f))
    }
}
