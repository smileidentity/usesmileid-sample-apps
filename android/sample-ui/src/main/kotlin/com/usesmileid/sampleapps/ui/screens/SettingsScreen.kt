package com.usesmileid.sampleapps.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.style.TextAlign
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRowDivider
import androidx.annotation.DrawableRes
import androidx.annotation.StringRes
import androidx.compose.ui.res.stringResource
import com.usesmileid.sampleapps.ui.UseSmileIDSampleStrings
import com.usesmileid.sampleapps.ui.R
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleIcon
import androidx.compose.ui.graphics.Color
import com.smileid.designsystem.SmileDimens
import com.smileid.designsystem.smileProfileHues
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleConfirmDialog
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleDestructiveRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleProfileRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionSurface
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRowChevron
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSwitch
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleSetting
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleSettings
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** One ABOUT or LEGAL row: an id, a title, the line beneath it, and where it goes. */
data class UseSmileIDSampleNavRow(
    val id: String,
    @StringRes val title: Int,
    /** A host name, never translated; [supportingTextRes] is the translated alternative. */
    val supportingText: String? = null,
    @StringRes val supportingTextRes: Int? = null,
    @DrawableRes val icon: Int = R.drawable.sample_ic_product_mark,
    /** Opened externally. Null means the app handles the row itself, which only the licences row does. */
    val url: String? = null,
    /**
     * False for a destination the in-app browser cannot render. Both legal pages wrap their document
     * in an embedded PDF, which mobile browsers show as a stub rather than the document — measured
     * 2026-08-25 — so those two hand off to the browser instead of being framed by this app.
     */
    val opensInApp: Boolean = true,
)

/** The rows in the order the design draws them, so a caller can assert the set rather than the screen. */
val useSmileIDSampleNavRows: List<UseSmileIDSampleNavRow> get() = ABOUT_ROWS + LEGAL_ROWS

/** Everything the settings list renders; callbacks stay parameters, like every screen. */
data class UseSmileIDSampleSettingsState(
    val settings: UseSmileIDSampleSettings,
    val organisation: String,
    val initials: String,
    /** Passed in because it names the host, and this module runs under eight. */
    val versionLabel: String,
    /** The token has taken the consent decision away, so the switch stops claiming to own it. */
    val consentBoundByToken: Boolean = false,
    val avatarColor: Color = smileProfileHues.first(),
    /** False while there is no profile, when the card invites creating one. */
    val hasProfile: Boolean = true,
    /** The device's own theme, which the System label names; the shell reads it where the app's choice cannot mask it. */
    val deviceDark: Boolean,
    /** The device's languages, which the System label resolves. */
    val deviceLanguages: List<String> = emptyList(),
)

