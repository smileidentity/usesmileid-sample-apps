package com.usesmileid.sampleapps.ui.screens

import androidx.compose.ui.res.stringResource
import com.usesmileid.sampleapps.ui.UseSmileIDSampleStrings
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.R
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleBottomSheet
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleIcon
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionLabel
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTextInput
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleContactRules
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserField
import androidx.compose.ui.platform.LocalAutofillManager

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
    val autofill = LocalAutofillManager.current
    val emailProblem = UseSmileIDSampleContactRules.problem(UseSmileIDSampleUserField.Email, email)
    val phoneProblem = UseSmileIDSampleContactRules.problem(UseSmileIDSampleUserField.Phone, phone)
    UseSmileIDSampleBottomSheet(
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        title = UseSmileIDSampleStrings.newProfileTitle,
        testId = UseSmileIDSampleTestIds.NEW_PROFILE_SHEET,
    ) {
        UseSmileIDSampleTextInput(
            value = name,
            onValueChange = onNameChange,
            placeholder = UseSmileIDSampleStrings.newProfileName,
            testId = UseSmileIDSampleTestIds.NEW_PROFILE_NAME,
            leading = { tint -> UseSmileIDSampleIcon(id = R.drawable.sample_ic_field_person, tint = tint) },
        )
        UseSmileIDSampleSectionLabel(text = UseSmileIDSampleStrings.newProfileSectionDetails)
        UseSmileIDSampleTextInput(
            value = firstName,
            onValueChange = onFirstNameChange,
            placeholder = UseSmileIDSampleStrings.userFieldFirstName,
            keyboardOptions = UseSmileIDSampleUserField.FirstName.keyboardOptions,
            testId = UseSmileIDSampleTestIds.NEW_PROFILE_FIRST_NAME,
            leading = { tint -> UseSmileIDSampleIcon(id = R.drawable.sample_ic_field_person, tint = tint) },
        )
        UseSmileIDSampleTextInput(
            value = lastName,
            onValueChange = onLastNameChange,
            placeholder = UseSmileIDSampleStrings.userFieldLastName,
            keyboardOptions = UseSmileIDSampleUserField.LastName.keyboardOptions,
            testId = UseSmileIDSampleTestIds.NEW_PROFILE_LAST_NAME,
            leading = { tint -> UseSmileIDSampleIcon(id = R.drawable.sample_ic_field_person, tint = tint) },
        )
        UseSmileIDSampleTextInput(
            value = email,
            onValueChange = onEmailChange,
            placeholder = UseSmileIDSampleStrings.userFieldEmailOptional,
            keyboardOptions = UseSmileIDSampleUserField.Email.keyboardOptions,
            isError = emailProblem != null,
            errorMessage = emailProblem?.let { stringResource(it) },
            testId = UseSmileIDSampleTestIds.NEW_PROFILE_EMAIL,
            leading = { tint -> UseSmileIDSampleIcon(id = R.drawable.sample_ic_field_email, tint = tint) },
        )
        UseSmileIDSampleTextInput(
            value = phone,
            onValueChange = onPhoneChange,
            placeholder = UseSmileIDSampleStrings.userFieldPhoneOptional,
            keyboardOptions = UseSmileIDSampleUserField.Phone.keyboardOptions,
            isError = phoneProblem != null,
            errorMessage = phoneProblem?.let { stringResource(it) },
            testId = UseSmileIDSampleTestIds.NEW_PROFILE_PHONE,
            leading = { tint -> UseSmileIDSampleIcon(id = R.drawable.sample_ic_field_phone, tint = tint) },
        )
        UseSmileIDSampleButton(
            text = UseSmileIDSampleStrings.newProfileCreate,
            onClick = {
                // Email and phone keyboards read as a sign-in form, so without this Android offers to save a password.
                autofill?.cancel()
                onSave()
            },
            enabled = name.isNotBlank() && firstName.isNotBlank() && lastName.isNotBlank() &&
                emailProblem == null && phoneProblem == null,
            testId = UseSmileIDSampleTestIds.NEW_PROFILE_SAVE,
        )
    }
}
