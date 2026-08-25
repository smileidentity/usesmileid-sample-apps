package com.usesmileid.sampleapps.ui.data

import android.content.Context
import androidx.datastore.core.DataMigration
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleSetting
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleSettings
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenDecoder
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

/** Everything the sample persists: the settings the SDK flow is composed from, and the token session. */
class UseSmileIDSampleStore(private val store: DataStore<Preferences>) {

    constructor(context: Context) : this(context.applicationContext.sampleStore)

    val settings: Flow<UseSmileIDSampleSettings> = store.data.map(::settingsIn)

    /**
     * The token is the whole record: the handle, the deadline and the bindings all decode from it, so
     * storing them alongside it would only create copies that can disagree with it. A stored token
     * that no longer decodes reads as no session rather than a degraded one.
     *
     * Unencrypted, deliberately: the token is short-lived and sandbox-scoped, and losing the session
     * on every process death the camera can cause would make the feature unusable.
     *
     * Both halves come from one emission: two collectors let the UI hold the token from one write and
     * the marker from the next, a pair impossible on disk.
     */
    val session: Flow<UseSmileIDSampleSessionRecord> = store.data.map { prefs ->
        UseSmileIDSampleSessionRecord(
            live = prefs[SESSION_TOKEN]?.let(UseSmileIDSampleTokenDecoder::session),
            ended = prefs[ENDED_SESSION_ID]?.let { id ->
                UseSmileIDSampleEndedSession(id = id, endedAtMillis = prefs[ENDED_SESSION_AT] ?: 0L)
            },
        )
    }

    /** Writes through the settings model, so the capture mutex can move the other row in the same edit. */
    suspend fun setSetting(setting: UseSmileIDSampleSetting, enabled: Boolean) {
        store.edit { prefs ->
            val current = settingsIn(prefs)
            val updated = current.withSetting(setting, enabled)
            // Only what moved: writing all six would freeze today's defaults onto the device.
            UseSmileIDSampleSetting.entries
                .filter { updated[it] != current[it] }
                .forEach { prefs[it.key()] = updated[it] }
        }
    }

    /** Takes the session rather than the raw token, so only a decoded one can ever be linked. */
    suspend fun linkTokenSession(session: UseSmileIDSampleTokenSession) {
        store.edit { prefs ->
            prefs[SESSION_TOKEN] = session.token
            // A new session is not an ended one.
            prefs.remove(ENDED_SESSION_ID)
            prefs.remove(ENDED_SESSION_AT)
        }
    }

    /**
     * Sign out: the session goes without leaving the ended marker behind, because a marker sends the
     * next run to the scanner — which is the right answer for a lapse and the wrong one for signing out.
     */
    suspend fun clearTokenSession() {
        store.edit { prefs ->
            prefs.remove(SESSION_TOKEN)
            prefs.remove(ENDED_SESSION_ID)
            prefs.remove(ENDED_SESSION_AT)
        }
    }

    /** Deletes the credential at its deadline, keeping only that the session ended. */
    suspend fun retireTokenSession(session: UseSmileIDSampleTokenSession) {
        store.edit { prefs ->
            prefs.remove(SESSION_TOKEN)
            prefs[ENDED_SESSION_ID] = session.id
            prefs[ENDED_SESSION_AT] = session.expiresAtMillis
        }
    }

    private fun settingsIn(prefs: Preferences): UseSmileIDSampleSettings {
        val defaults = UseSmileIDSampleSettings()
        return UseSmileIDSampleSettings(
            enhancedSmartSelfie = prefs[ENHANCED_SMART_SELFIE] ?: defaults.enhancedSmartSelfie,
            agentMode = prefs[AGENT_MODE] ?: defaults.agentMode,
            darkMode = prefs[DARK_MODE] ?: defaults.darkMode,
            consentStep = prefs[CONSENT_STEP] ?: defaults.consentStep,
            instructionsStep = prefs[INSTRUCTIONS_STEP] ?: defaults.instructionsStep,
            previewStep = prefs[PREVIEW_STEP] ?: defaults.previewStep,
        )
    }

    private fun UseSmileIDSampleSetting.key(): Preferences.Key<Boolean> = when (this) {
        UseSmileIDSampleSetting.EnhancedSmartSelfie -> ENHANCED_SMART_SELFIE
        UseSmileIDSampleSetting.AgentMode -> AGENT_MODE
        UseSmileIDSampleSetting.DarkMode -> DARK_MODE
        UseSmileIDSampleSetting.ConsentStep -> CONSENT_STEP
        UseSmileIDSampleSetting.InstructionsStep -> INSTRUCTIONS_STEP
        UseSmileIDSampleSetting.PreviewStep -> PREVIEW_STEP
    }

    private companion object {
        // A new key, not the old one reused: `smile_to_capture = true` meant enhanced liveness OFF,
        // so reading it as `enhanced_smart_selfie` would flip capture behaviour under every existing user.
        val ENHANCED_SMART_SELFIE = booleanPreferencesKey("enhanced_smart_selfie")
        val AGENT_MODE = booleanPreferencesKey("agent_mode")
        val DARK_MODE = booleanPreferencesKey("dark_mode")
        val CONSENT_STEP = booleanPreferencesKey("consent_step")
        val INSTRUCTIONS_STEP = booleanPreferencesKey("instructions_step")
        val PREVIEW_STEP = booleanPreferencesKey("preview_step")
        val SESSION_TOKEN = stringPreferencesKey("token_session_token")
        val ENDED_SESSION_ID = stringPreferencesKey("ended_session_id")
        val ENDED_SESSION_AT = longPreferencesKey("ended_session_at")
    }
}

/** A session that has run out, remembered without its credential. */
data class UseSmileIDSampleEndedSession(val id: String, val endedAtMillis: Long)

/** At most one half is ever set: retiring replaces the token with its marker in a single write. */
data class UseSmileIDSampleSessionRecord(
    val live: UseSmileIDSampleTokenSession? = null,
    val ended: UseSmileIDSampleEndedSession? = null,
)

/**
 * Drops settings keys whose control has gone: a device left on Production would keep submitting live
 * with no UI to clear it, and a stored `smile_to_capture` now means the opposite of what it says.
 * Self-terminating, so it needs no version counter.
 */
internal object UseSmileIDSampleRetiredSettingKeys : DataMigration<Preferences> {

    private val RETIRED = listOf(
        booleanPreferencesKey("production"),
        booleanPreferencesKey("smile_to_capture"),
    )

    override suspend fun shouldMigrate(currentData: Preferences): Boolean = RETIRED.any { it in currentData }

    override suspend fun migrate(currentData: Preferences): Preferences =
        currentData.toMutablePreferences().apply { RETIRED.forEach { remove(it) } }

    override suspend fun cleanUp() = Unit
}

// Not an application id, so it stays identity-agnostic and the same across all eight hosts.
private val Context.sampleStore by preferencesDataStore(
    name = "usesmileid_sample",
    produceMigrations = { listOf(UseSmileIDSampleRetiredSettingKeys) },
)