/** Settings, which every other screen's configuration comes from. */
@Composable
fun SettingsScreen(
    state: UseSmileIDSampleSettingsState,
    onSettingChange: (UseSmileIDSampleSetting, Boolean) -> Unit,
    onProfileClick: () -> Unit,
    onNavRowClick: (UseSmileIDSampleNavRow) -> Unit,
    onCaptureModeClick: () -> Unit,
    onAppearanceClick: () -> Unit,
    onLanguageClick: () -> Unit,
    /** Null hides the DEBUG section: `sample-ui` may not read a host's BuildConfig. */
    onOpenScenarioDrawer: (() -> Unit)?,
    onSignOut: () -> Unit,
    modifier: Modifier = Modifier,
    contentPadding: PaddingValues = PaddingValues(),
) {
    var confirmingSignOut by rememberSaveable { mutableStateOf(false) }
    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .testTag(UseSmileIDSampleTestIds.SETTINGS_SCREEN)
            .windowInsetsPadding(WindowInsets.statusBars),
        contentPadding = contentPadding,
        verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
    ) {
        item {
            Text(
                text = UseSmileIDSampleStrings.settingsTitle,
                style = UseSmileIDSampleTheme.type.textStyleHeadingPage,
                color = UseSmileIDSampleTheme.colors.textTitle,
                modifier = Modifier.padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingXs),
            )
        }

        section(R.string.sample_settings_section_profile) {
            UseSmileIDSampleProfileRow(
                organisation = state.organisation,
                supportingText = if (state.hasProfile) {
                    UseSmileIDSampleStrings.settingsProfileConfigure
                } else {
                    UseSmileIDSampleStrings.settingsProfileCreate
                },
                initials = state.initials,
                selected = false,
                onClick = onProfileClick,
                avatarColor = state.avatarColor,
                trailing = { UseSmileIDSampleSettingRowChevron() },
                testId = UseSmileIDSampleTestIds.PROFILE_SUMMARY,
            )
        }

        // Mutually exclusive, so each row says what turning it on does to the other.
        section(R.string.sample_settings_section_capture) {
            SwitchRow(
                title = UseSmileIDSampleStrings.settingsEnhancedSmartSelfie,
                icon = R.drawable.sample_ic_setting_smile,
                supportingText = if (state.settings.agentMode) {
                    UseSmileIDSampleStrings.settingsEnhancedSmartSelfieMutex
                } else {
                    UseSmileIDSampleStrings.settingsEnhancedSmartSelfieBody
                },
                checked = state.settings.enhancedSmartSelfie,
                setting = UseSmileIDSampleSetting.EnhancedSmartSelfie,
                testId = UseSmileIDSampleTestIds.SETTING_ENHANCED_SMART_SELFIE,
                onSettingChange = onSettingChange,
            )
            UseSmileIDSampleSettingRowDivider()
            SwitchRow(
                title = UseSmileIDSampleStrings.settingsAgentMode,
                icon = R.drawable.sample_ic_setting_agent,
                supportingText = if (state.settings.enhancedSmartSelfie) {
                    UseSmileIDSampleStrings.settingsAgentModeMutex(UseSmileIDSampleStrings.settingsEnhancedSmartSelfie)
                } else {
                    UseSmileIDSampleStrings.settingsAgentModeBody
                },
                checked = state.settings.agentMode,
                setting = UseSmileIDSampleSetting.AgentMode,
                testId = UseSmileIDSampleTestIds.SETTING_AGENT_MODE,
                onSettingChange = onSettingChange,
            )
        }

        section(R.string.sample_settings_section_appearance) {
            UseSmileIDSampleSettingRow(
                title = UseSmileIDSampleStrings.settingsTheme,
                supportingText = state.settings.appearance.label(state.deviceDark),
                onClick = onAppearanceClick,
                leading = { tint -> UseSmileIDSampleIcon(id = R.drawable.sample_ic_setting_dark_mode, tint = tint) },
                trailing = { UseSmileIDSampleSettingRowChevron() },
                testId = UseSmileIDSampleTestIds.SETTING_APPEARANCE,
            )
        }

        section(R.string.sample_settings_section_language) {
            UseSmileIDSampleSettingRow(
                title = UseSmileIDSampleStrings.settingsLanguage,
                supportingText = state.settings.language.label(state.deviceLanguages),
                onClick = onLanguageClick,
                leading = { tint -> UseSmileIDSampleIcon(id = R.drawable.sample_ic_setting_language, tint = tint) },
                trailing = { UseSmileIDSampleSettingRowChevron() },
                testId = UseSmileIDSampleTestIds.SETTING_LANGUAGE,
            )
        }

        section(R.string.sample_settings_section_sdk_screens) {
            SwitchRow(
                title = UseSmileIDSampleStrings.settingsConsent,
                icon = R.drawable.sample_ic_setting_consent,
                supportingText = if (state.consentBoundByToken) {
                    UseSmileIDSampleStrings.settingsConsentBound
                } else {
                    UseSmileIDSampleStrings.settingsConsentBody
                },
                checked = state.settings.consentStep,
                setting = UseSmileIDSampleSetting.ConsentStep,
                testId = UseSmileIDSampleTestIds.SETTING_CONSENT_STEP,
                onSettingChange = onSettingChange,
            )
            UseSmileIDSampleSettingRowDivider()
            SwitchRow(
                title = UseSmileIDSampleStrings.settingsInstructions,
                icon = R.drawable.sample_ic_setting_instructions,
                supportingText = UseSmileIDSampleStrings.settingsInstructionsBody,
                checked = state.settings.instructionsStep,
                setting = UseSmileIDSampleSetting.InstructionsStep,
                testId = UseSmileIDSampleTestIds.SETTING_INSTRUCTIONS_STEP,
                onSettingChange = onSettingChange,
            )
            UseSmileIDSampleSettingRowDivider()
            SwitchRow(
                title = UseSmileIDSampleStrings.settingsPreview,
                icon = R.drawable.sample_ic_setting_preview,
                supportingText = UseSmileIDSampleStrings.settingsPreviewBody,
                checked = state.settings.previewStep,
                setting = UseSmileIDSampleSetting.PreviewStep,
                testId = UseSmileIDSampleTestIds.SETTING_PREVIEW_STEP,
                onSettingChange = onSettingChange,
            )
        }

        // The design draws no such section either; it sits with the other capture choices.
        section(R.string.sample_settings_section_document_capture) {
            UseSmileIDSampleSettingRow(
                title = UseSmileIDSampleStrings.settingsCaptureMode,
                supportingText = state.settings.captureMode.label(),
                onClick = onCaptureModeClick,
                leading = { tint -> UseSmileIDSampleIcon(id = R.drawable.sample_ic_document_verification, tint = tint) },
                trailing = { UseSmileIDSampleSettingRowChevron() },
                testId = UseSmileIDSampleTestIds.SETTING_CAPTURE_MODE,
            )
            UseSmileIDSampleSettingRowDivider()
            SwitchRow(
                title = UseSmileIDSampleStrings.settingsGalleryUpload,
                icon = R.drawable.sample_ic_setting_preview,
                supportingText = UseSmileIDSampleStrings.settingsGalleryUploadBody,
                checked = state.settings.galleryUpload,
                setting = UseSmileIDSampleSetting.GalleryUpload,
                testId = UseSmileIDSampleTestIds.SETTING_GALLERY_UPLOAD,
                onSettingChange = onSettingChange,
            )
            UseSmileIDSampleSettingRowDivider()
            SwitchRow(
                title = UseSmileIDSampleStrings.settingsSkipBack,
                icon = R.drawable.sample_ic_setting_instructions,
                supportingText = UseSmileIDSampleStrings.settingsSkipBackBody,
                checked = state.settings.allowSkipBack,
                setting = UseSmileIDSampleSetting.AllowSkipBack,
                testId = UseSmileIDSampleTestIds.SETTING_ALLOW_SKIP_BACK,
                onSettingChange = onSettingChange,
            )
            UseSmileIDSampleSettingRowDivider()
            SwitchRow(
                title = UseSmileIDSampleStrings.settingsSelfieFirst,
                icon = R.drawable.sample_ic_setting_smile,
                supportingText = UseSmileIDSampleStrings.settingsSelfieFirstBody,
                checked = state.settings.selfieFirst,
                setting = UseSmileIDSampleSetting.SelfieFirst,
                testId = UseSmileIDSampleTestIds.SETTING_SELFIE_FIRST,
                onSettingChange = onSettingChange,
            )
        }

        // The design draws no control for the drawer, so this placement is ours, and debug-only.
        if (onOpenScenarioDrawer != null) {
            section(label = { DEBUG_SECTION }) {
                UseSmileIDSampleSettingRow(
                    title = "Scenarios",
                    supportingText = "Choose how the environment misbehaves",
                    onClick = onOpenScenarioDrawer,
                    leading = { tint -> UseSmileIDSampleIcon(id = R.drawable.sample_ic_setting_scenarios, tint = tint) },
                    trailing = { UseSmileIDSampleSettingRowChevron() },
                    testId = UseSmileIDSampleTestIds.SCENARIO_DRAWER_BUTTON,
                )
            }
        }

        section(R.string.sample_settings_section_about) {
            ABOUT_ROWS.forEachIndexed { index, row ->
                if (index > 0) UseSmileIDSampleSettingRowDivider()
                NavRow(row = row, onClick = onNavRowClick)
            }
        }

        section(R.string.sample_settings_section_legal) {
            LEGAL_ROWS.forEachIndexed { index, row ->
                if (index > 0) UseSmileIDSampleSettingRowDivider()
                NavRow(row = row, onClick = onNavRowClick)
            }
        }

        item {
            UseSmileIDSampleDestructiveRow(
                text = UseSmileIDSampleStrings.settingsSignOut,
                onClick = { confirmingSignOut = true },
                modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
                testId = UseSmileIDSampleTestIds.SIGN_OUT,
            )
        }
        // The last row: flush with the viewport edge it reports clipped bounds to automation, so the
        // caller's [contentPadding] has to clear whatever draws over the list.
        item {
            Text(
                text = state.versionLabel,
                style = UseSmileIDSampleTheme.type.textStyleCaption,
                textAlign = TextAlign.Center,
                color = UseSmileIDSampleTheme.colors.textMuted,
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag(UseSmileIDSampleTestIds.VERSION_LABEL)
                    .padding(SmileDimens.spacingMd),
            )
        }
    }
    if (confirmingSignOut) {
        UseSmileIDSampleConfirmDialog(
            title = UseSmileIDSampleStrings.settingsSignOutTitle,
            text = UseSmileIDSampleStrings.settingsSignOutBody,
            confirmLabel = UseSmileIDSampleStrings.settingsSignOut,
            confirmTestId = UseSmileIDSampleTestIds.SIGN_OUT_CONFIRM,
            onConfirm = {
                confirmingSignOut = false
                onSignOut()
            },
            onDismissRequest = { confirmingSignOut = false },
        )
    }
}

