package com.usesmileid.sampleapps.android

import com.usesmileid.sampleapps.android.flow.UseSmileIDSampleFlowTokens
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleSimulatedBindings
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleSimulatedSpan
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCountry
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdType
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenBindings
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenDecoder
import com.usesmileid.sampleapps.ui.state.bindsRequiredUserDetails
import java.util.Base64
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
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

    @Test
    fun `a simulated scan mints a token the decoder reads back`() {
        UseSmileIDSampleSimulatedSpan.entries.forEach { span ->
            val session = UseSmileIDSampleTokenDecoder.session(mint(span))
                ?: throw AssertionError("the minted token for $span did not decode")
            assertEquals(span.span.inWholeMilliseconds, session.expiresAtMillis - session.issuedAtMillis)
        }
    }

    @Test
    fun `only the ended span mints a session that is already over`() {
        UseSmileIDSampleSimulatedSpan.entries.forEach { span ->
            val session = requireNotNull(UseSmileIDSampleTokenDecoder.session(mint(span)))
            assertEquals("$span expiry", span.ended, session.hasExpired(NOW_MILLIS))
        }
    }

    @Test
    fun `an unbound simulated token carries no payload claim at all`() {
        val session = requireNotNull(UseSmileIDSampleTokenDecoder.session(mint(SPAN)))
        assertEquals(UseSmileIDSampleTokenBindings(), session.bindings)
    }

    @Test
    fun `a consent binding is complete, because a partial one is an SDK build error`() {
        val bindings = bindingsOf(UseSmileIDSampleSimulatedBindings(consent = true))
        assertTrue("the SDK drops its consent screen only on a complete binding", bindings.consent!!.isComplete)
        assertFalse("consent alone binds no user detail", bindings.bindsRequiredUserDetails)
    }

    @Test
    fun `a details binding covers what the SDK relaxes, plus the two plaintext fields`() {
        val bindings = bindingsOf(UseSmileIDSampleSimulatedBindings(userDetails = true))
        assertTrue(bindings.bindsRequiredUserDetails)
        assertEquals(UseSmileIDSampleCountry.Kenya.code, bindings.country)
        assertEquals(UseSmileIDSampleIdType.NationalId.id, bindings.idType)
        assertNull("details alone bind no consent", bindings.consent)
    }

    @Test
    fun `no minted token carries a plausible personal value in place of a vault reference`() {
        val claims = decode(mint(SPAN, UseSmileIDSampleSimulatedBindings(consent = true, userDetails = true)).split(".")[1])
        listOf("given_names", "last_name", "email", "phone_number", "id_number").forEach { field ->
            assertTrue("$field should hold a vault placeholder", claims.contains("\"$field\":\"vault_$field\""))
        }
    }

    @Test
    fun `a simulated scan mints either host, in the shape a real claim carries`() {
        UseSmileIDSampleEnvironment.entries.forEach { environment ->
            val minted = mint(SPAN, environment = environment)
            assertTrue(
                "the fixture should carry the /v3 path a real token does",
                decode(minted.split(".")[1]).contains(""""api_url":"https://${environment.host}/v3""""),
            )
            assertEquals(environment, UseSmileIDSampleTokenDecoder.session(minted)?.environment)
        }
    }

    private fun bindingsOf(bindings: UseSmileIDSampleSimulatedBindings) =
        requireNotNull(UseSmileIDSampleTokenDecoder.session(mint(SPAN, bindings))).bindings

    private fun mint(
        span: UseSmileIDSampleSimulatedSpan,
        bindings: UseSmileIDSampleSimulatedBindings = UseSmileIDSampleSimulatedBindings(),
        environment: UseSmileIDSampleEnvironment = UseSmileIDSampleEnvironment.Sandbox,
    ) = UseSmileIDSampleFlowTokens.session(
        span = span,
        bindings = bindings,
        environment = environment,
        nowMillis = NOW_MILLIS,
    )

    private fun decode(segment: String) = String(Base64.getUrlDecoder().decode(segment), Charsets.UTF_8)

    private fun expOf(token: String) = decode(token.split(".")[1])
        .removePrefix("""{"exp":""")
        .removeSuffix("}")
        .toLong()

    private companion object {
        const val NOW_MILLIS = 1_755_500_000_000L
        val SPAN = UseSmileIDSampleSimulatedSpan.FifteenMinutes
    }
}
