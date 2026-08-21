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
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleProfileRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionSurface
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRowChevron
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSwitch
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleSetting
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleSettings
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** One ABOUT or LEGAL row: an id, a title, and the line beneath it. */
data class UseSmileIDSampleNavRow(
    val id: String,
    val title: String,
    val supportingText: String? = null,
    @DrawableRes val icon: Int = R.drawable.sample_ic_product_mark,
)

/** Everything the settings list renders; callbacks stay parameters, like every screen. */
data class UseSmileIDSampleSettingsState(
    val settings: UseSmileIDSampleSettings,
    val environment: UseSmileIDSampleEnvironment,
    val environmentPinned: Boolean,
    val organisation: String,
    val initials: String,
    /** Passed in because it names the host, and this module runs under eight. */
    val versionLabel: String,
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

        // Not in the design. Read-only while a launch argument owns the choice.
        section("ENVIRONMENT") {
            SwitchRow(
                title = "Production",
                icon = R.drawable.sample_ic_settings,
                supportingText = when {
                    state.environmentPinned -> "Pinned by the sandbox launch argument"
                    state.environment == UseSmileIDSampleEnvironment.Production -> "Jobs submit to the live environment"
                    else -> "Jobs submit to sandbox"
                },
                checked = state.environment == UseSmileIDSampleEnvironment.Production,
                setting = UseSmileIDSampleSetting.Production,
                testId = UseSmileIDSampleTestIds.SETTING_PRODUCTION,
                onSettingChange = onSettingChange,
                enabled = !state.environmentPinned,
            )
        }

        // Two rows: 'Smile to capture' is the inverse of enhanced liveness, so it and agent mode differ.
        section("CAPTURE") {
            SwitchRow(
                title = "Smile to capture",
                icon = R.drawable.sample_ic_setting_smile,
                supportingText = "Passive capture — smile detection",
                checked = state.settings.smileToCapture,
                setting = UseSmileIDSampleSetting.SmileToCapture,
                testId = UseSmileIDSampleTestIds.SETTING_SMILE_TO_CAPTURE,
                onSettingChange = onSettingChange,
            )
            UseSmileIDSampleSettingRowDivider()
            SwitchRow(
                title = "Agent mode",
                icon = R.drawable.sample_ic_setting_agent,
                supportingText = "Operator captures for the applicant",
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
                supportingText = "Ask permission before KYC checks",
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
    enabled: Boolean = true,
) {
    UseSmileIDSampleSettingRow(
        title = title,
        supportingText = supportingText,
        leading = { tint -> UseSmileIDSampleIcon(id = icon, tint = tint) },
        trailing = {
            UseSmileIDSampleSwitch(
                checked = checked,
                onCheckedChange = { onSettingChange(setting, it) },
                enabled = enabled,
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

private val ABOUT_ROWS = listOf(
    UseSmileIDSampleNavRow("documentation", "Documentation", "docs.smileidentity.com", R.drawable.sample_ic_setting_docs),
    UseSmileIDSampleNavRow("support", "Support", "Contact the Smile team", R.drawable.sample_ic_setting_support),
)

private val LEGAL_ROWS = listOf(
    UseSmileIDSampleNavRow("terms", "Terms of Service", icon = R.drawable.sample_ic_setting_terms),
    UseSmileIDSampleNavRow("privacy", "Privacy Policy", icon = R.drawable.sample_ic_setting_privacy),
    UseSmileIDSampleNavRow("licenses", "Open-source licenses", icon = R.drawable.sample_ic_setting_licenses),
)
