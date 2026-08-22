package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.R
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleBottomSheet
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleIcon
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionLabel
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTextInput

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
