package com.usesmileid.sampleapps.android

import com.usesmileid.sampleapps.android.flow.FlowLaunchSnapshot
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import org.junit.Assert.assertEquals
import org.junit.Test

class FlowLaunchSnapshotEnvironmentTest {

    @Test
    fun `the card's environment is the boolean the builder was handed`() {
        assertEquals(UseSmileIDSampleEnvironment.Sandbox, snapshot(sandbox = true).environment)
        assertEquals(UseSmileIDSampleEnvironment.Production, snapshot(sandbox = false).environment)
    }

    @Test
    fun `the two names are the ones the schema enumerates`() {
        assertEquals("sandbox", snapshot(sandbox = true).environment.id)
        assertEquals("production", snapshot(sandbox = false).environment.id)
    }

    private fun snapshot(sandbox: Boolean) = FlowLaunchSnapshot(
        product = UseSmileIDSampleProduct.SmartSelfieEnrollment,
        route = UseSmileIDSampleFlowRoute.Fullscreen,
        userDetails = UseSmileIDSampleUserDetails(),
        idDetails = UseSmileIDSampleIdDetails(),
        scenario = UseSmileIDSampleScenario.Normal,
        theme = UseSmileIDSampleThemeScenario.BrandDefault,
        sandbox = sandbox,
        allowAgentMode = false,
        enableEnhancedLiveness = true,
        consentStep = true,
        instructionsStep = true,
        previewStep = true,
        userId = "sample-user",
        partnerId = "p-1",
        partnerName = "UpTech Finance",
        callbackUrl = "",
    )
}
