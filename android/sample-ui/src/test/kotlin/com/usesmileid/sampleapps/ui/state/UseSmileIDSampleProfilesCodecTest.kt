package com.usesmileid.sampleapps.ui.state

import org.junit.Assert.assertEquals
import org.junit.Test

class UseSmileIDSampleProfilesCodecTest {

    @Test
    fun a_record_round_trips_including_characters_json_escapes() {
        val record = UseSmileIDSampleProfilesRecord(
            profiles = listOf(
                UseSmileIDSampleProfile(
                    id = "p-1",
                    organisation = "Kobo \"Bank\" \\ Ltd\n",
                    defaults = UseSmileIDSampleUserDetails("Adá", "O'Neil", "ada@kobo.example", "+254 700 000 000"),
                    callbackUrl = "https://kobo.example/hook?a=1&b=2",
                ),
                UseSmileIDSampleProfile(id = "p-2", organisation = ""),
            ),
            activeId = "p-2",
        )

        assertEquals(record, UseSmileIDSampleProfilesCodec.decode(UseSmileIDSampleProfilesCodec.encode(record)))
    }

    @Test
    fun no_profiles_round_trips_with_a_null_active_id() {
        val none = UseSmileIDSampleProfilesRecord()

        assertEquals(none, UseSmileIDSampleProfilesCodec.decode(UseSmileIDSampleProfilesCodec.encode(none)))
    }

    @Test
    fun unreadable_input_is_no_profiles() {
        listOf(
            null,
            "",
            "not json",
            "[]",
            "{\"profiles\":[{\"id\":\"p-1\"}]}",
            "{\"version\":2,\"profiles\":[{\"id\":\"p-1\"}]}",
            "{\"version\":1,\"profiles\":\"p-1\"}",
            "{\"version\":1,\"profiles\":[{\"id\":\"p-1\",\"organisation\":\"Kobo\"",
        ).forEach { text ->
            assertEquals(text.toString(), emptyList<UseSmileIDSampleProfile>(), UseSmileIDSampleProfilesCodec.decode(text).profiles)
        }
    }

    @Test
    fun a_profile_without_an_id_or_with_a_repeated_one_is_dropped() {
        val decoded = UseSmileIDSampleProfilesCodec.decode(
            "{\"version\":1,\"activeId\":\"p-1\",\"profiles\":[{\"organisation\":\"No id\"},{\"id\":\"p-1\",\"organisation\":\"First\"},{\"id\":\"p-1\",\"organisation\":\"Again\"}]}",
        )

        assertEquals(listOf("First"), decoded.profiles.map { it.organisation })
    }

    @Test
    fun the_shape_is_the_one_all_four_apps_read() {
        val record = UseSmileIDSampleProfilesRecord(listOf(UseSmileIDSampleProfile(id = "p-1", organisation = "Kobo")))

        assertEquals(
            "{\"version\":1,\"activeId\":\"p-1\",\"profiles\":[{\"id\":\"p-1\",\"organisation\":\"Kobo\",\"firstName\":\"\"," +
                "\"lastName\":\"\",\"email\":\"\",\"phone\":\"\",\"callbackUrl\":\"\"}]}",
            UseSmileIDSampleProfilesCodec.encode(record),
        )
    }
}
