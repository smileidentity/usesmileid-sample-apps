package com.usesmileid.sampleapps.ui.state

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** A plain launch has no profile at all; the design's three are fixtures reached only by `seedProfiles`, and never stored. */
class UseSmileIDSampleProfilesTest {

    private val writes = mutableListOf<UseSmileIDSampleProfilesRecord>()

    private fun stored(record: UseSmileIDSampleProfilesRecord = UseSmileIDSampleProfilesRecord()) =
        UseSmileIDSampleProfiles(record, onChange = { writes += it })

    @Test
    fun a_plain_launch_has_no_profile_until_the_store_answers() {
        val profiles = UseSmileIDSampleProfiles.forLaunch(UseSmileIDSampleLaunchArgs()) { writes += it }

        assertFalse(profiles.loaded)
        profiles.restore(UseSmileIDSampleProfilesRecord())

        assertTrue(profiles.loaded)
        assertTrue(profiles.all.isEmpty())
        assertNull(profiles.active)
        assertEquals("Smile ID", profiles.partnerName)
        assertEquals("p-1", profiles.partnerId)
    }

    @Test
    fun a_seeded_launch_shows_the_fixtures_and_writes_nothing() {
        val profiles = UseSmileIDSampleProfiles.forLaunch(UseSmileIDSampleLaunchArgs(seedProfiles = true)) { writes += it }

        assertEquals(UseSmileIDSampleProfiles.fixtures(), profiles.all.toList())
        profiles.add("Karibu Pay")
        profiles.setActive("p-2")

        assertTrue("fixtures must never reach the store", writes.isEmpty())
    }

    @Test
    fun restoring_twice_keeps_the_first_answer() {
        val profiles = UseSmileIDSampleProfiles(loaded = false)
        profiles.restore(UseSmileIDSampleProfilesRecord(UseSmileIDSampleProfiles.fixtures()))
        profiles.restore(UseSmileIDSampleProfilesRecord())

        assertEquals(3, profiles.all.size)
    }

    @Test
    fun the_first_profile_becomes_active_and_later_ones_wait_for_the_offer() {
        val profiles = stored()

        val first = profiles.add("Karibu Pay")
        assertEquals(first.id, profiles.activeId)
        assertNull("the active one needs no Make active offer", profiles.lastCreatedId)

        val second = profiles.add("Sahara Pay")
        assertEquals(first.id, profiles.activeId)
        assertEquals(second.id, profiles.lastCreatedId)
        assertEquals(listOf("p-1", "p-2"), profiles.all.map { it.id })
    }

    @Test
    fun a_blank_organisation_names_the_app_on_consent_never_the_person() {
        val profiles = stored()
        profiles.add("", UseSmileIDSampleUserDetails(firstName = "Ada", lastName = "Okafor"))

        assertEquals("Ada Okafor", profiles.active?.title)
        assertEquals("Smile ID", profiles.partnerName)
    }

    @Test
    fun the_person_always_follows_the_details() {
        val profiles = stored()
        val created = profiles.add("Karibu Pay", UseSmileIDSampleUserDetails(firstName = "Njeri", lastName = "Wanjiku"))

        profiles.update(created.id, defaults = UseSmileIDSampleUserDetails(firstName = "Amani", lastName = "Otieno"))

        assertEquals("Amani Otieno", profiles.active?.person)
        assertEquals("AO", profiles.active?.initials)
    }

    @Test
    fun an_update_leaves_what_it_was_not_given() {
        val profiles = stored()
        val created = profiles.add("Karibu Pay")
        profiles.update(created.id, callbackUrl = " https://partner.example/hook ")

        profiles.update(created.id, defaults = UseSmileIDSampleUserDetails(firstName = "Njeri"))

        assertEquals("https://partner.example/hook", profiles.active?.callbackUrl)
        assertEquals("Karibu Pay", profiles.active?.organisation)
    }

    @Test
    fun deleting_the_active_profile_hands_over_to_the_first_left_then_to_none() {
        val profiles = stored(UseSmileIDSampleProfilesRecord(UseSmileIDSampleProfiles.fixtures(), activeId = "p-2"))

        profiles.delete("p-2")
        assertEquals("p-1", profiles.activeId)

        profiles.delete("p-1")
        profiles.delete("p-3")
        assertNull(profiles.activeId)
        assertEquals(UseSmileIDSampleProfilesRecord(), writes.last())
    }

    @Test
    fun sign_out_clears_every_profile_and_stores_that() {
        val profiles = stored(UseSmileIDSampleProfilesRecord(UseSmileIDSampleProfiles.fixtures()))

        profiles.clear()

        assertTrue(profiles.all.isEmpty())
        assertNull(profiles.active)
        assertEquals(UseSmileIDSampleProfilesRecord(), writes.single())
    }

    @Test
    fun every_change_is_stored_as_the_whole_record() {
        val profiles = stored()
        profiles.add("Karibu Pay")
        profiles.add("Sahara Pay")
        profiles.setActive("p-2")

        assertEquals(3, writes.size)
        assertEquals(UseSmileIDSampleProfilesRecord(profiles.all.toList(), "p-2"), writes.last())
    }

    @Test
    fun a_change_before_the_store_answers_writes_nothing_over_it() {
        val profiles = UseSmileIDSampleProfiles(loaded = false, onChange = { writes += it })
        profiles.add("Early")

        profiles.restore(UseSmileIDSampleProfilesRecord(UseSmileIDSampleProfiles.fixtures()))

        assertTrue("a partial list must not reach the store", writes.isEmpty())
        assertEquals(3, profiles.all.size)
    }

    @Test
    fun a_sign_out_before_the_store_answers_still_deletes_every_profile() {
        val profiles = UseSmileIDSampleProfiles(loaded = false, onChange = { writes += it })
        profiles.clear()

        profiles.restore(UseSmileIDSampleProfilesRecord(UseSmileIDSampleProfiles.fixtures()))

        assertTrue(profiles.all.isEmpty())
        assertEquals(UseSmileIDSampleProfilesRecord(), writes.single())
    }

    @Test
    fun a_stored_active_id_that_names_no_profile_falls_back_to_the_first() {
        val profiles = stored(UseSmileIDSampleProfilesRecord(UseSmileIDSampleProfiles.fixtures(), activeId = "p-9"))

        assertEquals("p-1", profiles.activeId)
    }
}
