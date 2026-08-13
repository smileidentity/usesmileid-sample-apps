package com.usesmileid.sampleapps.ui.golden

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.components.ChevronRightGlyph
import com.usesmileid.sampleapps.ui.components.ProductMarkGlyph
import com.usesmileid.sampleapps.ui.components.TorchGlyph
import com.usesmileid.sampleapps.ui.components.TrashGlyph
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleDataFieldRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleDateGroupHeader
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleDestructiveRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleFilterChip
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleJobRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleKeyValueEditRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleOptionRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleProfileRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSelectTrigger
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSelectionBar
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSelectionCheckbox
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRowChevron
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSwitch
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBar
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBarButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBarEmphasis
import org.junit.Test

/** `BottomSheet` is absent on purpose: `ModalBottomSheet` renders into its own window, so it is verified on a device. */
class CompositeGoldenTest : GoldenTest() {

    @Test
    fun top_app_bar() = goldens("top_app_bar") { TopAppBars() }

    @Test
    fun top_app_bar_max_font_scale() = assertSurvivesMaxFontScale { TopAppBars() }

    @Test
    fun data_field_row() = goldens("data_field_row") { DataFieldRows() }

    @Test
    fun data_field_row_max_font_scale() = assertSurvivesMaxFontScale { DataFieldRows() }

    @Test
    fun key_value_edit_row() = goldens("key_value_edit_row") { KeyValueEditRows() }

    @Test
    fun key_value_edit_row_max_font_scale() = assertSurvivesMaxFontScale { KeyValueEditRows() }

    @Test
    fun setting_row() = goldens("setting_row") { SettingRows() }

    @Test
    fun setting_row_max_font_scale() = assertSurvivesMaxFontScale { SettingRows() }

    @Test
    fun profile_row() = goldens("profile_row") { ProfileRows() }

    @Test
    fun profile_row_max_font_scale() = assertSurvivesMaxFontScale { ProfileRows() }

    @Test
    fun option_row() = goldens("option_row") { OptionRows() }

    @Test
    fun option_row_max_font_scale() = assertSurvivesMaxFontScale { OptionRows() }

    @Test
    fun select_trigger() = goldens("select_trigger") { SelectTriggers() }

    @Test
    fun select_trigger_max_font_scale() = assertSurvivesMaxFontScale { SelectTriggers() }

    @Test
    fun filter_chip() = goldens("filter_chip") { FilterChips() }

    @Test
    fun filter_chip_max_font_scale() = assertSurvivesMaxFontScale { FilterChips() }

    @Test
    fun date_group_header() = goldens("date_group_header") { DateGroupHeaders() }

    @Test
    fun date_group_header_max_font_scale() = assertSurvivesMaxFontScale { DateGroupHeaders() }

    @Test
    fun job_row() = goldens("job_row") { JobRows() }

    @Test
    fun job_row_max_font_scale() = assertSurvivesMaxFontScale { JobRows() }

    @Test
    fun selection_checkbox() = goldens("selection_checkbox") { SelectionCheckboxes() }

    @Test
    fun selection_checkbox_max_font_scale() = assertSurvivesMaxFontScale { SelectionCheckboxes() }

    @Test
    fun selection_bar() = goldens("selection_bar") { SelectionBars() }

    @Test
    fun selection_bar_max_font_scale() = assertSurvivesMaxFontScale { SelectionBars() }
}

private val stack: Arrangement.Vertical = Arrangement.spacedBy(SmileDimens.spacingXs)

@Composable
private fun TopAppBars() = Column(verticalArrangement = stack) {
    UseSmileIDSampleTopAppBar(title = "Verification details", onBack = {})
    UseSmileIDSampleTopAppBar(title = "Verification details", onBack = {}) {
        UseSmileIDSampleTopAppBarButton(contentDescription = "Delete", onClick = {}) { tint ->
            TrashGlyph(tint = tint)
        }
    }
    UseSmileIDSampleTopAppBar(title = "Scan token", onBack = {}) {
        UseSmileIDSampleTopAppBarButton(
            contentDescription = "Torch",
            onClick = {},
            emphasis = UseSmileIDSampleTopAppBarEmphasis.Filled,
        ) { tint -> TorchGlyph(tint = tint) }
    }
    UseSmileIDSampleTopAppBar(title = "Enhanced Document Verification", onBack = {})
}

@Composable
private fun DataFieldRows() = Column(verticalArrangement = stack) {
    UseSmileIDSampleDataFieldRow(label = "Created_at", value = "2026-07-16T11:50:12.253Z")
    UseSmileIDSampleDataFieldRow(label = "Job_id", value = "job_01ky31za…", onCopy = {})
    UseSmileIDSampleDataFieldRow(label = "Message", value = "Provisional — needs review")
    UseSmileIDSampleDataFieldRow(label = "Status", value = "202 Accepted")
    UseSmileIDSampleDataFieldRow(label = "User_id", value = "user_01ky31za…", onCopy = {})
}

@Composable
private fun KeyValueEditRows() = Column(verticalArrangement = stack) {
    UseSmileIDSampleKeyValueEditRow(
        label = "First name",
        value = "",
        onValueChange = {},
        placeholder = "Add first name",
        required = true,
    )
    UseSmileIDSampleKeyValueEditRow(label = "Last name", value = "Asante", onValueChange = {}, required = true)
    UseSmileIDSampleKeyValueEditRow(
        label = "Email (optional)",
        value = "",
        onValueChange = {},
        placeholder = "name@company.com",
    )
    UseSmileIDSampleKeyValueEditRow(label = "Phone (optional)", value = "+254 700 000 000", onValueChange = {})
    UseSmileIDSampleKeyValueEditRow(
        label = "Country",
        value = "Kenya",
        onValueChange = {},
        enabled = false,
    )
}

