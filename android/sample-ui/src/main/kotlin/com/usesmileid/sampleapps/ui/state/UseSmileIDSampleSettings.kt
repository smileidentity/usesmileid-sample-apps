package com.usesmileid.sampleapps.ui.state

import androidx.compose.runtime.Immutable

/** The Settings state. Three of these decide whether a step is composed into the flow at all, rather than toggling anything. */
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

    /**
     * The one owner of the capture mutex: `FlowValidator.validateSelfie()` refuses agent mode
     * together with enhanced liveness at ERROR severity, and enhanced liveness is now the default —
     * so a single tap on Agent mode would otherwise block the run. Turning either on turns the other
     * off here, rather than in the screen, so every persistence path and every port inherits one rule.
     */
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
