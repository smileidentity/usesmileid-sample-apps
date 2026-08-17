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
import com.usesmileid.sampleapps.ui.R
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleIcon
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRowDivider
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleBottomSheet
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
            text = "Make this profile active",
            onClick = onSave,
            modifier = Modifier.padding(SmileDimens.spacingMd),
            testId = UseSmileIDSampleTestIds.PROFILE_CONFIG_SAVE,
        )
    }
}

/** A profile name, then the four user details that will live under it. Create needs the name and both required names. */
@Composable
fun NewProfileSheet(
    name: String,
    firstName: String,
    lastName: String,
    email: String,
    phone: String,
    onNameChange: (String) -> Unit,
    onFirstNameChange: (String) -> Unit,
    onLastNameChange: (String) -> Unit,
    onEmailChange: (String) -> Unit,
    onPhoneChange: (String) -> Unit,
    onSave: () -> Unit,
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
) {
    UseSmileIDSampleBottomSheet(
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        title = "New profile",
        testId = UseSmileIDSampleTestIds.NEW_PROFILE_SHEET,
    ) {
        UseSmileIDSampleTextInput(
            value = name,
            onValueChange = onNameChange,
            placeholder = "Profile name",
            testId = UseSmileIDSampleTestIds.NEW_PROFILE_NAME,
            leading = { tint -> UseSmileIDSampleIcon(id = R.drawable.sample_ic_field_person, tint = tint) },
        )
        UseSmileIDSampleSectionLabel(text = "USER DETAILS")
        UseSmileIDSampleTextInput(
            value = firstName,
            onValueChange = onFirstNameChange,
            placeholder = "First name",
            testId = UseSmileIDSampleTestIds.NEW_PROFILE_FIRST_NAME,
            leading = { tint -> UseSmileIDSampleIcon(id = R.drawable.sample_ic_field_person, tint = tint) },
        )
        UseSmileIDSampleTextInput(
            value = lastName,
            onValueChange = onLastNameChange,
            placeholder = "Last name",
            testId = UseSmileIDSampleTestIds.NEW_PROFILE_LAST_NAME,
            leading = { tint -> UseSmileIDSampleIcon(id = R.drawable.sample_ic_field_person, tint = tint) },
        )
        UseSmileIDSampleTextInput(
            value = email,
            onValueChange = onEmailChange,
            placeholder = "Email (optional)",
            testId = UseSmileIDSampleTestIds.NEW_PROFILE_EMAIL,
            leading = { tint -> UseSmileIDSampleIcon(id = R.drawable.sample_ic_field_email, tint = tint) },
        )
        UseSmileIDSampleTextInput(
            value = phone,
            onValueChange = onPhoneChange,
            placeholder = "Phone (optional)",
            testId = UseSmileIDSampleTestIds.NEW_PROFILE_PHONE,
            leading = { tint -> UseSmileIDSampleIcon(id = R.drawable.sample_ic_field_phone, tint = tint) },
        )
        UseSmileIDSampleButton(
            text = "Create profile",
            onClick = onSave,
            enabled = name.isNotBlank() && firstName.isNotBlank() && lastName.isNotBlank(),
            testId = UseSmileIDSampleTestIds.NEW_PROFILE_SAVE,
        )
    }
}

