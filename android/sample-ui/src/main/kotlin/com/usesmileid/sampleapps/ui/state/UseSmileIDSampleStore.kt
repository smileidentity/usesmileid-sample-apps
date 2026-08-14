package com.usesmileid.sampleapps.ui.state

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

/** Everything the sample persists: the settings the SDK flow is composed from, and the token session. */
class UseSmileIDSampleStore(private val store: DataStore<Preferences>) {

    constructor(context: Context) : this(context.applicationContext.sampleStore)

    val settings: Flow<UseSmileIDSampleSettings> = store.data.map { prefs ->
        val defaults = UseSmileIDSampleSettings()
        UseSmileIDSampleSettings(
            smileToCapture = prefs[SMILE_TO_CAPTURE] ?: defaults.smileToCapture,
            agentMode = prefs[AGENT_MODE] ?: defaults.agentMode,
            darkMode = prefs[DARK_MODE] ?: defaults.darkMode,
            consentStep = prefs[CONSENT_STEP] ?: defaults.consentStep,
            instructionsStep = prefs[INSTRUCTIONS_STEP] ?: defaults.instructionsStep,
            previewStep = prefs[PREVIEW_STEP] ?: defaults.previewStep,
        )
    }

    val tokenSession: Flow<UseSmileIDSampleTokenSession?> = store.data.map { prefs ->
        val id = prefs[SESSION_ID]
        val expiresAt = prefs[SESSION_EXPIRES_AT]
        if (id == null || expiresAt == null) null else UseSmileIDSampleTokenSession(id, expiresAt)
    }

    suspend fun setSetting(setting: UseSmileIDSampleSetting, enabled: Boolean) {
        store.edit { prefs -> prefs[setting.key()] = enabled }
    }

    /** Stores the deadline the caller computed, so restoration never re-derives a shorter session. */
    suspend fun linkTokenSession(id: String, expiresAtMillis: Long) {
        store.edit { prefs ->
            prefs[SESSION_ID] = id
            prefs[SESSION_EXPIRES_AT] = expiresAtMillis
        }
    }

    suspend fun clearTokenSession() {
        store.edit { prefs ->
            prefs.remove(SESSION_ID)
            prefs.remove(SESSION_EXPIRES_AT)
        }
    }

    private fun UseSmileIDSampleSetting.key(): Preferences.Key<Boolean> = when (this) {
        UseSmileIDSampleSetting.SmileToCapture -> SMILE_TO_CAPTURE
        UseSmileIDSampleSetting.AgentMode -> AGENT_MODE
        UseSmileIDSampleSetting.DarkMode -> DARK_MODE
        UseSmileIDSampleSetting.ConsentStep -> CONSENT_STEP
        UseSmileIDSampleSetting.InstructionsStep -> INSTRUCTIONS_STEP
        UseSmileIDSampleSetting.PreviewStep -> PREVIEW_STEP
    }

    private companion object {
        val SMILE_TO_CAPTURE = booleanPreferencesKey("smile_to_capture")
        val AGENT_MODE = booleanPreferencesKey("agent_mode")
        val DARK_MODE = booleanPreferencesKey("dark_mode")
        val CONSENT_STEP = booleanPreferencesKey("consent_step")
        val INSTRUCTIONS_STEP = booleanPreferencesKey("instructions_step")
        val PREVIEW_STEP = booleanPreferencesKey("preview_step")
        val SESSION_ID = stringPreferencesKey("token_session_id")
        val SESSION_EXPIRES_AT = longPreferencesKey("token_session_expires_at")
    }
}

// Not an application id, so it stays identity-agnostic and the same across all eight hosts.
private val Context.sampleStore by preferencesDataStore(name = "usesmileid_sample")
