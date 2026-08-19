package com.usesmileid.sampleapps.android.flow

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleSimulatedBindings
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleSimulatedSpan
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCountry
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdType
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import kotlin.io.encoding.Base64

/**
 * Structurally valid unsigned JWTs — fixtures the scenarios demand ("a well-formed JWT whose exp is
 * in the past"), never credentials.
 */
object UseSmileIDSampleFlowTokens {

    fun token(expired: Boolean, nowMillis: Long): String {
        val exp = nowMillis / MILLIS_PER_SECOND + if (expired) -VALIDITY_SECONDS else VALIDITY_SECONDS
        return listOf(HEADER, """{"exp":$exp}""", SIGNATURE).joinToString(".", transform = ::base64Url)
    }

    fun malformed(): String = "sample-not-a-jwt"

    /**
     * What a simulated scan links. The same unsigned shape, over the chosen span and carrying the
     * chosen bindings — enough to exercise every client-side rule, because the SDK decodes a token
     * but never verifies one. What it cannot exercise is a server accepting it.
     *
     * The PII values are deliberate nonsense: a real token carries an opaque vault reference in their
     * place, so no plausible-looking name or number belongs in a fixture.
     */
    fun session(
        span: UseSmileIDSampleSimulatedSpan,
        bindings: UseSmileIDSampleSimulatedBindings,
        nowMillis: Long,
    ): String {
        val nowSeconds = nowMillis / MILLIS_PER_SECOND
        // An ended span is minted wholly in the past, which is the only way to reach the expiry gate.
        val issuedAt = if (span.ended) nowSeconds - span.span.inWholeSeconds - ENDED_LAG_SECONDS else nowSeconds
        val claims = buildList {
            add(""""iat":$issuedAt""")
            add(""""exp":${issuedAt + span.span.inWholeSeconds}""")
            if (bindings.binds) add(payloadClaim(bindings, issuedAt))
        }
        return listOf(HEADER, claims.joinToString(",", prefix = "{", postfix = "}"), SIGNATURE)
            .joinToString(".", transform = ::base64Url)
    }

    private fun payloadClaim(bindings: UseSmileIDSampleSimulatedBindings, issuedAtSeconds: Long): String {
        val fields = buildList {
            if (bindings.userDetails) {
                VAULTED_FIELDS.forEach { field -> add(""""$field":"vault_$field"""") }
                // The two the Portal leaves in plaintext, so a decode can read them back.
                add(""""country":"${UseSmileIDSampleCountry.Kenya.code}"""")
                add(""""id_type":"${UseSmileIDSampleIdType.NationalId.id}"""")
            }
            if (bindings.consent) add(consentClaim(issuedAtSeconds))
        }
        return fields.joinToString(",", prefix = """"payload":{""", postfix = "}")
    }

    /** All four subfields: the SDK treats a partial binding as a build error, not a partial relaxation. */
    private fun consentClaim(issuedAtSeconds: Long): String {
        val grantedAt = SimpleDateFormat(GRANTED_AT_FORMAT, Locale.US)
            .apply { timeZone = TimeZone.getTimeZone("UTC") }
            .format(Date(issuedAtSeconds * MILLIS_PER_SECOND))
        return """"consent":{"granted":true,"granted_at":"$grantedAt",""" +
            """"notice_language":"en","notice_privacy_policy_url":"$PRIVACY_POLICY_URL"}"""
    }

    private fun base64Url(value: String): String =
        Base64.UrlSafe.withPadding(Base64.PaddingOption.ABSENT).encode(value.toByteArray(Charsets.UTF_8))

    private const val HEADER = """{"alg":"none","typ":"JWT"}"""
    private const val SIGNATURE = "sample-signature"
    private const val MILLIS_PER_SECOND = 1000L
    private const val VALIDITY_SECONDS = 3600L
    private const val ENDED_LAG_SECONDS = 60L
    private const val GRANTED_AT_FORMAT = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    private const val PRIVACY_POLICY_URL = "https://usesmileid.com/privacy-policy"
    private val VAULTED_FIELDS = listOf("given_names", "last_name", "email", "phone_number", "id_number")
}
