package com.usesmileid.sampleapps.ui.state

import androidx.compose.runtime.Immutable

/** The Settings state. Three of these decide whether a step is composed into the flow at all, rather than toggling anything. */
@Immutable
data class UseSmileIDSampleSettings(
    val production: Boolean = false,
    val smileToCapture: Boolean = true,
    val agentMode: Boolean = false,
    val darkMode: Boolean = false,
    val consentStep: Boolean = true,
    val instructionsStep: Boolean = true,
    val previewStep: Boolean = true,
) {
    /** 'Smile to capture' is the inverse of enhanced liveness, so it and agent mode write different fields. */
    val enableEnhancedLiveness: Boolean get() = !smileToCapture

    /** What a flow submits against unless a launch argument pins it. Sandbox by default: a mistap must not bill a live job. */
    val useSandbox: Boolean get() = !production
}

/** Which settings row a toggle belongs to, so the screen can report changes without six callbacks. */
enum class UseSmileIDSampleSetting {
    Production,
    SmileToCapture,
    AgentMode,
    DarkMode,
    ConsentStep,
    InstructionsStep,
    PreviewStep,
}
