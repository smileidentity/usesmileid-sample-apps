package com.usesmileid.sampleapps.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.foundation.BorderStroke
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRowDivider
import androidx.compose.ui.unit.dp
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleKeyValueEditRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionLabel
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBar
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserField
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** A profile's user-details defaults, which is what seeds the Consent Details Form for its jobs. */
@Composable
fun ProfileConfigScreen(
    organisation: String,
    defaults: UseSmileIDSampleUserDetails,
    onFieldChange: (UseSmileIDSampleUserField, String) -> Unit,
    onBack: () -> Unit,
    onSave: () -> Unit,
    modifier: Modifier = Modifier,
    isActive: Boolean = false,
    contentPadding: PaddingValues = PaddingValues(),
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .testTag(UseSmileIDSampleTestIds.PROFILE_CONFIG_SCREEN),
    ) {
        UseSmileIDSampleTopAppBar(title = organisation, onBack = onBack)
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(contentPadding)
                .padding(horizontal = SmileDimens.spacingMd),
            verticalArrangement = Arrangement.spacedBy(SECTION_GAP),
        ) {
            UseSmileIDSampleSectionLabel(text = "USER DETAILS — ATTACHED TO EVERY JOB")
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(SmileDimens.radiusSurface),
                color = UseSmileIDSampleTheme.colors.surface,
                border = BorderStroke(SmileDimens.borderWidthHairline, UseSmileIDSampleTheme.colors.card.border),
            ) {
                Column {
                    UseSmileIDSampleUserField.entries.forEachIndexed { index, field ->
                        if (index > 0) UseSmileIDSampleSettingRowDivider()
                        UseSmileIDSampleKeyValueEditRow(
                            label = field.label,
                            value = field.read(defaults),
                            onValueChange = { onFieldChange(field, it) },
                            placeholder = field.placeholder,
                            required = field.required,
                            testId = UseSmileIDSampleTestIds.profileConfigField(field.id),
                        )
                    }
                }
            }
        }
        UseSmileIDSampleButton(
            // The design disables it on the profile that is already active, and says so.
            text = if (isActive) "Active profile" else "Make this profile active",
            onClick = onSave,
            enabled = !isActive,
            modifier = Modifier.padding(SmileDimens.spacingMd),
            testId = UseSmileIDSampleTestIds.PROFILE_CONFIG_SAVE,
        )
    }
}

/** The design's gap between the header, the label, the card and the CTA. */
private val SECTION_GAP = 14.dp
