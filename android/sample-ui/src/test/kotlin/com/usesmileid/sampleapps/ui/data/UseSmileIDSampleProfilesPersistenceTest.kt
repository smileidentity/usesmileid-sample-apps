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

        UseSmileIDSampleStore(prefs).setProfiles(record)

        assertEquals(record, UseSmileIDSampleStore(prefs).profiles.first())
    }

    @Test
    fun a_store_holding_only_the_released_keys_reads_as_no_profiles_with_its_settings_intact() = runTest {
        prefs.edit {
            it[booleanPreferencesKey("dark_mode")] = true
            it[stringPreferencesKey("ended_session_id")] = "session-1"
        }
        val store = UseSmileIDSampleStore(prefs)

        assertTrue(store.profiles.first().profiles.isEmpty())
        assertTrue(store.settings.first().darkMode)
        assertEquals("session-1", store.session.first().ended?.id)
    }

    @Test
    fun an_unreadable_record_reads_as_no_profiles() = runTest {
        prefs.edit { it[stringPreferencesKey("sample_profiles")] = "{\"version\":1,\"profiles\":[" }

        assertEquals(UseSmileIDSampleProfilesRecord(), UseSmileIDSampleStore(prefs).profiles.first())
    }
}
