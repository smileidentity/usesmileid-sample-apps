package com.usesmileid.sampleapps.ui.screens

import androidx.compose.ui.res.stringResource
import com.usesmileid.sampleapps.ui.UseSmileIDSampleStrings
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleConfirmDialog
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleDestructiveRow
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.input.KeyboardType
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRowDivider
import androidx.compose.ui.unit.dp
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleKeyValueEditRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionLabel
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionSurface
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBar
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleContactRules
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserField
import androidx.compose.ui.platform.LocalAutofillManager

/** A profile's name and user-details defaults, which is what seeds the Consent Details Form for its jobs. */
@Composable
fun ProfileConfigScreen(
    /** The saved profile's name, so the bar does not change as the organisation is typed. */
    title: String,
    defaults: UseSmileIDSampleUserDetails,
    organisation: String,
    onOrganisationChange: (String) -> Unit,
    onFieldChange: (UseSmileIDSampleUserField, String) -> Unit,
    onBack: () -> Unit,
    onSave: () -> Unit,
    modifier: Modifier = Modifier,
    isActive: Boolean = false,
    /** Whether anything differs from what is stored, which is all the active profile's Save can act on. */
    changed: Boolean = false,
    callbackUrl: String = "",
    onCallbackUrlChange: (String) -> Unit = {},
    /** Non-null while a token session is live: its text replaces the value, and the row stops editing. */
    callbackOverride: String? = null,
    contentPadding: PaddingValues = PaddingValues(),
    /** Null hides the row, for a host that offers no delete. */
    onDelete: (() -> Unit)? = null,
) {
    val autofill = LocalAutofillManager.current
    var confirmingDelete by rememberSaveable { mutableStateOf(false) }
    Column(
        modifier = modifier
            .fillMaxSize()
            .testTag(UseSmileIDSampleTestIds.PROFILE_CONFIG_SCREEN),
    ) {
        UseSmileIDSampleTopAppBar(title = title, onBack = onBack)
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(contentPadding)
                .padding(horizontal = SmileDimens.spacingMd),
            verticalArrangement = Arrangement.spacedBy(SECTION_GAP),
        ) {
            UseSmileIDSampleSectionLabel(text = UseSmileIDSampleStrings.profileConfigSectionProfile)
            UseSmileIDSampleSectionSurface {
                UseSmileIDSampleKeyValueEditRow(
                    label = UseSmileIDSampleStrings.profileConfigName,
                    value = organisation,
                    onValueChange = onOrganisationChange,
                    placeholder = UseSmileIDSampleStrings.profileConfigNameHint,
                    required = false,
                    testId = UseSmileIDSampleTestIds.PROFILE_CONFIG_NAME,
                )
            }
            // The label stays here: SECTION_GAP, not the component's own spacing, separates it from the card.
            UseSmileIDSampleSectionLabel(text = UseSmileIDSampleStrings.profileConfigSectionDetails)
            UseSmileIDSampleSectionSurface {
                UseSmileIDSampleUserField.entries.forEachIndexed { index, field ->
                    if (index > 0) UseSmileIDSampleSettingRowDivider()
                    UseSmileIDSampleKeyValueEditRow(
                        label = stringResource(field.label),
                        value = field.read(defaults),
                        onValueChange = { onFieldChange(field, it) },
                        placeholder = stringResource(field.placeholder),
                        required = field.required,
                        keyboardOptions = field.keyboardOptions,
                        isError = UseSmileIDSampleContactRules.problem(field, field.read(defaults)) != null,
                        testId = UseSmileIDSampleTestIds.profileConfigField(field.id),
                    )
                }
            }
            defaults.contactProblem?.let { problem ->
                Text(
                    text = stringResource(problem),
                    style = UseSmileIDSampleTheme.type.textStyleCaption,
                    color = UseSmileIDSampleTheme.colors.input.borderError,
                    modifier = Modifier.testTag(UseSmileIDSampleTestIds.PROFILE_CONFIG_CONTACT_ERROR),
                )
            }
            // Its own section, not a row in the card above: a webhook URL is not a user detail.
            UseSmileIDSampleSectionLabel(text = UseSmileIDSampleStrings.profileConfigSectionCallback)
            UseSmileIDSampleSectionSurface {
                UseSmileIDSampleKeyValueEditRow(
                    label = UseSmileIDSampleStrings.profileConfigCallbackLabel,
                    value = if (callbackOverride == null) callbackUrl else "",
                    onValueChange = onCallbackUrlChange,
                    placeholder = callbackOverride ?: UseSmileIDSampleStrings.profileConfigCallbackHint,
                    enabled = callbackOverride == null,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri),
                    testId = UseSmileIDSampleTestIds.PROFILE_CONFIG_CALLBACK_URL,
                )
            }
            if (onDelete != null) {
                UseSmileIDSampleDestructiveRow(
                    text = UseSmileIDSampleStrings.profileConfigDelete,
                    onClick = { confirmingDelete = true },
                    testId = UseSmileIDSampleTestIds.PROFILE_CONFIG_DELETE,
                )
            }
        }
        UseSmileIDSampleButton(
            text = if (isActive) UseSmileIDSampleStrings.profileConfigSave else UseSmileIDSampleStrings.profileConfigUse,
            onClick = {
                autofill?.cancel()
                onSave()
            },
            enabled = (changed || !isActive) && defaults.contactProblem == null,
            modifier = Modifier.padding(SmileDimens.spacingMd),
            testId = UseSmileIDSampleTestIds.PROFILE_CONFIG_SAVE,
        )
    }
    if (confirmingDelete && onDelete != null) {
        UseSmileIDSampleConfirmDialog(
            title = UseSmileIDSampleStrings.profileConfigDeleteTitle(title),
            text = UseSmileIDSampleStrings.profileConfigDeleteBody,
            confirmLabel = UseSmileIDSampleStrings.commonDelete,
            confirmTestId = UseSmileIDSampleTestIds.PROFILE_DELETE_CONFIRM,
            onConfirm = {
                confirmingDelete = false
                onDelete()
            },
            onDismissRequest = { confirmingDelete = false },
        )
    }
}

/** The design's gap between the header, the label, the card and the CTA. */
private val SECTION_GAP = 14.dp
