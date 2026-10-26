package com.usesmileid.sampleapps.android

import com.usesmileid.core.exception.AgentModeWithEnhancedLivenessException
import com.usesmileid.core.exception.InvalidFieldValueException
import com.usesmileid.core.exception.UseSmileIDValidationException
import com.usesmileid.sampleapps.android.flow.BOUND_COUNTRY
import com.usesmileid.sampleapps.android.flow.BOUND_ID_TYPE
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
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCaptureAs
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCountry
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleDocument
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleKycIdType
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenDecoder
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import java.util.Base64
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Preflight's last gate is `validate()`, which returns the verdict the SDK's `build()` reaches, so a
 * flow it passes is one the SDK accepts. Under Robolectric because the SDK reads the token's bindings
 * with `android.util.Base64`, which a plain JVM test stubs out.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
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
    fun `authentication without a user ID goes to the user ID screen, not to the SDK`() {
        val verdict = preflight(snapshotFor(UseSmileIDSampleProduct.SmartSelfieAuth).copy(userId = "  "))
        assertEquals(FlowPreflight.NeedsUserId, verdict)
    }

    @Test
    fun `no other product needs a user ID, because the server issues one`() {
        UseSmileIDSampleProduct.entries.filter { it != UseSmileIDSampleProduct.SmartSelfieAuth }.forEach { product ->
            assertEquals("$product", FlowPreflight.Ready, preflight(snapshotFor(product).copy(userId = "")))
        }
    }

    @Test
    fun `missing user details reach the SDK, for the API to judge`() {
        UseSmileIDSampleProduct.entries.forEach { product ->
            assertEquals("$product", FlowPreflight.Ready, preflight(snapshotFor(product).copy(userDetails = UseSmileIDSampleUserDetails())))
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
    fun `names without a contact field reach the SDK, for the API to judge`() {
        val namesOnly = UseSmileIDSampleUserDetails(firstName = "Ada", lastName = "Okafor")
        assertEquals(FlowPreflight.Ready, preflight(snapshotFor(UseSmileIDSampleProduct.SmartSelfieEnrollment).copy(userDetails = namesOnly)))
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
    fun `a run with no session at all goes to the scanner rather than the SDK`() {
        assertEquals(
            FlowPreflight.NeedsSession,
            preflight(snapshotFor(UseSmileIDSampleProduct.SmartSelfieEnrollment).copy(session = null)),
        )
    }

    @Test
    fun `a token binding the required details does not send the journey back to a form`() {
        val snapshot = snapshotFor(UseSmileIDSampleProduct.SmartSelfieEnrollment).copy(
            userDetails = UseSmileIDSampleUserDetails(),
            session = session(UseSmileIDSampleSimulatedBindings(userDetails = true)),
        )
        assertEquals(FlowPreflight.Ready, preflight(snapshot))
    }

    @Test
    fun `user details are left to the API whatever the token binds`() {
        listOf(
            session(UseSmileIDSampleSimulatedBindings(consent = true)),
            boundSession(""""given_names":"pii_1","last_name":"pii_2""""),
            boundSession(""""phone_number":"pii_1""""),
        ).forEach { bound ->
            val snapshot = snapshotFor(UseSmileIDSampleProduct.SmartSelfieEnrollment).copy(
                userDetails = UseSmileIDSampleUserDetails(),
                session = bound,
            )
            assertEquals(FlowPreflight.Ready, preflight(snapshot))
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
                country = UseSmileIDSampleCountry("NG", "Nigeria"),
                idType = UseSmileIDSampleKycIdType("NIN", "NIN", "National ID", "^[0-9]{11}$"),
                idNumber = "form-typed-number",
            ),
            session = session(UseSmileIDSampleSimulatedBindings(userDetails = true)),
        )
        val params = requireNotNull(UseSmileIDFlowBuilder().apply { applying(snapshot) }.enhancedKYCParams)
        assertEquals(BOUND_COUNTRY, params.country)
        assertEquals(BOUND_ID_TYPE, params.idType)
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
        assertEquals("KE", params.country)
        assertEquals("0000000", params.idNumber)
    }

    // The UI never persists agent mode with enhanced liveness; the mutex is tested in `sample-ui`.
    @Test
    fun `every capture combination the UI can persist reaches the SDK`() {
        val allowed = listOf(false to true, true to false, false to false)
        UseSmileIDSampleProduct.entries.forEach { product ->
            allowed.forEach { (agentMode, enhanced) ->
                val snapshot = snapshotFor(product).copy(
                    allowAgentMode = agentMode,
                    enableEnhancedLiveness = enhanced,
                )
                assertEquals(
                    "$product with agentMode=$agentMode enhanced=$enhanced",
                    FlowPreflight.Ready,
                    preflight(snapshot),
                )
            }
        }
    }

    @Test
    fun `agent mode with enhanced liveness is refused before the SDK on every product that captures`() {
        UseSmileIDSampleProduct.entries.filter { it.capture }.forEach { product ->
            val verdict = preflight(snapshotFor(product).copy(allowAgentMode = true, enableEnhancedLiveness = true))
            assertTrue(
                "$product should be refused for the pair, got $verdict",
                verdict is FlowPreflight.Misconfigured && verdict.issues.any { it is AgentModeWithEnhancedLivenessException },
            )
        }
    }

    @Test
    fun `every document setting passes preflight, except the Green Book the SDK refuses on Enhanced Document Verification`() {
        listOf(
            UseSmileIDSampleProduct.DocumentVerification,
            UseSmileIDSampleProduct.EnhancedDocumentVerification,
            UseSmileIDSampleProduct.ResidencyDocumentVerification,
        ).forEach { product ->
            (UseSmileIDSampleCaptureAs.entries + null).forEach { captureAs ->
                listOf(true, false).forEach { flag ->
                    val base = snapshotFor(product)
                    val snapshot = base.copy(
                        idDetails = base.idDetails.copy(captureAsOverride = captureAs),
                        allowSkipBack = !flag,
                        selfieFirst = flag,
                    )
                    val verdict = preflight(snapshot)
                    val refused = product == UseSmileIDSampleProduct.EnhancedDocumentVerification &&
                        captureAs == UseSmileIDSampleCaptureAs.GreenBook
                    assertTrue(
                        "$product $captureAs flag=$flag, got $verdict",
                        if (refused) verdict is FlowPreflight.Misconfigured else verdict == FlowPreflight.Ready,
                    )
                }
            }
        }
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
            country = UseSmileIDSampleCountry("KE", "Kenya"),
            idType = UseSmileIDSampleKycIdType("NATIONAL_ID", "NATIONAL_ID", "National ID", "^[0-9]{1,9}$"),
            idNumber = "0000000",
            document = UseSmileIDSampleDocument(code = "PASSPORT", name = "Passport", hasBack = false, format = 3),
        ),
        scenario = UseSmileIDSampleScenario.Normal,
        theme = UseSmileIDSampleThemeScenario.BrandDefault,
        sandbox = true,
        allowAgentMode = false,
        enableEnhancedLiveness = true,
        consentStep = true,
        instructionsStep = true,
        previewStep = true,
        // Only authentication carries one; every other product leaves it to the server.
        userId = if (product == UseSmileIDSampleProduct.SmartSelfieAuth) ENROLLED_USER_ID else "",
        partnerId = "p-1",
        partnerName = "UpTech Finance",
        callbackUrl = "",
        session = testSession(NOW_MILLIS),
    )

    private companion object {
        const val NOW_MILLIS = 1_755_500_000_000L
        const val ENROLLED_USER_ID = "user_01m4gahg4ceceatsw25mc5dd1h"
    }
}
