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
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleKeyValueEditRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionLabel
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTextInput
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
            verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
        ) {
            UseSmileIDSampleSectionLabel(text = "USER DETAILS — ATTACHED TO EVERY JOB")
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(SmileDimens.radiusSurface),
                color = UseSmileIDSampleTheme.colors.surface,
            ) {
                Column {
                    UseSmileIDSampleUserField.entries.forEach { field ->
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
            text = "Save",
            onClick = onSave,
            modifier = Modifier.padding(SmileDimens.spacingMd),
            testId = UseSmileIDSampleTestIds.PROFILE_CONFIG_SAVE,
        )
    }
}

/** The new-profile sheet. Save stays disabled until there is a name, which is the only required field. */
@Composable
fun NewProfileSheet(
    name: String,
    onNameChange: (String) -> Unit,
    onSave: () -> Unit,
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
) {
    com.usesmileid.sampleapps.ui.components.UseSmileIDSampleBottomSheet(
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        title = "New profile",
        testId = UseSmileIDSampleTestIds.NEW_PROFILE_SHEET,
    ) {
        UseSmileIDSampleSectionLabel(text = "ORGANISATION")
        UseSmileIDSampleTextInput(
            value = name,
            onValueChange = onNameChange,
            placeholder = "Organisation name",
            testId = UseSmileIDSampleTestIds.NEW_PROFILE_NAME,
        )
        UseSmileIDSampleButton(
            text = "Save",
            onClick = onSave,
            enabled = name.isNotBlank(),
            testId = UseSmileIDSampleTestIds.NEW_PROFILE_SAVE,
        )
        Text(
            text = "New profiles start in sandbox.",
            style = UseSmileIDSampleTheme.type.textStyleBodySm,
            color = UseSmileIDSampleTheme.colors.textMuted,
        )
    }
}
