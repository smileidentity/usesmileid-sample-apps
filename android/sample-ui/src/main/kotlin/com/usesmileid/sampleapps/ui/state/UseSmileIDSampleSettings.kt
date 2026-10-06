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
    /** Typed like [captureMode]; System follows the device. */
    val appearance: UseSmileIDSampleAppearance = UseSmileIDSampleAppearance.System,
    /** Typed like [appearance]; System follows the device's own language. */
    val language: UseSmileIDSampleLanguage = UseSmileIDSampleLanguage.System,
) {
    /** Reads one row, so a caller can diff two states without naming every field. */
    operator fun get(setting: UseSmileIDSampleSetting): Boolean = when (setting) {
        UseSmileIDSampleSetting.EnhancedSmartSelfie -> enhancedSmartSelfie
        UseSmileIDSampleSetting.AgentMode -> agentMode
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
    ConsentStep,
    InstructionsStep,
    PreviewStep,
    GalleryUpload,
    AllowSkipBack,
    SelfieFirst,
}

/** DocumentCaptureConfig.captureMode, in `spec/test-ids.json`'s vocabulary. */
enum class UseSmileIDSampleCaptureMode(val id: String) {
    Auto("auto"),
    Manual("manual"),
    AutoWithFallback("autoWithFallback"),
}

/** The app's theme choice; System follows the device's own theme. */
enum class UseSmileIDSampleAppearance(val id: String) {
    System("system"),
    Light("light"),
    Dark("dark"),
    ;

    /** Whether the app renders dark, given the device's own theme. */
    fun isDark(deviceDark: Boolean): Boolean = when (this) {
        System -> deviceDark
        Light -> false
        Dark -> true
    }
}

/** The app's language: System follows the device; the rest are in `spec/l10n/languages.json`. */
enum class UseSmileIDSampleLanguage(val id: String, val endonym: String) {
    System("system", ""),
    English("en", "English"),
    French("fr", "Français"),
    Arabic("ar", "العربية"),
    Hebrew("he", "עברית"),
    ;

    /** System resolves to the first device language the app ships, else English. */
    fun resolved(deviceLanguages: List<String>): UseSmileIDSampleLanguage =
        if (this != System) this else deviceLanguages.firstNotNullOfOrNull(::shipped) ?: English

    companion object {
        /** The shipped language a BCP 47 tag names, by its language subtag; Android still reports Hebrew as `iw`. */
        fun shipped(tag: String): UseSmileIDSampleLanguage? {
            val language = tag.substringBefore('-').substringBefore('_').lowercase().let { if (it == "iw") "he" else it }
            return entries.firstOrNull { it != System && it.id == language }
        }
    }
}
