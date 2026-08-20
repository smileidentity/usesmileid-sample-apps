package com.usesmileid.sampleapps.ui.state

import androidx.compose.runtime.Immutable
import kotlin.time.Duration
import kotlin.time.DurationUnit
import kotlin.time.toDuration

/**
 * A linked session: the token a run submits under, held as an absolute deadline because a counter
 * restarts at the wrong value after process death. Built only by
 * [UseSmileIDSampleTokenDecoder], so a session cannot exist without a token that decodes.
 */
@Immutable
data class UseSmileIDSampleTokenSession(
    /** A display handle — the token's `jti`, else a digest of it. Never a prefix of the credential. */
    val id: String,
    val token: String,
    val issuedAtMillis: Long,
    val expiresAtMillis: Long,
    val bindings: UseSmileIDSampleTokenBindings,
    /**
     * The partner the token was minted for, from its own `partner_id` claim. The authority for a
     * submission's identity: sending a locally configured id alongside a real token is how a signed
     * request gets a 401. Never logged — a partner id is on this repo's never-commit list.
     */
    val partnerId: String? = null,
) {

    fun remaining(nowMillis: Long): Duration = (expiresAtMillis - nowMillis).coerceAtLeast(0L).milliseconds

    fun hasExpired(nowMillis: Long): Boolean = nowMillis >= expiresAtMillis

    /**
     * 1f on a fresh session down to 0f on an expired one, over the token's own span, for the nav bar's
     * ring. The decoder rejects a token whose `exp` is not after its `iat`, so the span is positive by
     * construction — but this constructor is public, and a zero span would divide to `NaN`, which
     * `coerceIn` passes straight through to the ring.
     */
    fun progress(nowMillis: Long): Float {
        val span = (expiresAtMillis - issuedAtMillis).coerceAtLeast(1L)
        return (remaining(nowMillis).inWholeMilliseconds.toFloat() / span).coerceIn(0f, 1f)
    }

    /** Redacted: the generated `toString` is how a bearer credential reaches a log or a crash report. */
    override fun toString(): String = "UseSmileIDSampleTokenSession(id=$id, expiresAtMillis=$expiresAtMillis)"
}

/** `m:ss`, growing an hours part when the span needs one — an 8h token reads 7:59:12, not 479:12. */
fun Duration.toCountdown(): String {
    val total = inWholeSeconds
    val minutes = (total % SECONDS_PER_HOUR) / SECONDS_PER_MINUTE
    val seconds = total % SECONDS_PER_MINUTE
    val hours = total / SECONDS_PER_HOUR
    return if (hours > 0) {
        "$hours:${minutes.padded()}:${seconds.padded()}"
    } else {
        "$minutes:${seconds.padded()}"
    }
}

private fun Long.padded(): String = toString().padStart(2, '0')

private const val SECONDS_PER_MINUTE = 60
private const val SECONDS_PER_HOUR = 3600

/** Exact rather than divided through a Double, so the countdown and the ring agree to the millisecond. */
private val Long.milliseconds: Duration get() = toDuration(DurationUnit.MILLISECONDS)
