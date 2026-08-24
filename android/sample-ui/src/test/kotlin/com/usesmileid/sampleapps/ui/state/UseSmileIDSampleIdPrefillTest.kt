package com.usesmileid.sampleapps.ui.state

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * TOK-A10. Only `country` and `id_type` arrive in plaintext, so those are the only two the form may
 * seed — and a claim the picker could not have offered must resolve to nothing rather than to a
 * value the person cannot see the provenance of.
 */
class UseSmileIDSampleIdPrefillTest {

    @Test
    fun `a country resolves from a code, an enum name or the label the picker shows`() {
        listOf("KE", "ke", "Kenya", "kenya").forEach { claim ->
            assertEquals("\"$claim\" must resolve", UseSmileIDSampleCountry.Kenya, bindings(country = claim).prefilledCountry)
        }
    }

    @Test
    fun `a country the picker does not offer resolves to nothing`() {
        listOf("US", "Wakanda", "", "   ").forEach { claim ->
            assertNull("\"$claim\" must not resolve", bindings(country = claim).prefilledCountry)
        }
        assertNull(bindings(country = null).prefilledCountry)
    }

    @Test
    fun `an id type resolves from the wire id or the enum name`() {
        listOf("NATIONAL_ID", "national_id", "NationalId").forEach { claim ->
            assertEquals(
                "\"$claim\" must resolve",
                UseSmileIDSampleIdType.NationalId,
                bindings(country = "NG", idType = claim).prefilledIdType,
            )
        }
    }

    @Test
    fun `an id type resolves unfiltered, because the form owns the country rule`() {
        assertEquals(
            UseSmileIDSampleIdType.DriversLicense,
            bindings(country = "GH", idType = "DRIVERS_LICENSE").prefilledIdType,
        )
        assertNull(bindings(country = "NG", idType = "not a type").prefilledIdType)
    }

    @Test
    fun `prefill seeds an untouched form and never the id number`() {
        val forms = UseSmileIDSampleForms()
        forms.prefillIdDetails(SESSION_A, UseSmileIDSampleCountry.Kenya, UseSmileIDSampleIdType.Passport)

        assertEquals(UseSmileIDSampleCountry.Kenya, forms.idDetails.country)
        assertEquals(UseSmileIDSampleIdType.Passport, forms.idDetails.idType)
        assertEquals("the token carries a vault reference, never a number", "", forms.idDetails.idNumber)
    }

    @Test
    fun `prefill leaves a country the person already chose alone`() {
        val forms = UseSmileIDSampleForms()
        forms.setCountry(UseSmileIDSampleCountry.Ghana)
        forms.prefillIdDetails(SESSION_A, UseSmileIDSampleCountry.Kenya, UseSmileIDSampleIdType.Passport)

        assertEquals(UseSmileIDSampleCountry.Ghana, forms.idDetails.country)
        assertNull("seeding must not smuggle a type onto their own country", forms.idDetails.idType)
    }

    @Test
    fun `prefill without a country changes nothing, since the type trigger stays disabled`() {
        val forms = UseSmileIDSampleForms()
        forms.prefillIdDetails(SESSION_A, null, UseSmileIDSampleIdType.Passport)

        assertNull(forms.idDetails.country)
        assertNull(forms.idDetails.idType)
    }

    @Test
    fun `a type the seeded country does not offer is dropped, because the picker could not show it`() {
        val forms = UseSmileIDSampleForms()
        // Ghana has no driver's licence in the picker.
        forms.prefillIdDetails(SESSION_A, UseSmileIDSampleCountry.Ghana, UseSmileIDSampleIdType.DriversLicense)

        assertEquals(UseSmileIDSampleCountry.Ghana, forms.idDetails.country)
        assertNull(forms.idDetails.idType)
    }

    @Test
    fun `a relinked token corrects a seed the first one left behind`() {
        val forms = UseSmileIDSampleForms()
        forms.prefillIdDetails(SESSION_A, UseSmileIDSampleCountry.Kenya, UseSmileIDSampleIdType.Passport)
        forms.prefillIdDetails(SESSION_B, UseSmileIDSampleCountry.Ghana, UseSmileIDSampleIdType.VoterId)

        assertEquals("the form must not show one token while the run submits another", UseSmileIDSampleCountry.Ghana, forms.idDetails.country)
        assertEquals(UseSmileIDSampleIdType.VoterId, forms.idDetails.idType)
    }

    @Test
    fun `re-entering under the same session leaves the seed as it is`() {
        val forms = UseSmileIDSampleForms()
        forms.prefillIdDetails(SESSION_A, UseSmileIDSampleCountry.Kenya, UseSmileIDSampleIdType.Passport)
        forms.setIdNumber("A1234567")
        forms.prefillIdDetails(SESSION_A, UseSmileIDSampleCountry.Kenya, UseSmileIDSampleIdType.Passport)

        assertEquals("A1234567", forms.idDetails.idNumber)
        assertEquals(UseSmileIDSampleCountry.Kenya, forms.idDetails.country)
    }

    @Test
    fun `a seed does not outlive the session that justified it`() {
        val forms = UseSmileIDSampleForms()
        forms.prefillIdDetails(SESSION_A, UseSmileIDSampleCountry.Kenya, UseSmileIDSampleIdType.Passport)
        forms.prefillIdDetails(null, null, null)

        assertNull(forms.idDetails.country)
        assertNull(forms.idDetails.idType)
        assertNull(forms.seededFrom)
    }

    @Test
    fun `losing the session never discards a value the person typed or chose`() {
        val forms = UseSmileIDSampleForms()
        forms.setCountry(UseSmileIDSampleCountry.Ghana)
        forms.setIdNumber("GH-99")
        forms.prefillIdDetails(null, null, null)

        assertEquals(UseSmileIDSampleCountry.Ghana, forms.idDetails.country)
        assertEquals("GH-99", forms.idDetails.idNumber)
    }

    @Test
    fun `choosing a country makes it theirs, so a later token cannot replace it`() {
        val forms = UseSmileIDSampleForms()
        forms.prefillIdDetails(SESSION_A, UseSmileIDSampleCountry.Kenya, UseSmileIDSampleIdType.Passport)
        forms.setCountry(UseSmileIDSampleCountry.Uganda)
        forms.prefillIdDetails(SESSION_B, UseSmileIDSampleCountry.Ghana, UseSmileIDSampleIdType.VoterId)

        assertEquals(UseSmileIDSampleCountry.Uganda, forms.idDetails.country)
    }

    private fun bindings(country: String? = null, idType: String? = null) =
        UseSmileIDSampleTokenBindings(country = country, idType = idType)

    private companion object {
        // Session handles, which is what the form tracks — never the credential.
        const val SESSION_A = "9f3a2c71"
        const val SESSION_B = "0b17dd42"
    }
}
