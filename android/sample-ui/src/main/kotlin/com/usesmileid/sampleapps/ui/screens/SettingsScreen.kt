package com.usesmileid.sampleapps.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.ProductMarkGlyph
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleDestructiveRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleProfileRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionLabel
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRowChevron
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSwitch
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleSetting
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleSettings
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** One ABOUT or LEGAL row: an id, a title, and the line beneath it. */
data class UseSmileIDSampleNavRow(val id: String, val title: String, val supportingText: String? = null)

/** Settings, which every other screen's configuration comes from. [versionLabel] is passed in because it names the host, and this module runs under eight. */
@Composable
fun SettingsScreen(
    settings: UseSmileIDSampleSettings,
    onSettingChange: (UseSmileIDSampleSetting, Boolean) -> Unit,
    organisation: String,
    initials: String,
    versionLabel: String,
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
                organisation = organisation,
                supportingText = "Tap to configure",
                initials = initials,
                selected = false,
                onClick = onProfileClick,
                trailing = { UseSmileIDSampleSettingRowChevron() },
                testId = UseSmileIDSampleTestIds.PROFILE_SUMMARY,
            )
        }

        // Two rows: 'Smile to capture' is the inverse of enhanced liveness, so it and agent mode differ.
        section("CAPTURE") {
            SwitchRow(
                title = "Smile to capture",
                supportingText = "Passive capture — smile detection",
                checked = settings.smileToCapture,
                setting = UseSmileIDSampleSetting.SmileToCapture,
                testId = UseSmileIDSampleTestIds.SETTING_SMILE_TO_CAPTURE,
                onSettingChange = onSettingChange,
            )
            SwitchRow(
                title = "Agent mode",
                supportingText = "Operator captures for the applicant",
                checked = settings.agentMode,
                setting = UseSmileIDSampleSetting.AgentMode,
                testId = UseSmileIDSampleTestIds.SETTING_AGENT_MODE,
                onSettingChange = onSettingChange,
            )
        }

        section("APPEARANCE") {
            SwitchRow(
                title = "Dark mode",
                supportingText = "Switch appearance",
                checked = settings.darkMode,
                setting = UseSmileIDSampleSetting.DarkMode,
                testId = UseSmileIDSampleTestIds.SETTING_DARK_MODE,
                onSettingChange = onSettingChange,
            )
        }

        section("SDK SCREENS — SHOW OR SKIP FLOW STEPS") {
            SwitchRow(
                title = "Consent screen",
                supportingText = "Ask permission before KYC checks",
                checked = settings.consentStep,
                setting = UseSmileIDSampleSetting.ConsentStep,
                testId = UseSmileIDSampleTestIds.SETTING_CONSENT_STEP,
                onSettingChange = onSettingChange,
            )
            SwitchRow(
                title = "Instruction screen",
                supportingText = "Prep tips before capture",
                checked = settings.instructionsStep,
                setting = UseSmileIDSampleSetting.InstructionsStep,
                testId = UseSmileIDSampleTestIds.SETTING_INSTRUCTIONS_STEP,
                onSettingChange = onSettingChange,
            )
            SwitchRow(
                title = "Preview screen",
                supportingText = "Confirm or retake after capture",
                checked = settings.previewStep,
                setting = UseSmileIDSampleSetting.PreviewStep,
                testId = UseSmileIDSampleTestIds.SETTING_PREVIEW_STEP,
                onSettingChange = onSettingChange,
            )
        }

        // The design draws no control for the drawer, so this placement is ours and worth confirming.
        section("DEBUG") {
            UseSmileIDSampleSettingRow(
                title = "Scenarios",
                supportingText = "Choose how the environment misbehaves",
                onClick = onOpenScenarioDrawer,
                leading = { tint -> ProductMarkGlyph(tint = tint) },
                trailing = { UseSmileIDSampleSettingRowChevron() },
                testId = UseSmileIDSampleTestIds.SCENARIO_DRAWER_BUTTON,
            )
        }

        section("ABOUT") { ABOUT_ROWS.forEach { NavRow(row = it, onClick = onNavRowClick) } }

        section("LEGAL") { LEGAL_ROWS.forEach { NavRow(row = it, onClick = onNavRowClick) } }

        item {
            UseSmileIDSampleDestructiveRow(
                text = "Sign out",
                onClick = onSignOut,
                modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
                testId = UseSmileIDSampleTestIds.SIGN_OUT,
            )
        }
        item {
            Text(
                text = versionLabel,
                style = UseSmileIDSampleTheme.type.textStyleBodySm,
                color = UseSmileIDSampleTheme.colors.textMuted,
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag(UseSmileIDSampleTestIds.VERSION_LABEL)
                    .padding(SmileDimens.spacingMd),
            )
        }
        // Trailing space, so the last row is not flush with the viewport edge, where it renders fine
        // but reports clipped bounds to automation.
        item { Spacer(modifier = Modifier.height(SmileDimens.space64)) }
    }
}

/** A labelled group of rows on one surface, which is how the design draws every settings section. */
private fun androidx.compose.foundation.lazy.LazyListScope.section(
    label: String,
    content: @Composable () -> Unit,
) = item {
    Column(
        modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
        verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
    ) {
        UseSmileIDSampleSectionLabel(text = label)
        Surface(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(SmileDimens.radiusSurface),
            color = UseSmileIDSampleTheme.colors.surface,
        ) {
            Column { content() }
        }
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
) {
    UseSmileIDSampleSettingRow(
        title = title,
        supportingText = supportingText,
        leading = { tint -> ProductMarkGlyph(tint = tint) },
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
        leading = { tint -> ProductMarkGlyph(tint = tint) },
        trailing = { UseSmileIDSampleSettingRowChevron() },
        testId = UseSmileIDSampleTestIds.settingNav(row.id),
    )
}

private val ABOUT_ROWS = listOf(
    UseSmileIDSampleNavRow("documentation", "Documentation", "docs.smileidentity.com"),
    UseSmileIDSampleNavRow("support", "Support", "Contact the Smile team"),
)

private val LEGAL_ROWS = listOf(
    UseSmileIDSampleNavRow("terms", "Terms of Service"),
    UseSmileIDSampleNavRow("privacy", "Privacy Policy"),
    UseSmileIDSampleNavRow("licenses", "Open-source licenses"),
)