/** A labelled group of rows on one surface, which is how the design draws every settings section. */
private fun androidx.compose.foundation.lazy.LazyListScope.section(
    @StringRes label: Int,
    content: @Composable () -> Unit,
) = section(label = { stringResource(label) }, content = content)

private fun androidx.compose.foundation.lazy.LazyListScope.section(
    label: @Composable () -> String,
    content: @Composable () -> Unit,
) = item {
    UseSmileIDSampleSectionSurface(
        modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
        label = label(),
    ) {
        content()
    }
}

@Composable
private fun SwitchRow(
    title: String,
    supportingText: String,
    checked: Boolean,
    setting: UseSmileIDSampleSetting,
    testId: String,
    onSettingChange: (UseSmileIDSampleSetting, Boolean) -> Unit,
    @DrawableRes icon: Int,
) {
    UseSmileIDSampleSettingRow(
        title = title,
        supportingText = supportingText,
        leading = { tint -> UseSmileIDSampleIcon(id = icon, tint = tint) },
        trailing = {
            UseSmileIDSampleSwitch(
                checked = checked,
                onCheckedChange = { onSettingChange(setting, it) },
                testId = testId,
            )
        },
    )
}

@Composable
private fun NavRow(row: UseSmileIDSampleNavRow, onClick: (UseSmileIDSampleNavRow) -> Unit) {
    UseSmileIDSampleSettingRow(
        title = stringResource(row.title),
        supportingText = row.supportingTextRes?.let { stringResource(it) } ?: row.supportingText,
        onClick = { onClick(row) },
        leading = { tint -> UseSmileIDSampleIcon(id = row.icon, tint = tint) },
        trailing = { UseSmileIDSampleSettingRowChevron() },
        testId = UseSmileIDSampleTestIds.settingNav(row.id),
    )
}

