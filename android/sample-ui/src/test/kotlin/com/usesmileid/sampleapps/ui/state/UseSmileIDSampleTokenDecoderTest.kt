package com.usesmileid.sampleapps.ui.state

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import java.util.Base64
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The decode rules, held against the SDK's own. `TokenPayload.fromClaim` and
 * `bindsRequiredUserDetails` are `internal`, so these cases are what stop this duplicate drifting
 * from the rules the SDK actually applies at `build()`.
 */
class UseSmileIDSampleTokenDecoderTest {

    @Test
    fun `a token is three base64url segments or it is not a token`() {
        listOf(
            "not-a-jwt",
            "two.segments",
            "four.of.these.segments",
            "header..signature",
            "header.pay load.signature",
            "header.payload+slash.signature",
        ).forEach { candidate ->
            assertTrue("$candidate should be rejected", decoder(candidate) is UseSmileIDSampleTokenDecode.Rejected)
        }
    }

    @Test
    fun `surrounding whitespace is trimmed rather than rejected`() {
        val session = session("  ${token()}\n")
        assertNotNull("a pasted token with whitespace should decode", session)
    }

    @Test
    fun `a payload segment that is not base64url json is rejected`() {
        assertTrue(decoder("aGVhZGVy.@@@@.c2ln") is UseSmileIDSampleTokenDecode.Rejected)
        assertTrue(decoder(jwt("[1,2,3]")) is UseSmileIDSampleTokenDecode.Rejected)
        assertTrue(decoder(jwt("{\"exp\":")) is UseSmileIDSampleTokenDecode.Rejected)
    }

    @Test
    fun `both time claims are required, and exp must be after iat`() {
        assertTrue(decoder(jwt("""{"iat":$IAT}""")) is UseSmileIDSampleTokenDecode.Rejected)
        assertTrue(decoder(jwt("""{"exp":$EXP}""")) is UseSmileIDSampleTokenDecode.Rejected)
        assertTrue(decoder(jwt("""{"iat":$EXP,"exp":$IAT}""")) is UseSmileIDSampleTokenDecode.Rejected)
        assertTrue(decoder(jwt("""{"iat":$IAT,"exp":"$EXP"}""")) is UseSmileIDSampleTokenDecode.Rejected)
    }

    @Test
    fun `a rejection names the structure that failed and never the token`() {
        val candidate = jwt("""{"iat":$IAT}""")
        val reason = (decoder(candidate) as UseSmileIDSampleTokenDecode.Rejected).reason
        assertTrue("reason should name the claim: $reason", reason.contains("exp"))
        assertFalse("reason must not carry the token", reason.contains(candidate.split(".")[1]))
    }

    @Test
    fun `epoch seconds become the absolute deadline in millis`() {
        val session = requireNotNull(session(token()))
        assertEquals(IAT * 1000, session.issuedAtMillis)
        assertEquals(EXP * 1000, session.expiresAtMillis)
    }

    @Test
    fun `the handle is the jti when the token carries one`() {
        val session = requireNotNull(session(jwt("""{"iat":$IAT,"exp":$EXP,$SANDBOX_URL,"jti":"sess_7f2"}""")))
        assertEquals("sess_7f2", session.id)
    }

    @Test
    fun `without a jti the handle is a short digest, never a prefix of the credential`() {
        val token = token()
        val session = requireNotNull(session(token))
        assertTrue("handle should be short hex, was ${session.id}", session.id.matches(Regex("[0-9a-f]{8}")))
        assertFalse(token.startsWith(session.id))
        assertFalse(token.contains(session.id))
        assertEquals("the same token must give the same handle", session.id, session(token)?.id)
    }

    @Test
    fun `toString redacts the token, because that is how a credential reaches a log`() {
        val session = requireNotNull(session(token()))
        assertFalse(session.toString().contains(session.token))
    }

