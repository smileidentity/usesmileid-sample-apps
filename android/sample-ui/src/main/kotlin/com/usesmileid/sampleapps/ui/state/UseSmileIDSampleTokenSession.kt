package com.usesmileid.sampleapps.ui.state

import androidx.compose.runtime.Immutable
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

/** A linked session, held as an absolute deadline: a counter restarts at the wrong value after process death. */
@Immutable
data class UseSmileIDSampleTokenSession(val id: String, val expiresAtMillis: Long) {

    fun remaining(nowMillis: Long): Duration = (expiresAtMillis - nowMillis).coerceAtLeast(0L).milliseconds

    fun hasExpired(nowMillis: Long): Boolean = nowMillis >= expiresAtMillis

    /** 1f on a fresh session down to 0f on an expired one, for the nav bar's countdown ring. */
    fun progress(nowMillis: Long): Float =
        (remaining(nowMillis).inWholeMilliseconds.toFloat() / DEFAULT_DURATION.inWholeMilliseconds).coerceIn(0f, 1f)

    companion object {
        val DEFAULT_DURATION = 5.minutes
    }
}

/** m:ss, the format the design's countdown uses. */
fun Duration.toCountdown(): String {
    val total = inWholeSeconds
    return "${total / SECONDS_PER_MINUTE}:${(total % SECONDS_PER_MINUTE).toString().padStart(2, '0')}"
}

private const val SECONDS_PER_MINUTE = 60

private val Long.milliseconds: Duration get() = (this / MILLIS_PER_SECOND.toDouble()).seconds

private const val MILLIS_PER_SECOND = 1000
