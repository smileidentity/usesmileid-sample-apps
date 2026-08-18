package com.usesmileid.sampleapps.android.flow

import kotlin.io.encoding.Base64

/**
 * Structurally valid, unsigned sandbox JWTs — fixtures the scenarios demand (`spec/scenarios.json`:
 * "a well-formed JWT whose exp is in the past"), never credentials. Flows stop at the capture
 * screen, so these are parsed by the SDK's pre-flight and refresh logic but never submitted.
 */
object UseSmileIDSampleFlowTokens {

    fun token(expired: Boolean, nowMillis: Long): String {
        val exp = nowMillis / MILLIS_PER_SECOND + if (expired) -VALIDITY_SECONDS else VALIDITY_SECONDS
        return listOf(HEADER, """{"exp":$exp}""", SIGNATURE).joinToString(".", transform = ::base64Url)
    }

    fun malformed(): String = "sample-not-a-jwt"

    private fun base64Url(value: String): String =
        Base64.UrlSafe.withPadding(Base64.PaddingOption.ABSENT).encode(value.toByteArray(Charsets.UTF_8))

    private const val HEADER = """{"alg":"none","typ":"JWT"}"""
    private const val SIGNATURE = "sample-signature"
    private const val MILLIS_PER_SECOND = 1000L
    private const val VALIDITY_SECONDS = 3600L
}
