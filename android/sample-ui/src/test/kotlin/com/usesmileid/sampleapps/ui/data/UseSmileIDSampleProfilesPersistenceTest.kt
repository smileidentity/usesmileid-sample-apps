package com.usesmileid.sampleapps.ui.data

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import com.usesmileid.sampleapps.ui.golden.ROBOLECTRIC_SDK
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleProfile
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleProfilesRecord
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import java.io.File
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** Profiles survive a restart, and an install updated from a build that never stored them reads as a first launch. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [ROBOLECTRIC_SDK])
class UseSmileIDSampleProfilesPersistenceTest {

    private lateinit var file: File
    private lateinit var prefs: DataStore<Preferences>

    /** Robolectric has no Android Keystore, so a reversible stand-in seals here; the device run proves the real one. */
    private val cipher = object : UseSmileIDSampleProfilesCipher {
        override fun seal(plain: String) = "sealed:" + plain.reversed()
        override fun open(sealed: String) = sealed.removePrefix("sealed:").takeIf { it != sealed }?.reversed()
    }

    private fun store() = UseSmileIDSampleStore(prefs, cipher)

    @Before
    fun setUp() {
        file = File.createTempFile("profiles", ".preferences_pb").also { it.delete() }
        prefs = PreferenceDataStoreFactory.create { file }
    }

    @After
    fun tearDown() {
        file.delete()
    }

    @Test
    fun profiles_written_by_one_store_are_read_by_the_next() = runTest {
        val record = UseSmileIDSampleProfilesRecord(
            listOf(UseSmileIDSampleProfile(id = "p-1", organisation = "Kobo Bank", callbackUrl = "https://kobo.example/hook")),
        )

        store().setProfiles(record)

        assertEquals(record, store().profiles.first())
    }

    @Test
    fun a_store_holding_only_the_released_keys_reads_as_no_profiles_with_its_settings_intact() = runTest {
        prefs.edit {
            it[booleanPreferencesKey("dark_mode")] = true
            it[stringPreferencesKey("ended_session_id")] = "session-1"
        }
        val store = store()

        assertTrue(store.profiles.first().profiles.isEmpty())
        assertTrue(store.settings.first().darkMode)
        assertEquals("session-1", store.session.first().ended?.id)
    }

    @Test
    fun what_is_stored_is_sealed_never_the_details_in_plain_text() = runTest {
        store().setProfiles(
            UseSmileIDSampleProfilesRecord(
                listOf(
                    UseSmileIDSampleProfile(
                        id = "p-1",
                        organisation = "Kobo Bank",
                        defaults = UseSmileIDSampleUserDetails(email = "ada@kobo.example"),
                    ),
                ),
            ),
        )

        val raw = prefs.data.first()[stringPreferencesKey("sample_profiles")].orEmpty()
        assertTrue(raw.startsWith("sealed:"))
        assertTrue("an email reached the store in plain text", "ada@kobo.example" !in raw)
    }

    @Test
    fun a_record_this_key_cannot_open_reads_as_no_profiles() = runTest {
        prefs.edit { it[stringPreferencesKey("sample_profiles")] = "sealed-by-another-key" }

        assertEquals(UseSmileIDSampleProfilesRecord(), store().profiles.first())
    }

    @Test
    fun a_plain_record_from_before_sealing_still_reads() = runTest {
        prefs.edit {
            it[stringPreferencesKey("sample_profiles")] =
                "{\"version\":1,\"activeId\":\"p-1\",\"profiles\":[{\"id\":\"p-1\",\"organisation\":\"Kobo\"}]}"
        }

        assertEquals("Kobo", store().profiles.first().profiles.single().organisation)
    }

    @Test
    fun an_unreadable_record_reads_as_no_profiles() = runTest {
        prefs.edit { it[stringPreferencesKey("sample_profiles")] = "{\"version\":1,\"profiles\":[" }

        assertEquals(UseSmileIDSampleProfilesRecord(), store().profiles.first())
    }
}