@Composable
private fun SettingRows() = Column(verticalArrangement = stack) {
    UseSmileIDSampleSettingRow(
        title = "Smile to capture",
        supportingText = "Passive capture — smile detection",
        leading = { tint -> ProductMarkGlyph(tint = tint) },
        trailing = { UseSmileIDSampleSwitch(checked = true, onCheckedChange = {}) },
    )
    UseSmileIDSampleSettingRow(
        title = "Agent mode",
        supportingText = "Operator captures for the applicant",
        leading = { tint -> ProductMarkGlyph(tint = tint) },
        trailing = { UseSmileIDSampleSwitch(checked = false, onCheckedChange = {}) },
    )
    UseSmileIDSampleSettingRow(
        title = "Documentation",
        supportingText = "docs.smileidentity.com",
        onClick = {},
        leading = { tint -> ProductMarkGlyph(tint = tint) },
        trailing = { UseSmileIDSampleSettingRowChevron() },
    )
    UseSmileIDSampleSettingRow(
        title = "Terms of Service",
        onClick = {},
        leading = { tint -> ProductMarkGlyph(tint = tint) },
        trailing = { UseSmileIDSampleSettingRowChevron() },
    )
    UseSmileIDSampleDestructiveRow(text = "Sign out", onClick = {})
}

@Composable
private fun ProfileRows() = Column(verticalArrangement = stack) {
    UseSmileIDSampleProfileRow(
        organisation = "UpTech Finance",
        supportingText = "Kwame Asante",
        initials = "KA",
        selected = true,
        onClick = {},
    )
    UseSmileIDSampleProfileRow(
        organisation = "Kazi Microlending",
        supportingText = "Amina Diallo",
        initials = "AD",
        selected = false,
        onClick = {},
    )
}

@Composable
private fun OptionRows() = Column(verticalArrangement = stack) {
    UseSmileIDSampleOptionRow(label = "Nigeria", selected = false, onClick = {}, leadingText = "🇳🇬")
    UseSmileIDSampleOptionRow(label = "Kenya", selected = true, onClick = {}, leadingText = "🇰🇪")
    UseSmileIDSampleOptionRow(label = "National ID", selected = false, onClick = {})
    UseSmileIDSampleOptionRow(label = "Passport", selected = true, onClick = {})
}

@Composable
private fun SelectTriggers() = Column(verticalArrangement = stack) {
    UseSmileIDSampleSelectTrigger(value = null, placeholder = "Select country", onClick = {})
    UseSmileIDSampleSelectTrigger(value = "Kenya", placeholder = "Select country", onClick = {})
    UseSmileIDSampleSelectTrigger(value = null, placeholder = "Select ID type", onClick = {}, enabled = false)
    UseSmileIDSampleSelectTrigger(
        value = null,
        placeholder = "Select country",
        onClick = {},
        leading = { tint -> ChevronRightGlyph(tint = tint) },
    )
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun FilterChips() = FlowRow(
    horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
    verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
) {
    UseSmileIDSampleFilterChip(label = "All", count = 11, selected = true, onClick = {})
    UseSmileIDSampleFilterChip(label = "Clear", count = 6, selected = false, onClick = {})
    UseSmileIDSampleFilterChip(label = "Attention", count = 2, selected = false, onClick = {})
    UseSmileIDSampleFilterChip(label = "Blocked", count = 2, selected = false, onClick = {})
}

@Composable
private fun DateGroupHeaders() = Column(verticalArrangement = stack) {
    UseSmileIDSampleDateGroupHeader(relative = "TODAY", absolute = "THU, 16 JUL 2026")
    UseSmileIDSampleDateGroupHeader(relative = "YESTERDAY", absolute = "WED, 15 JUL 2026")
}

@Composable
private fun JobRows() = Column(verticalArrangement = stack) {
    UseSmileIDSampleJobRow(
        product = "SmartSelfie Enrollment",
        jobId = "7d2f01aa…",
        time = "13:03:41",
        status = UseSmileIDSampleStatus.Clear,
        onClick = {},
    )
    UseSmileIDSampleJobRow(
        product = "SmartSelfie Authentication",
        jobId = "8f3b912c…",
        time = "13:00:07",
        status = UseSmileIDSampleStatus.Processing,
        onClick = {},
    )
    UseSmileIDSampleJobRow(
        product = "Enhanced Document Verification",
        jobId = "b6e4d90f…",
        time = "12:36:59",
        status = UseSmileIDSampleStatus.Blocked,
        onClick = {},
    )
    Row(
        horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        UseSmileIDSampleSelectionCheckbox(checked = true, onCheckedChange = {})
        UseSmileIDSampleJobRow(
            product = "Biometric KYC",
            jobId = "c41b8a2e…",
            time = "11:50:12",
            status = UseSmileIDSampleStatus.Attention,
        )
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun SelectionCheckboxes() = FlowRow(
    horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
) {
    UseSmileIDSampleSelectionCheckbox(checked = false, onCheckedChange = {})
    UseSmileIDSampleSelectionCheckbox(checked = true, onCheckedChange = {})
}

@Composable
private fun SelectionBars() = Column(verticalArrangement = stack) {
    UseSmileIDSampleSelectionBar(selectedCount = 0, onRemove = {})
    UseSmileIDSampleSelectionBar(selectedCount = 2, onRemove = {})
}
