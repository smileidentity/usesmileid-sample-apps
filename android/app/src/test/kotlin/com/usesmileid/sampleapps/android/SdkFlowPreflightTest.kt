package com.usesmileid.sampleapps.android

import com.usesmileid.sampleapps.android.flow.FlowLaunchSnapshot
import com.usesmileid.sampleapps.android.flow.FlowPreflight
import com.usesmileid.sampleapps.android.flow.preflight
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCountry
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdType
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * What the route's entry gate decides, for every product, without a device.
 *
 * Scope worth knowing, because it is narrower than "the SDK will accept this flow": on 12.0.2 the
 * public `validate()` does not report errors raised inside `screens { }` — a consent block missing
 * its icon returns Valid here and fails only in the SDK's internal `build()`. So these tests pin the
 * payload contract and the gate's routing, not the screen composition; the icon defect was found on
 * a device and no test written against this API could have caught it.
 */
class SdkFlowPreflightTest {

    @Test
    fun `every product assembles a flow the SDK accepts`() {
        UseSmileIDSampleProduct.entries.forEach { product ->
            assertEquals(
                "preflight rejected $product",
                FlowPreflight.Ready,
                preflight(snapshotFor(product)),
            )
        }
    }

    @Test
    fun `missing user details route to the forms rather than the SDK`() {
        UseSmileIDSampleProduct.entries.forEach { product ->
            val verdict = preflight(snapshotFor(product).copy(userDetails = UseSmileIDSampleUserDetails()))
            assertTrue("$product should need details, got $verdict", verdict is FlowPreflight.NeedsDetails)
        }
    }

    /** Guards the per-product ID mapping: a product whose params stop being populated fails here. */
    @Test
    fun `products needing ID details route to the forms without them`() {
        UseSmileIDSampleProduct.entries.filter { it.needsIdDetails }.forEach { product ->
            val verdict = preflight(snapshotFor(product).copy(idDetails = UseSmileIDSampleIdDetails()))
            assertTrue("$product should need ID details, got $verdict", verdict is FlowPreflight.NeedsDetails)
        }
    }

    /** The design's form treats both contact fields as optional; the SDK requires one of them. */
    @Test
    fun `names without a contact field still need details`() {
        val namesOnly = UseSmileIDSampleUserDetails(firstName = "Ada", lastName = "Okafor")
        assertTrue(namesOnly.isComplete)
        val verdict = preflight(snapshotFor(UseSmileIDSampleProduct.SmartSelfieEnrollment).copy(userDetails = namesOnly))
        assertTrue("expected NeedsDetails, got $verdict", verdict is FlowPreflight.NeedsDetails)
    }

    @Test
    fun `a phone number alone satisfies the contact requirement`() {
        val phoneOnly = UseSmileIDSampleUserDetails(firstName = "Ada", lastName = "Okafor", phone = "+10000000000")
        assertEquals(
            FlowPreflight.Ready,
            preflight(snapshotFor(UseSmileIDSampleProduct.SmartSelfieEnrollment).copy(userDetails = phoneOnly)),
        )
    }

    private fun snapshotFor(product: UseSmileIDSampleProduct) = FlowLaunchSnapshot(
        product = product,
        route = UseSmileIDSampleFlowRoute.Fullscreen,
        userDetails = UseSmileIDSampleUserDetails(
            firstName = "Ada",
            lastName = "Okafor",
            email = "ada.okafor@example.com",
        ),
        idDetails = UseSmileIDSampleIdDetails(
            country = UseSmileIDSampleCountry.Kenya,
            idType = UseSmileIDSampleIdType.NationalId,
            idNumber = "0000000",
        ),
        scenario = UseSmileIDSampleScenario.Normal,
        theme = UseSmileIDSampleThemeScenario.BrandDefault,
        sandbox = true,
        userId = "sample-user",
        partnerId = "p-1",
        partnerName = "UpTech Finance",
    )
}
