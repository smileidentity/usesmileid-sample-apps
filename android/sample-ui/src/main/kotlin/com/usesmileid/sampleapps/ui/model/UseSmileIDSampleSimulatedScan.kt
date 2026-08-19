package com.usesmileid.sampleapps.ui.model

import androidx.compose.runtime.Immutable
import kotlin.time.Duration
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.minutes

/**
 * How long a simulated scan's token lasts. The three live spans are the Portal's own expiry
 * allow-list; [Ended] is the only way a device flow can reach the expiry gate without waiting.
 */
enum class UseSmileIDSampleSimulatedSpan(val label: String, val span: Duration, val ended: Boolean = false) {
    FifteenMinutes("15m", 15.minutes),
    OneHour("1h", 1.hours),
    EightHours("8h", 8.hours),
    Ended("Expired", 15.minutes, ended = true),
}

/**
 * What a simulated scan's token binds. Both default to off, so a simulated session never silently
 * changes the SDK's screen set: a bound consent removes the SDK's consent screen at runtime.
 */
@Immutable
data class UseSmileIDSampleSimulatedBindings(val consent: Boolean = false, val userDetails: Boolean = false) {

    val binds: Boolean get() = consent || userDetails
}
