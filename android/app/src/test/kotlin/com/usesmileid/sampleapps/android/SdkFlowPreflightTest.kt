package com.usesmileid.sampleapps.android

import com.usesmileid.core.exception.InvalidFieldValueException
import com.usesmileid.core.exception.UseSmileIDValidationException
import com.usesmileid.sampleapps.android.flow.FlowLaunchSnapshot
import com.usesmileid.sampleapps.android.flow.FlowPreflight
import com.usesmileid.sampleapps.android.flow.UseSmileIDSampleFlowTokens
import com.usesmileid.presentation.flow.dsl.UseSmileIDFlowBuilder
import com.usesmileid.sampleapps.android.flow.applying
import com.usesmileid.sampleapps.android.flow.preflight
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleSimulatedBindings
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleSimulatedSpan
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCountry
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdType
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenDecoder
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import java.util.Base64
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Narrower than "the SDK accepts this flow": `validate()` reports no error raised inside `screens { }`. */
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

    @Test
    fun `products needing ID details route to the forms without them`() {
        UseSmileIDSampleProduct.entries.filter { it.needsIdDetails }.forEach { product ->
            val verdict = preflight(snapshotFor(product).copy(idDetails = UseSmileIDSampleIdDetails()))
            assertTrue("$product should need ID details, got $verdict", verdict is FlowPreflight.NeedsDetails)
        }
    }

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

    @Test
    fun `an expired session routes to the scanner, because no form holds a token`() {
        val snapshot = snapshotFor(UseSmileIDSampleProduct.SmartSelfieEnrollment).copy(
            session = null,
            sessionExpired = true,
        )
        assertEquals(FlowPreflight.NeedsSession, preflight(snapshot))
    }

    @Test
    fun `an expired session outranks missing details, which the scanner is the only fix for`() {
        val snapshot = snapshotFor(UseSmileIDSampleProduct.SmartSelfieEnrollment).copy(
            userDetails = UseSmileIDSampleUserDetails(),
            sessionExpired = true,
        )
        assertEquals(FlowPreflight.NeedsSession, preflight(snapshot))
    }

    @Test
    fun `a run with no session at all still reaches the SDK on the fixture path`() {
        assertEquals(
            FlowPreflight.Ready,
            preflight(snapshotFor(UseSmileIDSampleProduct.SmartSelfieEnrollment).copy(session = null)),
        )
    }

    @Test
    fun `a token binding the required details does not send the journey back to a form`() {
        // The SDK relaxes these inside build(); its host-facing validateUserDetails cannot see a token.
        val snapshot = snapshotFor(UseSmileIDSampleProduct.SmartSelfieEnrollment).copy(
            userDetails = UseSmileIDSampleUserDetails(),
            session = session(UseSmileIDSampleSimulatedBindings(userDetails = true)),
        )
        assertEquals(FlowPreflight.Ready, preflight(snapshot))
    }

    @Test
    fun `a token binding only consent leaves the user-details requirement standing`() {
        val snapshot = snapshotFor(UseSmileIDSampleProduct.SmartSelfieEnrollment).copy(
            userDetails = UseSmileIDSampleUserDetails(),
            session = session(UseSmileIDSampleSimulatedBindings(consent = true)),
        )
        assertTrue(preflight(snapshot) is FlowPreflight.NeedsDetails)
    }

    @Test
    fun `the two refresh scenarios keep the fixture path, so their token relaxes nothing`() {
        listOf(UseSmileIDSampleScenario.ExpiredToken, UseSmileIDSampleScenario.BadRefresh).forEach { scenario ->
            val snapshot = snapshotFor(UseSmileIDSampleProduct.SmartSelfieEnrollment).copy(
                userDetails = UseSmileIDSampleUserDetails(),
                scenario = scenario,
                session = session(UseSmileIDSampleSimulatedBindings(userDetails = true)),
            )
            assertTrue("$scenario should still need details", preflight(snapshot) is FlowPreflight.NeedsDetails)
        }
    }

    @Test
    fun `a token supplying the ID parameters does not send the journey back to the ID form`() {
        UseSmileIDSampleProduct.entries.filter { it.needsIdDetails }.forEach { product ->
            val snapshot = snapshotFor(product).copy(
                idDetails = UseSmileIDSampleIdDetails(),
                userDetails = UseSmileIDSampleUserDetails(),
                session = session(UseSmileIDSampleSimulatedBindings(userDetails = true)),
            )
            assertEquals("$product should reach the SDK", FlowPreflight.Ready, preflight(snapshot))
        }
    }

    @Test
    fun `the token's ID parameters beat the form's, which is the rule the server applies`() {
        val snapshot = snapshotFor(UseSmileIDSampleProduct.EnhancedKyc).copy(
            idDetails = UseSmileIDSampleIdDetails(
                country = UseSmileIDSampleCountry.Nigeria,
                idType = UseSmileIDSampleIdType.Passport,
                idNumber = "form-typed-number",
            ),
            session = session(UseSmileIDSampleSimulatedBindings(userDetails = true)),
        )
        val params = requireNotNull(UseSmileIDFlowBuilder().apply { applying(snapshot) }.enhancedKYCParams)
        assertEquals(UseSmileIDSampleCountry.Kenya.code, params.country)
        assertEquals(UseSmileIDSampleIdType.NationalId.id, params.idType)
        assertEquals("the vault reference is the only ID number a token session has", "vault_id_number", params.idNumber)
    }

    @Test
    fun `the refresh scenarios keep the fixture path, so their token supplies no ID parameters either`() {
        listOf(UseSmileIDSampleScenario.ExpiredToken, UseSmileIDSampleScenario.BadRefresh).forEach { scenario ->
            val snapshot = snapshotFor(UseSmileIDSampleProduct.EnhancedKyc).copy(
                idDetails = UseSmileIDSampleIdDetails(),
                scenario = scenario,
                session = session(UseSmileIDSampleSimulatedBindings(userDetails = true)),
            )
            assertTrue("$scenario should still need ID details", preflight(snapshot) is FlowPreflight.NeedsDetails)
        }
    }

    @Test
    fun `without a session the form still decides the ID parameters`() {
        val snapshot = snapshotFor(UseSmileIDSampleProduct.EnhancedKyc).copy(session = null)
        val params = requireNotNull(UseSmileIDFlowBuilder().apply { applying(snapshot) }.enhancedKYCParams)
        assertEquals(UseSmileIDSampleCountry.Kenya.code, params.country)
        assertEquals("0000000", params.idNumber)
    }

    @Test
    fun `a token binding both names but no contact still asks for one`() {
        val bound = boundSession(""""given_names":"pii_1","last_name":"pii_2"""")
        val snapshot = snapshotFor(UseSmileIDSampleProduct.SmartSelfieEnrollment).copy(
            userDetails = UseSmileIDSampleUserDetails(),
            session = bound,
        )
        val verdict = preflight(snapshot)
        assertTrue("expected NeedsDetails, got $verdict", verdict is FlowPreflight.NeedsDetails)
        assertEquals(
            "the contact field is the only thing outstanding",
            listOf("userDetails"),
            (verdict as FlowPreflight.NeedsDetails).issues.fieldNames(),
        )
        val withContact = snapshot.copy(userDetails = UseSmileIDSampleUserDetails(email = "ada@example.com"))
        assertEquals(FlowPreflight.Ready, preflight(withContact))
    }

    @Test
    fun `a partially bound token asks only for the fields it left out`() {
        val bound = boundSession(""""given_names":"pii_1","email":"pii_2"""")
        val snapshot = snapshotFor(UseSmileIDSampleProduct.SmartSelfieEnrollment).copy(
            userDetails = UseSmileIDSampleUserDetails(),
            session = bound,
        )
        val verdict = preflight(snapshot)
        assertEquals(
            "only the last name is missing",
            listOf("userDetails.lastName"),
            (verdict as FlowPreflight.NeedsDetails).issues.fieldNames(),
        )
        val filled = snapshot.copy(userDetails = UseSmileIDSampleUserDetails(lastName = "Okafor"))
        assertEquals(FlowPreflight.Ready, preflight(filled))
    }

    @Test
    fun `a token binding only a contact still asks for both names`() {
        val snapshot = snapshotFor(UseSmileIDSampleProduct.SmartSelfieEnrollment).copy(
            userDetails = UseSmileIDSampleUserDetails(),
            session = boundSession(""""phone_number":"pii_1""""),
        )
        assertEquals(
            listOf("userDetails.givenNames", "userDetails.lastName"),
            (preflight(snapshot) as FlowPreflight.NeedsDetails).issues.fieldNames(),
        )
    }

    /** The list is typed to the base exception, which carries no field name; the subtype does. */
    private fun List<UseSmileIDValidationException>.fieldNames() =
        filterIsInstance<InvalidFieldValueException>().map { it.fieldName }

    /** A session whose token binds exactly [payloadFields] — the minter only does all or nothing. */
    private fun boundSession(payloadFields: String): UseSmileIDSampleTokenSession {
        val claims = """{"iat":${NOW_MILLIS / 1000},"exp":${NOW_MILLIS / 1000 + 900},""" +
            """"api_url":"https://testapi.smileidentity.com/v3","payload":{$payloadFields}}"""
        val token = listOf("""{"alg":"none","typ":"JWT"}""", claims, "sample-signature")
            .joinToString(".") { Base64.getUrlEncoder().withoutPadding().encodeToString(it.toByteArray()) }
        return requireNotNull(UseSmileIDSampleTokenDecoder.session(token))
    }

    private fun session(bindings: UseSmileIDSampleSimulatedBindings) = requireNotNull(
        UseSmileIDSampleTokenDecoder.session(
            UseSmileIDSampleFlowTokens.session(
                span = UseSmileIDSampleSimulatedSpan.FifteenMinutes,
                bindings = bindings,
                environment = UseSmileIDSampleEnvironment.Sandbox,
                nowMillis = NOW_MILLIS,
            ),
        ),
    )

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

    private companion object {
        const val NOW_MILLIS = 1_755_500_000_000L
    }
}
