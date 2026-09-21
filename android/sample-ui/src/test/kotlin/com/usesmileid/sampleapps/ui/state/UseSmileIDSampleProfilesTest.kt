package com.usesmileid.sampleapps.ui.state

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** A plain launch carries one empty profile; the design's three are fixtures reached only by `seedProfiles`. */
class UseSmileIDSampleProfilesTest {

    @Test
    fun a_launch_carries_the_fixtures_only_when_seedProfiles_asks() {
        assertEquals(
            UseSmileIDSampleProfiles.starter(),
            UseSmileIDSampleProfiles.forLaunch(UseSmileIDSampleLaunchArgs()).all.toList(),
        )
        assertEquals(
            UseSmileIDSampleProfiles.fixtures(),
            UseSmileIDSampleProfiles.forLaunch(UseSmileIDSampleLaunchArgs(seedProfiles = true)).all.toList(),
        )
    }

    @Test
    fun a_plain_launch_carries_one_profile_with_nothing_made_up() {
        val profiles = UseSmileIDSampleProfiles()
        val starter = profiles.all.single()

        assertEquals(starter.id, profiles.activeId)
        assertEquals(UseSmileIDSampleProfiles.STARTER_ORGANISATION, starter.organisation)
        assertTrue("a starter profile names nobody", starter.person.isBlank())
        assertEquals(UseSmileIDSampleUserDetails(), starter.defaults)
        // The consent screen shows this as the partner, so it must not collide with a fixture.
        assertTrue(UseSmileIDSampleProfiles.fixtures().none { it.organisation == starter.organisation })
    }

    @Test
    fun the_fixtures_are_the_designs_three_with_distinct_ids() {
        val fixtures = UseSmileIDSampleProfiles.fixtures()

        assertEquals(3, fixtures.size)
        assertEquals(3, fixtures.map { it.id }.toSet().size)
        assertEquals("p-1", UseSmileIDSampleProfiles(fixtures).activeId)
    }

    @Test
    fun a_profile_created_after_the_starter_takes_the_next_id_and_does_not_activate() {
        val profiles = UseSmileIDSampleProfiles()

        val created = profiles.add(organisation = "Karibu Pay", person = "Njeri Wanjiku")

        assertEquals("p-2", created.id)
        assertEquals(created.id, profiles.lastCreatedId)
        assertEquals("p-1", profiles.activeId)
    }

    @Test
    fun a_starter_profile_still_has_initials_for_the_avatar() {
        assertEquals("DP", UseSmileIDSampleProfiles().active.initials)
    }

    @Test
    fun saving_details_on_the_starter_names_it_and_a_created_profile_keeps_its_name() {
        val profiles = UseSmileIDSampleProfiles()
        assertEquals("No user details yet", profiles.active.caption)

        profiles.setDefaults("p-1", UseSmileIDSampleUserDetails(firstName = "Njeri", lastName = "Wanjiku"))
        assertEquals("Njeri Wanjiku", profiles.active.person)
        assertEquals("Njeri Wanjiku", profiles.active.caption)

        val created = profiles.add(organisation = "Karibu Pay", person = "Amani Otieno")
        profiles.setDefaults(created.id, UseSmileIDSampleUserDetails(firstName = "Someone", lastName = "Else"))
        assertEquals("Amani Otieno", profiles.find(created.id)?.person)
    }

    @Test
    fun saving_details_without_a_callback_url_leaves_the_saved_one_alone() {
        val profiles = UseSmileIDSampleProfiles()
        profiles.setDefaults("p-1", UseSmileIDSampleUserDetails(), callbackUrl = "https://partner.example/hook")

        profiles.setDefaults("p-1", UseSmileIDSampleUserDetails(firstName = "Njeri"))

        assertEquals("https://partner.example/hook", profiles.active.callbackUrl)
    }
}
