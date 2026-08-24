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
    fun `an id type the country does not offer is dropped rather than seeded`() {
        // Ghana has no driver's licence in the picker, so a token naming one must not seed it.
        assertNull(bindings(country = "GH", idType = "DRIVERS_LICENSE").prefilledIdType)
        assertEquals(
            UseSmileIDSampleIdType.DriversLicense,
            bindings(country = "NG", idType = "DRIVERS_LICENSE").prefilledIdType,
        )
    }

    @Test
    fun `an id type without a resolvable country is dropped, because the form could not offer it`() {
        assertNull(bindings(country = null, idType = "PASSPORT").prefilledIdType)
        assertNull(bindings(country = "US", idType = "PASSPORT").prefilledIdType)
    }

    @Test
    fun `prefill seeds an untouched form and never the id number`() {
        val forms = UseSmileIDSampleForms()
        forms.prefillIdDetails(UseSmileIDSampleCountry.Kenya, UseSmileIDSampleIdType.Passport)

        assertEquals(UseSmileIDSampleCountry.Kenya, forms.idDetails.country)
        assertEquals(UseSmileIDSampleIdType.Passport, forms.idDetails.idType)
        assertEquals("the token carries a vault reference, never a number", "", forms.idDetails.idNumber)
    }

    @Test
    fun `prefill leaves a country the person already chose alone`() {
        val forms = UseSmileIDSampleForms()
        forms.setCountry(UseSmileIDSampleCountry.Ghana)
        forms.prefillIdDetails(UseSmileIDSampleCountry.Kenya, UseSmileIDSampleIdType.Passport)

        assertEquals(UseSmileIDSampleCountry.Ghana, forms.idDetails.country)
        assertNull("seeding must not smuggle a type onto their own country", forms.idDetails.idType)
    }

    @Test
    fun `prefill without a country changes nothing, since the type trigger stays disabled`() {
        val forms = UseSmileIDSampleForms()
        forms.prefillIdDetails(null, UseSmileIDSampleIdType.Passport)

        assertNull(forms.idDetails.country)
        assertNull(forms.idDetails.idType)
    }

    @Test
    fun `a mismatched type still seeds the country it did resolve`() {
        val forms = UseSmileIDSampleForms()
        forms.prefillIdDetails(UseSmileIDSampleCountry.Ghana, UseSmileIDSampleIdType.DriversLicense)

        assertEquals(UseSmileIDSampleCountry.Ghana, forms.idDetails.country)
        assertNull(forms.idDetails.idType)
    }

    private fun bindings(country: String? = null, idType: String? = null) =
        UseSmileIDSampleTokenBindings(country = country, idType = idType)
}
