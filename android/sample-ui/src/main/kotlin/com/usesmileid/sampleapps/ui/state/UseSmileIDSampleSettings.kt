package com.usesmileid.sampleapps.ui.state

import androidx.compose.runtime.Immutable

/**
 * The Settings screen's state. Three of these look like booleans and are not: they decide whether a
 * step is composed into the SDK flow at all, rather than toggling anything at runtime.
 */
@Immutable
data class UseSmileIDSampleSettings(
    val smileToCapture: Boolean = true,
    val agentMode: Boolean = false,
    val darkMode: Boolean = false,
    val consentStep: Boolean = true,
    val instructionsStep: Boolean = true,
    val previewStep: Boolean = true,
) {
    /** 'Smile to capture' is the inverse of enhanced liveness, so it and agent mode write different fields. */
    val enableEnhancedLiveness: Boolean get() = !smileToCapture
}

/** Which settings row a toggle belongs to, so the screen can report changes without six callbacks. */
enum class UseSmileIDSampleSetting {
    SmileToCapture,
    AgentMode,
    DarkMode,
    ConsentStep,
    InstructionsStep,
    PreviewStep,
}
