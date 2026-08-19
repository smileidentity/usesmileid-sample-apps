package com.usesmileid.sampleapps.android

import com.usesmileid.sampleapps.android.flow.UseSmileIDSampleFlowTokens
import java.util.Base64
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class UseSmileIDSampleFlowTokensTest {

    @Test
    fun `token is a three-segment jwt with a numeric exp claim`() {
        val segments = UseSmileIDSampleFlowTokens.token(expired = false, nowMillis = NOW_MILLIS).split(".")
        assertEquals(3, segments.size)
        assertEquals("""{"alg":"none","typ":"JWT"}""", decode(segments[0]))
        assertTrue(decode(segments[1]).matches(Regex("""\{"exp":\d+}""")))
    }

    @Test
    fun `expired token has exp in the past and a fresh one in the future`() {
        val nowSeconds = NOW_MILLIS / 1000
        assertTrue(expOf(UseSmileIDSampleFlowTokens.token(expired = true, nowMillis = NOW_MILLIS)) < nowSeconds)
        assertTrue(expOf(UseSmileIDSampleFlowTokens.token(expired = false, nowMillis = NOW_MILLIS)) > nowSeconds)
    }

    @Test
    fun `no segment carries padding characters that break url-safe consumers`() {
        val token = UseSmileIDSampleFlowTokens.token(expired = false, nowMillis = NOW_MILLIS)
        assertTrue(token.matches(Regex("""[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+""")))
    }

    private fun decode(segment: String) = String(Base64.getUrlDecoder().decode(segment), Charsets.UTF_8)

    private fun expOf(token: String) = decode(token.split(".")[1])
        .removePrefix("""{"exp":""")
        .removeSuffix("}")
        .toLong()

    private companion object {
        const val NOW_MILLIS = 1_755_500_000_000L
    }
}
