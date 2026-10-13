package com.usesmileid.sampleapps.android.extension

import com.usesmileid.data.dsl.UseSmileIDNetworkBuilder
import com.usesmileid.presentation.flow.dsl.UseSmileIDFlowBuilder
import com.usesmileid.sampleapps.android.flow.FlowLaunchSnapshot
import com.usesmileid.sampleapps.android.flow.applying
import com.usesmileid.sampleapps.android.testSession
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import org.junit.Assert.assertEquals
import org.junit.Test

class UseSmileIDSampleCustomiseNetworkTest {
    @Test
    fun the_extension_customises_the_network_the_shell_configured_for_the_product() {
        val customised = mutableListOf<UseSmileIDSampleProduct>()
        val extension = object : UseSmileIDSampleShellExtension {
            override fun customiseNetwork(network: UseSmileIDNetworkBuilder, product: UseSmileIDSampleProduct) {
                customised += product
            }
        }
        UseSmileIDFlowBuilder().apply { applying(snapshot(UseSmileIDSampleProduct.SmartSelfieEnrollment), extension = extension) }
        assertEquals(listOf(UseSmileIDSampleProduct.SmartSelfieEnrollment), customised)
    }

    private fun snapshot(product: UseSmileIDSampleProduct) = FlowLaunchSnapshot(
        product = product,
        route = UseSmileIDSampleFlowRoute.Fullscreen,
        userDetails = UseSmileIDSampleUserDetails(firstName = "Ada", lastName = "Okafor", email = "ada@example.com"),
        idDetails = UseSmileIDSampleIdDetails(),
        scenario = UseSmileIDSampleScenario.Normal,
        theme = UseSmileIDSampleThemeScenario.BrandDefault,
        sandbox = true,
        allowAgentMode = false,
        enableEnhancedLiveness = true,
        consentStep = true,
        instructionsStep = true,
        previewStep = true,
        userId = "user",
        partnerId = "p-1",
        partnerName = "Test",
        callbackUrl = "",
        session = testSession(),
    )
}
