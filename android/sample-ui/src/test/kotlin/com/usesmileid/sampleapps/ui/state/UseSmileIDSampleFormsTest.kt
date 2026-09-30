package com.usesmileid.sampleapps.ui.state

import androidx.compose.runtime.saveable.SaverScope
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class UseSmileIDSampleFormsTest {

    private val ada = UseSmileIDSampleUserDetails(firstName = "Ada", lastName = "Okafor", email = "ada@kobo.example")

    private fun typed(details: UseSmileIDSampleUserDetails, organisation: String = "") = UseSmileIDSampleForms().apply {
        UseSmileIDSampleUserField.entries.forEach { setUserField(it, it.read(details)) }
        organisation(organisation)
    }

    @Test
    fun the_first_run_creates_an_active_profile_from_what_was_typed() {
        val profiles = UseSmileIDSampleProfiles()

        profiles.keep(typed(ada, organisation = " Kobo Bank "))

        assertEquals("Kobo Bank", profiles.active?.organisation)
        assertEquals(ada, profiles.active?.defaults)
    }

    @Test
    fun an_active_profile_takes_the_edits() {
        val profiles = UseSmileIDSampleProfiles(UseSmileIDSampleProfilesRecord(UseSmileIDSampleProfiles.fixtures()))

        profiles.keep(typed(ada))

        assertEquals(ada, profiles.find("p-1")?.defaults)
        assertEquals("UpTech Finance", profiles.find("p-1")?.organisation)
        assertEquals(3, profiles.all.size)
    }

    @Test
    fun the_switch_off_keeps_nothing() {
        val profiles = UseSmileIDSampleProfiles()
        val forms = typed(ada).apply { saveToProfile(false) }

        profiles.keep(forms)

        assertTrue(profiles.all.isEmpty())
    }

    @Test
    fun a_field_the_token_supplies_is_never_stored() {
        val stored = UseSmileIDSampleUserDetails(firstName = "Kwame", lastName = "Asante")
        val profiles = UseSmileIDSampleProfiles(
            UseSmileIDSampleProfilesRecord(listOf(UseSmileIDSampleProfile(id = "p-1", organisation = "UpTech", defaults = stored))),
        )
        val namesBound = UseSmileIDSampleTokenBindings(givenNames = true, lastName = true).userDetailsRequirement()

        profiles.keep(typed(ada.copy(firstName = "", lastName = "")), namesBound)

        assertEquals(stored.copy(email = "ada@kobo.example"), profiles.active?.defaults)
    }

    @Test
    fun filling_from_a_profile_drops_what_was_typed_and_turns_the_switch_back_on() {
        val forms = typed(ada, organisation = "Kobo").apply { saveToProfile(false) }
        val kwame = UseSmileIDSampleProfiles.fixtures().first()

        forms.fillFrom(kwame)

        assertEquals(kwame.defaults, forms.userDetails)
        assertEquals("", forms.organisation)
        assertTrue(forms.saveToProfile)
    }

    @Test
    fun a_new_run_never_carries_the_last_runs_id_details() {
        val forms = typed(ada).apply {
            setCountry(UseSmileIDSampleCountry("KE", "Kenya"))
            setIdType(UseSmileIDSampleKycIdType("NATIONAL_ID", "NATIONAL_ID", "National ID", "^[0-9]{1,9}$"))
            setIdNumber("12345678")
        }

        forms.startRun(null)

        assertEquals(UseSmileIDSampleIdDetails(), forms.idDetails)
        assertEquals(ada, forms.userDetails)
    }

    @Test
    fun the_capture_as_override_survives_the_saver_and_an_unknown_value_restores_as_match() {
        val scope = SaverScope { true }
        val chosen = UseSmileIDSampleForms().apply { setCaptureAs(UseSmileIDSampleCaptureAs.Passport) }
        val saved = with(UseSmileIDSampleForms.Saver) { scope.save(chosen) } as List<*>
        assertEquals(UseSmileIDSampleCaptureAs.Passport, UseSmileIDSampleForms.Saver.restore(saved)?.idDetails?.captureAsOverride)
        val renamed = saved.map { value -> if (value == UseSmileIDSampleCaptureAs.Passport.name) "Retired" else value }
        assertEquals(null, UseSmileIDSampleForms.Saver.restore(renamed)?.idDetails?.captureAsOverride)
        val match = with(UseSmileIDSampleForms.Saver) { scope.save(UseSmileIDSampleForms()) } as List<*>
        assertEquals(null, UseSmileIDSampleForms.Saver.restore(match)?.idDetails?.captureAsOverride)
    }

    @Test
    fun a_row_the_product_does_not_list_is_dropped_with_its_override() {
        val greenBook = UseSmileIDSampleDocument(
            code = "IDENTITY_CARD",
            subType = GREEN_BOOK_SUB_TYPE,
            name = "Green Book",
            hasBack = false,
            format = 7,
        )
        val forms = UseSmileIDSampleForms().apply {
            setCountry(UseSmileIDSampleCountry("ZA", "South Africa"))
            setDocument(greenBook)
            setCaptureAs(UseSmileIDSampleCaptureAs.Passport)
        }
        forms.keepDocumentListedOn(UseSmileIDSampleProduct.DocumentVerification)
        assertEquals(greenBook, forms.idDetails.document)
        forms.keepDocumentListedOn(UseSmileIDSampleProduct.EnhancedDocumentVerification)
        assertEquals(null, forms.idDetails.document)
        assertEquals(null, forms.idDetails.captureAsOverride)
    }

    private val kenya = UseSmileIDSampleCountry("KE", "Kenya")
    private val passport = UseSmileIDSampleDocument(code = "PASSPORT", name = "Passport", hasBack = false, format = 3)

    private fun picked() = UseSmileIDSampleForms().apply {
        setCountry(kenya)
        setDocument(passport)
    }

    @Test
    fun a_relinked_partner_that_lacks_the_country_drops_every_pick() {
        val forms = picked()
        forms.keepOnlyEnabled(listOf(UseSmileIDSampleCountry("NG", "Nigeria")), null)
        assertEquals(null, forms.idDetails.country)
        assertEquals(null, forms.idDetails.document)
    }

    @Test
    fun a_relinked_partner_that_lacks_only_the_document_keeps_the_country() {
        val forms = picked()
        forms.keepOnlyEnabled(listOf(kenya), listOf(UseSmileIDSampleDocument(code = "NATIONAL_ID", name = "National ID", hasBack = true, format = 1)))
        assertEquals(kenya, forms.idDetails.country)
        assertEquals(null, forms.idDetails.document)
    }

    @Test
    fun a_list_still_loading_keeps_the_picks() {
        val forms = picked()
        forms.keepOnlyEnabled(null, null)
        assertEquals(kenya, forms.idDetails.country)
        assertEquals(passport, forms.idDetails.document)
    }
}
