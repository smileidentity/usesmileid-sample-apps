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
    fun `a device carrying the retired key has it removed`() = runTest {
        val stored = mutablePreferencesOf(PRODUCTION to true)
        assertTrue(UseSmileIDSampleRetiredSettingKeys.shouldMigrate(stored))

        val migrated = UseSmileIDSampleRetiredSettingKeys.migrate(stored)
        assertFalse(PRODUCTION in migrated)
    }

    @Test
    fun `once cleared it never runs again`() = runTest {
        val migrated = UseSmileIDSampleRetiredSettingKeys.migrate(mutablePreferencesOf(PRODUCTION to true))
        assertFalse(UseSmileIDSampleRetiredSettingKeys.shouldMigrate(migrated))
    }

    @Test
    fun `a store that never had the key is untouched`() = runTest {
        assertFalse(UseSmileIDSampleRetiredSettingKeys.shouldMigrate(emptyPreferences()))
    }

    @Test
    fun `every other setting survives the clear`() = runTest {
        val stored = mutablePreferencesOf(PRODUCTION to true, DARK_MODE to true, CONSENT_STEP to false)
        val migrated = UseSmileIDSampleRetiredSettingKeys.migrate(stored)
        assertEquals(true, migrated[DARK_MODE])
        assertEquals(false, migrated[CONSENT_STEP])
    }

    private companion object {
        val PRODUCTION = booleanPreferencesKey("production")
        val DARK_MODE = booleanPreferencesKey("dark_mode")
        val CONSENT_STEP = booleanPreferencesKey("consent_step")
    }
}
