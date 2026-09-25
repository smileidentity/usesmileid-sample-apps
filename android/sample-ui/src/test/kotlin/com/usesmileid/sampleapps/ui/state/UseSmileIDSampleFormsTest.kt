package com.usesmileid.sampleapps.ui.state

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Continue keeps the typed details in the active profile, or makes one; the switch off keeps nothing. */
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
            setCountry(UseSmileIDSampleCountry.entries.first())
            setIdType(UseSmileIDSampleIdType.NationalId)
            setIdNumber("12345678")
        }

        forms.startRun(null)

        assertEquals(UseSmileIDSampleIdDetails(), forms.idDetails)
        assertEquals(ada, forms.userDetails)
    }
}
