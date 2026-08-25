package com.usesmileid.sampleapps.ui.data

import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.mutablePreferencesOf
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class UseSmileIDSampleRetiredSettingKeysTest {

    @Test
    fun `a device carrying either retired key has it removed`() = runTest {
        listOf(PRODUCTION, SMILE_TO_CAPTURE).forEach { retired ->
            val stored = mutablePreferencesOf(retired to true)
            assertTrue("$retired should migrate", UseSmileIDSampleRetiredSettingKeys.shouldMigrate(stored))

            val migrated = UseSmileIDSampleRetiredSettingKeys.migrate(stored)
            assertFalse(retired in migrated)
        }
    }

    @Test
    fun `once cleared it never runs again`() = runTest {
        val stored = mutablePreferencesOf(PRODUCTION to true, SMILE_TO_CAPTURE to true)
        val migrated = UseSmileIDSampleRetiredSettingKeys.migrate(stored)
        assertFalse(UseSmileIDSampleRetiredSettingKeys.shouldMigrate(migrated))
    }

    /**
     * The value is not reinterpreted: `smile_to_capture = true` meant enhanced liveness OFF, and the
     * new key means the opposite, so the old one is dropped rather than read under its new name.
     */
    @Test
    fun `the retired capture key does not become the new one`() = runTest {
        val migrated = UseSmileIDSampleRetiredSettingKeys.migrate(mutablePreferencesOf(SMILE_TO_CAPTURE to true))
        assertFalse(SMILE_TO_CAPTURE in migrated)
        assertFalse(ENHANCED_SMART_SELFIE in migrated)
    }

    @Test
    fun `a store that never had the key is untouched`() = runTest {
        assertFalse(UseSmileIDSampleRetiredSettingKeys.shouldMigrate(emptyPreferences()))
    }

    @Test
    fun `every other setting survives the clear`() = runTest {
        val stored = mutablePreferencesOf(
            PRODUCTION to true,
            SMILE_TO_CAPTURE to true,
            DARK_MODE to true,
            CONSENT_STEP to false,
        )
        val migrated = UseSmileIDSampleRetiredSettingKeys.migrate(stored)
        assertEquals(true, migrated[DARK_MODE])
        assertEquals(false, migrated[CONSENT_STEP])
    }

    private companion object {
        val PRODUCTION = booleanPreferencesKey("production")
        val SMILE_TO_CAPTURE = booleanPreferencesKey("smile_to_capture")
        val ENHANCED_SMART_SELFIE = booleanPreferencesKey("enhanced_smart_selfie")
        val DARK_MODE = booleanPreferencesKey("dark_mode")
        val CONSENT_STEP = booleanPreferencesKey("consent_step")
    }
}
