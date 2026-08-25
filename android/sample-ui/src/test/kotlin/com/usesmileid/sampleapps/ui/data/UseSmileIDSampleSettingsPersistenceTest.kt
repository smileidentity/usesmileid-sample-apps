package com.usesmileid.sampleapps.ui.data

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import com.usesmileid.sampleapps.ui.golden.ROBOLECTRIC_SDK
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleSetting
import java.io.File
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [ROBOLECTRIC_SDK])
class UseSmileIDSampleSettingsPersistenceTest {

    private lateinit var file: File
    private lateinit var prefs: DataStore<Preferences>
    private lateinit var store: UseSmileIDSampleStore

    @Before
    fun setUp() {
        file = File.createTempFile("settings", ".preferences_pb").also { it.delete() }
        prefs = PreferenceDataStoreFactory.create { file }
        store = UseSmileIDSampleStore(prefs)
    }

    @After
    fun tearDown() {
        file.delete()
    }

    @Test
    fun `the mutex writes both rows, not just the one that was tapped`() = runTest {
        store.setSetting(UseSmileIDSampleSetting.AgentMode, true)

        val settings = store.settings.first()
        assertTrue(settings.agentMode)
        assertFalse("agent mode must take enhanced liveness with it", settings.enhancedSmartSelfie)
        assertEquals(false, prefs.data.first()[ENHANCED_SMART_SELFIE])
    }

    @Test
    fun `a row that did not move is never written`() = runTest {
        store.setSetting(UseSmileIDSampleSetting.ConsentStep, false)

        val written = prefs.data.first()
        assertEquals(false, written[CONSENT_STEP])
        // Writing all six would freeze today's defaults onto the device.
        assertNull(written[PREVIEW_STEP])
        assertNull(written[AGENT_MODE])
    }

    @Test
    fun `setting a row to the value it already holds writes nothing`() = runTest {
        store.setSetting(UseSmileIDSampleSetting.PreviewStep, true)

        assertNull(prefs.data.first()[PREVIEW_STEP])
    }

    /** Preferences predate the mutex, so a stored pair has to be corrected on read. */
    @Test
    fun `a stored pair the SDK refuses is normalised on read`() = runTest {
        prefs.edit {
            it[AGENT_MODE] = true
            it[ENHANCED_SMART_SELFIE] = true
        }

        val settings = store.settings.first()
        assertTrue(settings.agentMode)
        assertFalse(settings.enhancedSmartSelfie)
    }

    private companion object {
        val ENHANCED_SMART_SELFIE = booleanPreferencesKey("enhanced_smart_selfie")
        val AGENT_MODE = booleanPreferencesKey("agent_mode")
        val CONSENT_STEP = booleanPreferencesKey("consent_step")
        val PREVIEW_STEP = booleanPreferencesKey("preview_step")
    }
}