// Instrumentation, so it stays English.
private const val DEBUG_SECTION = "DEBUG"

// Each URL is recorded in spec/screens.json and asserted against it.
private val ABOUT_ROWS = listOf(
    UseSmileIDSampleNavRow(
        id = "documentation",
        title = R.string.sample_settings_documentation,
        supportingText = "docs.usesmileid.com",
        icon = R.drawable.sample_ic_setting_docs,
        url = "https://docs.usesmileid.com/",
    ),
    UseSmileIDSampleNavRow(
        id = "support",
        title = R.string.sample_settings_support,
        supportingTextRes = R.string.sample_settings_support_body,
        icon = R.drawable.sample_ic_setting_support,
        url = "https://smile.id/contact-us",
    ),
)

private val LEGAL_ROWS = listOf(
    // Both of these serve their document as an embedded PDF, so they leave the app (see opensInApp).
    UseSmileIDSampleNavRow(
        id = "terms",
        title = R.string.sample_settings_terms,
        icon = R.drawable.sample_ic_setting_terms,
        url = "https://smile.id/terms-and-conditions",
        opensInApp = false,
    ),
    UseSmileIDSampleNavRow(
        id = "privacy",
        title = R.string.sample_settings_privacy,
        icon = R.drawable.sample_ic_setting_privacy,
        url = "https://smile.id/privacy-policy",
        opensInApp = false,
    ),
    // No url: Apache-2.0 §4 asks the notice to travel with the distribution, so it is a screen here.
    UseSmileIDSampleNavRow(
        id = "licenses",
        title = R.string.sample_settings_licenses,
        icon = R.drawable.sample_ic_setting_licenses,
    ),
)
