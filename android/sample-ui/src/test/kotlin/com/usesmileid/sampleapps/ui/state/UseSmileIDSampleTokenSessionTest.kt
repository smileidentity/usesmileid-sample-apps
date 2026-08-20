package com.usesmileid.sampleapps.ui.state

import kotlin.time.Duration
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The countdown and the ring at every span the Portal mints. Asserted here rather than watched on a
 * device, which is the only affordable way to know an 8h token reads correctly at its seventh hour.
 */
class UseSmileIDSampleTokenSessionTest {

    @Test
    fun `the ring measures the token's own span, not a fixed five minutes`() {
        PORTAL_SPANS.forEach { span ->
            val session = session(span)
            assertEquals("full ring at issue for $span", 1f, session.progress(NOW), TOLERANCE)
            assertEquals("half ring at half of $span", 0.5f, session.progress(NOW + span.inWholeMilliseconds / 2), TOLERANCE)
            assertEquals("empty ring at the deadline for $span", 0f, session.progress(NOW + span.inWholeMilliseconds), TOLERANCE)
        }
    }

    @Test
    fun `an hour in, an eight hour token still has most of its ring`() {
        // The bug this replaces: dividing by five minutes pinned the ring at 1f for 55 minutes, then cliffed.
        val session = session(8.hours)
        assertEquals(0.875f, session.progress(NOW + 1.hours.inWholeMilliseconds), TOLERANCE)
        assertEquals(1f, session(5.minutes).progress(NOW), TOLERANCE)
    }

    @Test
    fun `progress is clamped either side of the span`() {
        val session = session(15.minutes)
        assertEquals(1f, session.progress(NOW - 1.hours.inWholeMilliseconds), TOLERANCE)
        assertEquals(0f, session.progress(NOW + 1.hours.inWholeMilliseconds), TOLERANCE)
    }

    @Test
    fun `a fresh countdown reads m ss under an hour and h mm ss above it`() {
        assertEquals("15:00", session(15.minutes).remaining(NOW).toCountdown())
        assertEquals("1:00:00", session(1.hours).remaining(NOW).toCountdown())
        assertEquals("8:00:00", session(8.hours).remaining(NOW).toCountdown())
    }

    @Test
    fun `an eight hour token reads 7 59 12 rather than overflowing minutes`() {
        val session = session(8.hours)
        assertEquals("7:59:12", session.remaining(NOW + 48.seconds.inWholeMilliseconds).toCountdown())
    }

    @Test
    fun `the countdown pads both minutes and seconds once there is an hours part`() {
        assertEquals("1:00:09", (1.hours + 9.seconds).toCountdown())
        assertEquals("1:09:00", (1.hours + 9.minutes).toCountdown())
        assertEquals("0:09", 9.seconds.toCountdown())
        assertEquals("59:59", (59.minutes + 59.seconds).toCountdown())
        assertEquals("0:00", Duration.ZERO.toCountdown())
    }

    @Test
    fun `the countdown floors rather than rounding, so it never shows time that has gone`() {
        assertEquals("0:01", 1999.milliseconds.toCountdown())
    }

    @Test
    fun `a zero span reads as spent rather than as NaN`() {
        // Unreachable through the decoder, which rejects exp <= iat — but this constructor is public,
        // and NaN survives coerceIn to reach the ring.
        val degenerate = session(15.minutes).copy(expiresAtMillis = NOW)
        assertEquals(0f, degenerate.progress(NOW), TOLERANCE)
        assertFalse(degenerate.progress(NOW).isNaN())
    }

    @Test
    fun `expiry is the deadline itself, and remaining never goes negative`() {
        val session = session(15.minutes)
        val deadline = NOW + 15.minutes.inWholeMilliseconds
        assertFalse(session.hasExpired(deadline - 1))
        assertTrue("the deadline is expired, not the millisecond after it", session.hasExpired(deadline))
        assertEquals(Duration.ZERO, session.remaining(deadline + 1.hours.inWholeMilliseconds))
    }

    private fun session(span: Duration) = UseSmileIDSampleTokenSession(
        id = "a1b2c3d4",
        token = "header.payload.signature",
        issuedAtMillis = NOW,
        expiresAtMillis = NOW + span.inWholeMilliseconds,
        bindings = UseSmileIDSampleTokenBindings(),
    )

    private companion object {
        const val NOW = 1_755_500_000_000L
        const val TOLERANCE = 0.0001f
        val PORTAL_SPANS = listOf(15.minutes, 1.hours, 8.hours)
    }
}
