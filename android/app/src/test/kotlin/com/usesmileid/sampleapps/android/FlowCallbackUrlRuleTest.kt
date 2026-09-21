package com.usesmileid.sampleapps.android

import com.usesmileid.sampleapps.android.flow.FlowLaunchSnapshot
import com.usesmileid.sampleapps.android.flow.resolveCallbackUrl
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenBindings
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import com.usesmileid.sampleapps.ui.state.callbackOverrideCaption
import org.junit.Assert.assertEquals
import org.junit.Test

class FlowCallbackUrlRuleTest {

    @Test
    fun `without a session the profile's webhook is what the job carries`() {
        assertEquals(PROFILE_URL, resolveCallbackUrl(snapshot(session = null)))
    }

    @Test
    fun `a live session drops it, whether or not the token binds one of its own`() {
        assertEquals("", resolveCallbackUrl(snapshot(session = session())))
        assertEquals("", resolveCallbackUrl(snapshot(session = session(callbackUrl = "https://token.example/hook"))))
    }

    @Test
    fun `the row says which of the two applies`() {
        assertEquals("The scanned token's partner default applies", session().callbackOverrideCaption())
        assertEquals("Set by the scanned token", session(callbackUrl = "https://token.example/hook").callbackOverrideCaption())
    }

    private fun session(callbackUrl: String? = null) = UseSmileIDSampleTokenSession(
        id = "9f3a2c71",
        token = "header.payload.signature",
        issuedAtMillis = NOW - 1_000,
        expiresAtMillis = NOW + 60_000,
        bindings = UseSmileIDSampleTokenBindings(callbackUrl = callbackUrl),
        environment = UseSmileIDSampleEnvironment.Sandbox,
    )

    private fun snapshot(session: UseSmileIDSampleTokenSession?) = FlowLaunchSnapshot(
        product = UseSmileIDSampleProduct.SmartSelfieEnrollment,
        route = UseSmileIDSampleFlowRoute.Fullscreen,
        userDetails = UseSmileIDSampleUserDetails(),
        idDetails = UseSmileIDSampleIdDetails(),
        scenario = UseSmileIDSampleScenario.Normal,
        theme = UseSmileIDSampleThemeScenario.BrandDefault,
        sandbox = true,
        allowAgentMode = false,
        enableEnhancedLiveness = true,
        consentStep = true,
        instructionsStep = true,
        previewStep = true,
        userId = "sample-user",
        partnerId = "p-1",
        partnerName = "UpTech Finance",
        callbackUrl = PROFILE_URL,
        session = session,
    )

    private companion object {
        const val NOW = 1_760_000_000_000L
        const val PROFILE_URL = "https://profile.example/hook"
    }
}
