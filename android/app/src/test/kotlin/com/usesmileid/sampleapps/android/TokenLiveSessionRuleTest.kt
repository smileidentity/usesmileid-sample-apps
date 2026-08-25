package com.usesmileid.sampleapps.android

import com.usesmileid.sampleapps.android.flow.liveAt
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenBindings
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class TokenLiveSessionRuleTest {

    @Test
    fun `a live session under an ordinary scenario is readable`() {
        assertNotNull(session(expiresInMillis = 60_000).liveAt(UseSmileIDSampleScenario.Normal, NOW))
    }

    @Test
    fun `an expired session is not readable, and the deadline itself counts as expired`() {
        assertNull(session(expiresInMillis = -1).liveAt(UseSmileIDSampleScenario.Normal, NOW))
        assertNull(session(expiresInMillis = 0).liveAt(UseSmileIDSampleScenario.Normal, NOW))
    }

    @Test
    fun `no session at all is not readable`() {
        assertNull(null.liveAt(UseSmileIDSampleScenario.Normal, NOW))
    }

    @Test
    fun `the two refresh scenarios are never read from, however live their fixture looks`() {
        listOf(UseSmileIDSampleScenario.ExpiredToken, UseSmileIDSampleScenario.BadRefresh).forEach { scenario ->
            assertNull(
                "$scenario must not expose token values",
                session(expiresInMillis = 60_000).liveAt(scenario, NOW),
            )
        }
    }

    @Test
    fun `every other scenario reads a live session, so the exclusion stays a short list`() {
        val excluded = setOf(UseSmileIDSampleScenario.ExpiredToken, UseSmileIDSampleScenario.BadRefresh)
        UseSmileIDSampleScenario.entries.filterNot { it in excluded }.forEach { scenario ->
            assertNotNull("$scenario should read a live session", session(expiresInMillis = 60_000).liveAt(scenario, NOW))
        }
    }

    private fun session(expiresInMillis: Long) = UseSmileIDSampleTokenSession(
        id = "9f3a2c71",
        token = "header.payload.signature",
        issuedAtMillis = NOW - 1_000,
        expiresAtMillis = NOW + expiresInMillis,
        bindings = UseSmileIDSampleTokenBindings(country = "KE", idType = "NATIONAL_ID"),
        environment = UseSmileIDSampleEnvironment.Sandbox,
    )

    private companion object {
        const val NOW = 1_760_000_000_000L
    }
}
