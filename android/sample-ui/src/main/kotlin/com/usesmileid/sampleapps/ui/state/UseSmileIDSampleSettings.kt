package com.usesmileid.sampleapps.ui.state

import androidx.compose.runtime.Immutable

/**
 * The Settings state. Three of these decide whether a step is composed into the flow at all.
 *
 * The capture mutex is in [withSetting] and [normalised], not this constructor: stored preferences
 * predate the rule, so rejecting the pair here would crash a device that already has both.
 */
@Immutable
data class UseSmileIDSampleSettings(
    /** ON is the head-turn challenge, which is the default the design draws. */
    val enhancedSmartSelfie: Boolean = true,
    val agentMode: Boolean = false,
    val darkMode: Boolean = false,
    val consentStep: Boolean = true,
    val instructionsStep: Boolean = true,
    val previewStep: Boolean = true,
) {
    /** Reads one row, so a caller can diff two states without naming six fields. */
    operator fun get(setting: UseSmileIDSampleSetting): Boolean = when (setting) {
        UseSmileIDSampleSetting.EnhancedSmartSelfie -> enhancedSmartSelfie
        UseSmileIDSampleSetting.AgentMode -> agentMode
        UseSmileIDSampleSetting.DarkMode -> darkMode
        UseSmileIDSampleSetting.ConsentStep -> consentStep
        UseSmileIDSampleSetting.InstructionsStep -> instructionsStep
        UseSmileIDSampleSetting.PreviewStep -> previewStep
    }

    /** Drops enhanced liveness where a stored state carries both, so the SDK is never handed the pair it refuses. */
    fun normalised(): UseSmileIDSampleSettings =
        if (agentMode && enhancedSmartSelfie) copy(enhancedSmartSelfie = false) else this

    /** The capture mutex: the SDK refuses agent mode with enhanced liveness, so turning either on turns the other off. */
    fun withSetting(setting: UseSmileIDSampleSetting, enabled: Boolean): UseSmileIDSampleSettings =
        when (setting) {
            UseSmileIDSampleSetting.EnhancedSmartSelfie ->
                copy(enhancedSmartSelfie = enabled, agentMode = agentMode && !enabled)
            UseSmileIDSampleSetting.AgentMode ->
                copy(agentMode = enabled, enhancedSmartSelfie = enhancedSmartSelfie && !enabled)
            UseSmileIDSampleSetting.DarkMode -> copy(darkMode = enabled)
            UseSmileIDSampleSetting.ConsentStep -> copy(consentStep = enabled)
            UseSmileIDSampleSetting.InstructionsStep -> copy(instructionsStep = enabled)
            UseSmileIDSampleSetting.PreviewStep -> copy(previewStep = enabled)
        }
}

/** Which settings row a toggle belongs to, so the screen can report changes without six callbacks. */
enum class UseSmileIDSampleSetting {
    EnhancedSmartSelfie,
    AgentMode,
    DarkMode,
    ConsentStep,
    InstructionsStep,
    PreviewStep,
}
