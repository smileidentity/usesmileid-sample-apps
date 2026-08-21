package com.usesmileid.sampleapps.ui.state

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
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
            production = prefs[PRODUCTION] ?: defaults.production,
            smileToCapture = prefs[SMILE_TO_CAPTURE] ?: defaults.smileToCapture,
            agentMode = prefs[AGENT_MODE] ?: defaults.agentMode,
            darkMode = prefs[DARK_MODE] ?: defaults.darkMode,
            consentStep = prefs[CONSENT_STEP] ?: defaults.consentStep,
            instructionsStep = prefs[INSTRUCTIONS_STEP] ?: defaults.instructionsStep,
            previewStep = prefs[PREVIEW_STEP] ?: defaults.previewStep,
        )
    }

    /**
     * The token is the whole record: the handle, the deadline and the bindings all decode from it, so
     * storing them alongside it would only create copies that can disagree with it. A stored token
     * that no longer decodes reads as no session rather than a degraded one.
     *
     * Unencrypted, deliberately: the token is short-lived and sandbox-scoped, and losing the session
     * on every process death the camera can cause would make the feature unusable.
     */
    val tokenSession: Flow<UseSmileIDSampleTokenSession?> = store.data.map { prefs ->
        prefs[SESSION_TOKEN]?.let(UseSmileIDSampleTokenDecoder::session)
    }

    suspend fun setSetting(setting: UseSmileIDSampleSetting, enabled: Boolean) {
        store.edit { prefs -> prefs[setting.key()] = enabled }
    }

    /** Takes the session rather than the raw token, so only a decoded one can ever be linked. */
    suspend fun linkTokenSession(session: UseSmileIDSampleTokenSession) {
        store.edit { prefs -> prefs[SESSION_TOKEN] = session.token }
    }

    suspend fun clearTokenSession() {
        store.edit { prefs -> prefs.remove(SESSION_TOKEN) }
    }

    private fun UseSmileIDSampleSetting.key(): Preferences.Key<Boolean> = when (this) {
        UseSmileIDSampleSetting.Production -> PRODUCTION
        UseSmileIDSampleSetting.SmileToCapture -> SMILE_TO_CAPTURE
        UseSmileIDSampleSetting.AgentMode -> AGENT_MODE
        UseSmileIDSampleSetting.DarkMode -> DARK_MODE
        UseSmileIDSampleSetting.ConsentStep -> CONSENT_STEP
        UseSmileIDSampleSetting.InstructionsStep -> INSTRUCTIONS_STEP
        UseSmileIDSampleSetting.PreviewStep -> PREVIEW_STEP
    }

    private companion object {
        val PRODUCTION = booleanPreferencesKey("production")
        val SMILE_TO_CAPTURE = booleanPreferencesKey("smile_to_capture")
        val AGENT_MODE = booleanPreferencesKey("agent_mode")
        val DARK_MODE = booleanPreferencesKey("dark_mode")
        val CONSENT_STEP = booleanPreferencesKey("consent_step")
        val INSTRUCTIONS_STEP = booleanPreferencesKey("instructions_step")
        val PREVIEW_STEP = booleanPreferencesKey("preview_step")
        val SESSION_TOKEN = stringPreferencesKey("token_session_token")
    }
}

// Not an application id, so it stays identity-agnostic and the same across all eight hosts.
private val Context.sampleStore by preferencesDataStore(name = "usesmileid_sample")
