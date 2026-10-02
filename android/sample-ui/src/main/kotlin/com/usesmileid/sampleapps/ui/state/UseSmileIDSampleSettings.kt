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
    /** DocumentCaptureConfig.allowGalleryUpload; off, as the SDK defaults it. */
    val galleryUpload: Boolean = false,
    /** DocumentCaptureConfig.allowSkipBack; off, as the SDK defaults it. */
    val allowSkipBack: Boolean = false,
    /** The document products capture the selfie before the document. */
    val selfieFirst: Boolean = false,
    /** A typed field rather than one of the switches: three values, not two. */
    val captureMode: UseSmileIDSampleCaptureMode = UseSmileIDSampleCaptureMode.AutoWithFallback,
) {
    /** Reads one row, so a caller can diff two states without naming every field. */
    operator fun get(setting: UseSmileIDSampleSetting): Boolean = when (setting) {
        UseSmileIDSampleSetting.EnhancedSmartSelfie -> enhancedSmartSelfie
        UseSmileIDSampleSetting.AgentMode -> agentMode
        UseSmileIDSampleSetting.DarkMode -> darkMode
        UseSmileIDSampleSetting.ConsentStep -> consentStep
        UseSmileIDSampleSetting.InstructionsStep -> instructionsStep
        UseSmileIDSampleSetting.PreviewStep -> previewStep
        UseSmileIDSampleSetting.GalleryUpload -> galleryUpload
        UseSmileIDSampleSetting.AllowSkipBack -> allowSkipBack
        UseSmileIDSampleSetting.SelfieFirst -> selfieFirst
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
            UseSmileIDSampleSetting.GalleryUpload -> copy(galleryUpload = enabled)
            UseSmileIDSampleSetting.AllowSkipBack -> copy(allowSkipBack = enabled)
            UseSmileIDSampleSetting.SelfieFirst -> copy(selfieFirst = enabled)
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
    GalleryUpload,
    AllowSkipBack,
    SelfieFirst,
}

/** DocumentCaptureConfig.captureMode, in `spec/test-ids.json`'s vocabulary. */
enum class UseSmileIDSampleCaptureMode(val id: String, val label: String, val supportingText: String) {
    Auto("auto", "Automatic", "Captures when the document is held steady"),
    Manual("manual", "Manual", "The shutter shows at once"),
    AutoWithFallback("autoWithFallback", "Automatic with manual fallback", "The shutter shows after 10 seconds"),
}
