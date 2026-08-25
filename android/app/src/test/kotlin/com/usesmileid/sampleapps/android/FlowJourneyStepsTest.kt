package com.usesmileid.sampleapps.android

import com.usesmileid.sampleapps.android.flow.FlowJourneyStep
import com.usesmileid.sampleapps.android.flow.FlowLaunchSnapshot
import com.usesmileid.sampleapps.android.flow.UseSmileIDSampleFlowTokens
import com.usesmileid.sampleapps.android.flow.journeyStepsFor
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleSimulatedBindings
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleSimulatedSpan
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenDecoder
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class FlowJourneyStepsTest {

    @Test
    fun `all three steps on is the design's default journey`() {
        assertEquals(
            listOf(
                FlowJourneyStep.Consent,
                FlowJourneyStep.Instructions,
                FlowJourneyStep.SelfieCapture,
                FlowJourneyStep.Preview,
                FlowJourneyStep.Processing,
            ),
            journeyStepsFor(snapshot()),
        )
    }

    @Test
    fun `each switch off removes exactly its own screens`() {
        assertFalse(
            journeyStepsFor(snapshot().copy(consentStep = false)).contains(FlowJourneyStep.Consent),
        )
        assertFalse(
            journeyStepsFor(snapshot().copy(instructionsStep = false)).contains(FlowJourneyStep.Instructions),
        )
        assertFalse(
            journeyStepsFor(snapshot().copy(previewStep = false)).contains(FlowJourneyStep.Preview),
        )
    }

    @Test
    fun `all three off leaves the capture and the processing screen`() {
        assertEquals(
            listOf(FlowJourneyStep.SelfieCapture, FlowJourneyStep.Processing),
            journeyStepsFor(
                snapshot().copy(consentStep = false, instructionsStep = false, previewStep = false),
            ),
        )
    }

    @Test
    fun `the document products keep both previews or neither`() {
        listOf(
            UseSmileIDSampleProduct.DocumentVerification,
            UseSmileIDSampleProduct.EnhancedDocumentVerification,
        ).forEach { product ->
            val on = journeyStepsFor(snapshot(product))
            assertEquals("$product should preview both captures", 2, on.count { it == FlowJourneyStep.Preview })
            val off = journeyStepsFor(snapshot(product).copy(previewStep = false))
            assertEquals("$product should preview neither", 0, off.count { it == FlowJourneyStep.Preview })
        }
    }

    @Test
    fun `a preview always follows the capture it belongs to`() {
        UseSmileIDSampleProduct.entries.filter { it.capture }.forEach { product ->
            val steps = journeyStepsFor(snapshot(product))
            steps.forEachIndexed { index, step ->
                if (step == FlowJourneyStep.Preview) {
                    assertTrue(
                        "$product previews before capturing",
                        steps[index - 1] in
                            listOf(FlowJourneyStep.SelfieCapture, FlowJourneyStep.DocumentCapture),
                    )
                }
            }
        }
    }

    @Test
    fun `the token's consent binding beats the switch either way`() {
        val bound = snapshot().copy(session = boundSession)
        assertFalse(
            "a bound token means the SDK's screen is omitted, switch ON",
            journeyStepsFor(bound).contains(FlowJourneyStep.Consent),
        )
        assertFalse(
            "and switch OFF",
            journeyStepsFor(bound.copy(consentStep = false)).contains(FlowJourneyStep.Consent),
        )
        assertTrue(
            "unbound, the switch decides",
            journeyStepsFor(snapshot()).contains(FlowJourneyStep.Consent),
        )
    }

    // The refresh scenarios submit under the fixture token, so a scanned binding must not apply.
    @Test
    fun `the refresh scenarios ignore a bound token, so the screen stays`() {
        listOf(UseSmileIDSampleScenario.ExpiredToken, UseSmileIDSampleScenario.BadRefresh).forEach { scenario ->
            val steps = journeyStepsFor(snapshot().copy(session = boundSession, scenario = scenario))
            assertTrue("$scenario dropped the consent screen", steps.contains(FlowJourneyStep.Consent))
        }
    }

    @Test
    fun `enhanced KYC composes no capture, whatever the step switches say`() {
        val captureless = snapshot(UseSmileIDSampleProduct.EnhancedKyc)
        assertEquals(
            listOf(FlowJourneyStep.Consent, FlowJourneyStep.Processing),
            journeyStepsFor(captureless),
        )
        assertEquals(
            listOf(FlowJourneyStep.Processing),
            journeyStepsFor(captureless.copy(consentStep = false, instructionsStep = false)),
        )
    }

    private val boundSession = requireNotNull(
        UseSmileIDSampleTokenDecoder.session(
            UseSmileIDSampleFlowTokens.session(
                span = UseSmileIDSampleSimulatedSpan.EightHours,
                bindings = UseSmileIDSampleSimulatedBindings(consent = true),
                environment = UseSmileIDSampleEnvironment.Sandbox,
                nowMillis = NOW_MILLIS,
            ),
        ),
    )

    private fun snapshot(
        product: UseSmileIDSampleProduct = UseSmileIDSampleProduct.SmartSelfieEnrollment,
    ) = FlowLaunchSnapshot(
        product = product,
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
    )

    private companion object {
        const val NOW_MILLIS = 1_755_500_000_000L
    }
}
