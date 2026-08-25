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
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.style.TextAlign
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRowDivider
import androidx.annotation.DrawableRes
import com.usesmileid.sampleapps.ui.R
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleIcon
import androidx.compose.ui.graphics.Color
import com.smileid.designsystem.SmileDimens
import com.smileid.designsystem.smileProfileHues
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
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
    val title: String,
    val supportingText: String? = null,
    @DrawableRes val icon: Int = R.drawable.sample_ic_product_mark,
    /** Opened externally. Null means the app handles the row itself, which only the licences row does. */
    val url: String? = null,
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
    /** The token has taken the consent decision away, so the switch must stop claiming to own it. */
    val consentBoundByToken: Boolean = false,
    val avatarColor: Color = smileProfileHues.first(),
)

/** Settings, which every other screen's configuration comes from. */
@Composable
fun SettingsScreen(
    state: UseSmileIDSampleSettingsState,
    onSettingChange: (UseSmileIDSampleSetting, Boolean) -> Unit,
    onProfileClick: () -> Unit,
    onNavRowClick: (UseSmileIDSampleNavRow) -> Unit,
    onOpenScenarioDrawer: () -> Unit,
    onSignOut: () -> Unit,
    modifier: Modifier = Modifier,
    contentPadding: PaddingValues = PaddingValues(),
) {
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
                text = "Settings",
                style = UseSmileIDSampleTheme.type.textStyleHeadingPage,
                color = UseSmileIDSampleTheme.colors.textTitle,
                modifier = Modifier.padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingXs),
            )
        }

        section("PROFILE") {
            UseSmileIDSampleProfileRow(
                organisation = state.organisation,
                supportingText = "Tap to configure",
                initials = state.initials,
                selected = false,
                onClick = onProfileClick,
                avatarColor = state.avatarColor,
                trailing = { UseSmileIDSampleSettingRowChevron() },
                testId = UseSmileIDSampleTestIds.PROFILE_SUMMARY,
            )
        }

        // The two rows are mutually exclusive, so each says what turning it on will do to the other.
        section("CAPTURE") {
            SwitchRow(
                title = ENHANCED_SMART_SELFIE_TITLE,
                icon = R.drawable.sample_ic_setting_smile,
                supportingText = if (state.settings.agentMode) {
                    "Turns Agent mode off"
                } else {
                    "Face capture uses head-turns"
                },
                checked = state.settings.enhancedSmartSelfie,
                setting = UseSmileIDSampleSetting.EnhancedSmartSelfie,
                testId = UseSmileIDSampleTestIds.SETTING_ENHANCED_SMART_SELFIE,
                onSettingChange = onSettingChange,
            )
            UseSmileIDSampleSettingRowDivider()
            SwitchRow(
                title = "Agent mode",
                icon = R.drawable.sample_ic_setting_agent,
                supportingText = if (state.settings.enhancedSmartSelfie) {
                    "Turns $ENHANCED_SMART_SELFIE_TITLE off"
                } else {
                    "Operator captures for the applicant"
                },
                checked = state.settings.agentMode,
                setting = UseSmileIDSampleSetting.AgentMode,
                testId = UseSmileIDSampleTestIds.SETTING_AGENT_MODE,
                onSettingChange = onSettingChange,
            )
        }

        section("APPEARANCE") {
            SwitchRow(
                title = "Dark mode",
                icon = R.drawable.sample_ic_setting_dark_mode,
                supportingText = "Switch appearance",
                checked = state.settings.darkMode,
                setting = UseSmileIDSampleSetting.DarkMode,
                testId = UseSmileIDSampleTestIds.SETTING_DARK_MODE,
                onSettingChange = onSettingChange,
            )
        }

        section("SDK SCREENS — SHOW OR SKIP FLOW STEPS") {
            SwitchRow(
                title = "Consent screen",
                icon = R.drawable.sample_ic_setting_consent,
                supportingText = if (state.consentBoundByToken) {
                    "The token grants consent, so the screen is skipped"
                } else {
                    "Ask permission before KYC checks"
                },
                checked = state.settings.consentStep,
                setting = UseSmileIDSampleSetting.ConsentStep,
                testId = UseSmileIDSampleTestIds.SETTING_CONSENT_STEP,
                onSettingChange = onSettingChange,
            )
            UseSmileIDSampleSettingRowDivider()
            SwitchRow(
                title = "Instruction screen",
                icon = R.drawable.sample_ic_setting_instructions,
                supportingText = "Prep tips before capture",
                checked = state.settings.instructionsStep,
                setting = UseSmileIDSampleSetting.InstructionsStep,
                testId = UseSmileIDSampleTestIds.SETTING_INSTRUCTIONS_STEP,
                onSettingChange = onSettingChange,
            )
            UseSmileIDSampleSettingRowDivider()
            SwitchRow(
                title = "Preview screen",
                icon = R.drawable.sample_ic_setting_preview,
                supportingText = "Confirm or retake after capture",
                checked = state.settings.previewStep,
                setting = UseSmileIDSampleSetting.PreviewStep,
                testId = UseSmileIDSampleTestIds.SETTING_PREVIEW_STEP,
                onSettingChange = onSettingChange,
            )
        }

        // The design draws no control for the drawer, so this placement is ours.
        section("DEBUG") {
            UseSmileIDSampleSettingRow(
                title = "Scenarios",
                supportingText = "Choose how the environment misbehaves",
                onClick = onOpenScenarioDrawer,
                leading = { tint -> UseSmileIDSampleIcon(id = R.drawable.sample_ic_setting_scenarios, tint = tint) },
                trailing = { UseSmileIDSampleSettingRowChevron() },
                testId = UseSmileIDSampleTestIds.SCENARIO_DRAWER_BUTTON,
            )
        }

        section("ABOUT") {
            ABOUT_ROWS.forEachIndexed { index, row ->
                if (index > 0) UseSmileIDSampleSettingRowDivider()
                NavRow(row = row, onClick = onNavRowClick)
            }
        }

        section("LEGAL") {
            LEGAL_ROWS.forEachIndexed { index, row ->
                if (index > 0) UseSmileIDSampleSettingRowDivider()
                NavRow(row = row, onClick = onNavRowClick)
            }
        }

        item {
            UseSmileIDSampleDestructiveRow(
                text = "Sign out",
                onClick = onSignOut,
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
}

/** A labelled group of rows on one surface, which is how the design draws every settings section. */
private fun androidx.compose.foundation.lazy.LazyListScope.section(
    label: String,
    content: @Composable () -> Unit,
) = item {
    UseSmileIDSampleSectionSurface(
        modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
        label = label,
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
        title = row.title,
        supportingText = row.supportingText,
        onClick = { onClick(row) },
        leading = { tint -> UseSmileIDSampleIcon(id = row.icon, tint = tint) },
        trailing = { UseSmileIDSampleSettingRowChevron() },
        testId = UseSmileIDSampleTestIds.settingNav(row.id),
    )
}

// The design marks the trademark here and nowhere else on this screen (node 5206:2898).
private const val ENHANCED_SMART_SELFIE_TITLE = "Enhanced SmartSelfie\u2122"

// The URLs the design's own copy names, each recorded in spec/screens.json and asserted against it.
private val ABOUT_ROWS = listOf(
    UseSmileIDSampleNavRow(
        id = "documentation",
        title = "Documentation",
        supportingText = "docs.usesmileid.com",
        icon = R.drawable.sample_ic_setting_docs,
        url = "https://docs.usesmileid.com/",
    ),
    UseSmileIDSampleNavRow(
        id = "support",
        title = "Support",
        supportingText = "Contact the Smile team",
        icon = R.drawable.sample_ic_setting_support,
        url = "https://smile.id/contact-us",
    ),
)

private val LEGAL_ROWS = listOf(
    UseSmileIDSampleNavRow(
        id = "terms",
        title = "Terms of Service",
        icon = R.drawable.sample_ic_setting_terms,
        url = "https://smile.id/terms-and-conditions",
    ),
    UseSmileIDSampleNavRow(
        id = "privacy",
        title = "Privacy Policy",
        icon = R.drawable.sample_ic_setting_privacy,
        url = "https://smile.id/privacy-policy",
    ),
    // No url: Apache-2.0 §4 asks the notice to travel with the distribution, so it is a screen here.
    UseSmileIDSampleNavRow(
        id = "licenses",
        title = "Open-source licenses",
        icon = R.drawable.sample_ic_setting_licenses,
    ),
)