    @Test
    fun `each known host maps to its environment, whatever the scheme, port, path or case`() {
        mapOf(
            "https://testapi.smileidentity.com/v3" to UseSmileIDSampleEnvironment.Sandbox,
            "https://testapi.smileidentity.com/" to UseSmileIDSampleEnvironment.Sandbox,
            "https://testapi.smileidentity.com" to UseSmileIDSampleEnvironment.Sandbox,
            "HTTPS://TestApi.SmileIdentity.COM/v3" to UseSmileIDSampleEnvironment.Sandbox,
            // The SDK's constant carries the trailing slash a real claim does not; both must land.
            "https://api.smileidentity.com/" to UseSmileIDSampleEnvironment.Production,
            "https://api.smileidentity.com/v3" to UseSmileIDSampleEnvironment.Production,
            "http://api.smileidentity.com/v3" to UseSmileIDSampleEnvironment.Production,
            "https://api.smileidentity.com:443/v3" to UseSmileIDSampleEnvironment.Production,
        ).forEach { (url, expected) ->
            val session = requireNotNull(session(tokenWithApiUrl(""""api_url":"$url""""))) { "$url did not decode" }
            assertEquals(url, expected, session.environment)
        }
    }

    @Test
    fun `an unrecognised host is refused rather than falling back, and the rejection names it`() {
        val reason = rejection(tokenWithApiUrl(""""api_url":"https://api.smileidentity.com.evil.test/v3""""))
        assertTrue("the rejection should name the host it saw: $reason", reason.contains("api.smileidentity.com.evil.test"))
    }

    @Test
    fun `a host that only looks like one of ours is not one of ours`() {
        listOf(
            "https://smileidentity.com/v3",
            "https://api.smileidentity.com.br/v3",
            "https://testapi.smileidentity.co/v3",
            // No authority, so there is no host to match.
            "testapi.smileidentity.com/v3",
        ).forEach { url ->
            assertTrue("$url should be refused", decoder(tokenWithApiUrl(""""api_url":"$url"""")) is UseSmileIDSampleTokenDecode.Rejected)
        }
    }

    @Test
    fun `a malformed api_url is refused, and says so without pretending to name a host`() {
        val reason = rejection(tokenWithApiUrl(""""api_url":"not a url at all""""))
        assertTrue("reason should say it is not a URL: $reason", reason.contains("not a URL"))
    }

    @Test
    fun `an absent, blank or non-string api_url refuses the token`() {
        listOf(""""jti":"sess_7f2"""", """"api_url":""""", """"api_url":"  """", """"api_url":42""")
            .forEach { claim ->
                val reason = rejection(tokenWithApiUrl(claim))
                assertTrue("$claim should be refused for the claim: $reason", reason.contains("api_url"))
            }
    }

    @Test
    fun `the redacted toString reports the environment as a value, because a host is public`() {
        val session = requireNotNull(session(token()))
        assertTrue(session.toString().contains("Sandbox"))
    }

    @Test
    fun `a field binds only when the claim carries it as a non-empty string`() {
        val bindings = bindings(
            """"given_names":"vault_given_names","last_name":"","email":42,"phone_number":null""",
        )
        assertTrue(bindings.givenNames)
        assertFalse("an empty string is not a binding", bindings.lastName)
        assertFalse("a number is not a binding", bindings.email)
        assertFalse("null is not a binding", bindings.phoneNumber)
    }

    @Test
    fun `an object or array in a user-detail field is not a binding`() {
        val bindings = bindings(""""given_names":{"vault":"x"},"last_name":["x"]""")
        assertFalse(bindings.givenNames)
        assertFalse(bindings.lastName)
    }

    @Test
    fun `the two plaintext claims and the ID number's vault reference are all read`() {
        val bindings = bindings(""""country":"KE","id_type":"NATIONAL_ID","id_number":"pii_fixture01"""")
        assertEquals("KE", bindings.country)
        assertEquals("NATIONAL_ID", bindings.idType)
        assertEquals("pii_fixture01", bindings.idNumberReference)
    }

    @Test
    fun `a blank value claim reads as absent, unlike the presence flags`() {
        val bindings = bindings(""""country":" ","id_type":"","id_number":"  """")
        assertNull(bindings.country)
        assertNull(bindings.idType)
        assertNull(bindings.idNumberReference)
    }

    @Test
    fun `the KYC products need country, ID type and the ID number reference before their form is skipped`() {
        val bound = UseSmileIDSampleTokenBindings(country = "KE", idType = "NATIONAL_ID", idNumberReference = "pii_1")
        listOf(UseSmileIDSampleProduct.EnhancedKyc, UseSmileIDSampleProduct.BiometricKyc).forEach { product ->
            assertTrue(bound.bindsIdDetails(product))
            assertFalse(bound.copy(idNumberReference = null).bindsIdDetails(product))
            assertFalse(bound.copy(idType = null).bindsIdDetails(product))
            assertFalse(bound.copy(country = null).bindsIdDetails(product))
        }
    }

    @Test
    fun `both document products need country and ID type, and neither needs an ID number`() {
        val bound = UseSmileIDSampleTokenBindings(country = "KE", idType = "NATIONAL_ID")
        listOf(
            UseSmileIDSampleProduct.DocumentVerification,
            UseSmileIDSampleProduct.EnhancedDocumentVerification,
        ).forEach { product ->
            assertTrue(bound.bindsIdDetails(product))
            // Document Verification's own validator accepts a null idType, but the form is where the
            // document type is chosen — so a partial binding must still go through it.
            assertFalse(bound.copy(idType = null).bindsIdDetails(product))
            assertFalse(bound.copy(country = null).bindsIdDetails(product))
        }
    }

    @Test
    fun `a product that submits no ID parameters is never sent to the form`() {
        listOf(UseSmileIDSampleProduct.SmartSelfieEnrollment, UseSmileIDSampleProduct.SmartSelfieAuth)
            .forEach { assertTrue(UseSmileIDSampleTokenBindings().bindsIdDetails(it)) }
    }

    @Test
    fun `the bindings toString reports presence, because a vault reference is still a claim value`() {
        val text = bindings(""""country":"KE","id_type":"NATIONAL_ID","id_number":"pii_fixture01"""").toString()
        listOf("KE", "NATIONAL_ID", "pii_fixture01").forEach {
            assertFalse("toString must not carry $it", text.contains(it))
        }
    }

    @Test
    fun `an absent or empty consent object is no consent binding`() {
        assertNull(bindings(""""email":"vault_email"""").consent)
        assertNull(bindings(""""consent":{}""").consent)
        assertNull(bindings(""""consent":[]""").consent)
        assertNull(bindings(""""consent":"granted"""").consent)
    }

    @Test
    fun `granted false or non-boolean never counts toward a consent binding`() {
        listOf("false", """"true"""", "1", "null").forEach { granted ->
            val consent = requireNotNull(bindings(""""consent":{"granted":$granted,"granted_at":"$GRANTED_AT"}""").consent)
            assertNull("granted:$granted should read as absent", consent.granted)
            assertFalse(consent.isComplete)
        }
    }

    @Test
    fun `consent is complete only with granted true and all three subfields non-blank`() {
        assertTrue(bindings(CONSENT).consent!!.isComplete)
        assertFalse(bindings(consent(grantedAt = "")).consent!!.isComplete)
        assertFalse(bindings(consent(language = " ")).consent!!.isComplete)
        assertFalse(bindings(consent(policyUrl = null)).consent!!.isComplete)
        assertFalse(bindings(consent(granted = "false")).consent!!.isComplete)
    }

    @Test
    fun `a non-string consent subfield reads as absent`() {
        val consent = requireNotNull(bindings(""""consent":{"granted":true,"granted_at":1755500000}""").consent)
        assertNull(consent.grantedAt)
        assertFalse(consent.isComplete)
    }

    @Test
    fun `required user details are both names plus one contact field`() {
        val names = UseSmileIDSampleTokenBindings(givenNames = true, lastName = true)
        assertFalse("names alone relax nothing", names.bindsRequiredUserDetails)
        assertTrue(names.copy(email = true).bindsRequiredUserDetails)
        assertTrue(names.copy(phoneNumber = true).bindsRequiredUserDetails)
        assertFalse(names.copy(givenNames = false, email = true).bindsRequiredUserDetails)
        assertFalse(UseSmileIDSampleTokenBindings(email = true, phoneNumber = true).bindsRequiredUserDetails)
    }

    @Test
    fun `a payload claim of the wrong shape leaves the token usable and unbound`() {
        // The SDK degrades a malformed `payload` claim to strict validation rather than failing.
        val session = requireNotNull(session(jwt("""{"iat":$IAT,"exp":$EXP,$SANDBOX_URL,"payload":"nonsense"}""")))
        assertEquals(UseSmileIDSampleTokenBindings(), session.bindings)
    }

    @Test
    fun `nesting past the reader's depth cap is rejected rather than crashing`() {
        val deep = "[".repeat(200) + "]".repeat(200)
        assertTrue(
            decoder(jwt("""{"iat":$IAT,"exp":$EXP,$SANDBOX_URL,"payload":$deep}"""))
                is UseSmileIDSampleTokenDecode.Rejected,
        )
    }

    private fun decoder(token: String) = UseSmileIDSampleTokenDecoder.decode(token)

    private fun session(token: String) = UseSmileIDSampleTokenDecoder.session(token)

    private fun bindings(payloadFields: String) =
        requireNotNull(session(jwt("""{"iat":$IAT,"exp":$EXP,$SANDBOX_URL,"payload":{$payloadFields}}"""))).bindings

    private fun consent(
        granted: String = "true",
        grantedAt: String? = GRANTED_AT,
        language: String? = "en",
        policyUrl: String? = "https://smile.id/privacy-policy",
    ) = """"consent":{"granted":$granted,"granted_at":${quoted(grantedAt)},""" +
        """"notice_language":${quoted(language)},"notice_privacy_policy_url":${quoted(policyUrl)}}"""

    private fun quoted(value: String?) = if (value == null) "null" else "\"$value\""

    private fun token() = jwt("""{"iat":$IAT,"exp":$EXP,$SANDBOX_URL}""")

    private fun tokenWithApiUrl(claim: String) = jwt("""{"iat":$IAT,"exp":$EXP,$claim}""")

    private fun rejection(token: String) = (decoder(token) as UseSmileIDSampleTokenDecode.Rejected).reason

    private fun jwt(claims: String) = listOf(HEADER, claims, "sample-signature")
        .joinToString(".") { Base64.getUrlEncoder().withoutPadding().encodeToString(it.toByteArray()) }

    private companion object {
        const val IAT = 1_755_500_000L
        const val EXP = 1_755_500_900L
        const val GRANTED_AT = "2026-08-18T09:00:00Z"
        const val HEADER = """{"alg":"none","typ":"JWT"}"""

        const val SANDBOX_URL = """"api_url":"https://testapi.smileidentity.com/v3""""
        val CONSENT = """"consent":{"granted":true,"granted_at":"$GRANTED_AT",""" +
            """"notice_language":"en","notice_privacy_policy_url":"https://smile.id/privacy-policy"}"""
    }
}
