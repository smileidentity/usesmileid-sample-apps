package com.usesmileid.sampleapps.ui.screens

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
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserField

/** A profile's name and user-details defaults, which is what seeds the Consent Details Form for its jobs. */
@Composable
fun ProfileConfigScreen(
    organisation: String,
    defaults: UseSmileIDSampleUserDetails,
    name: String,
    onNameChange: (String) -> Unit,
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
    var confirmingDelete by rememberSaveable { mutableStateOf(false) }
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
            UseSmileIDSampleSectionLabel(text = "PROFILE")
            UseSmileIDSampleSectionSurface {
                UseSmileIDSampleKeyValueEditRow(
                    label = "Organisation",
                    value = name,
                    onValueChange = onNameChange,
                    placeholder = "Shown on the consent screen",
                    required = false,
                    testId = UseSmileIDSampleTestIds.PROFILE_CONFIG_NAME,
                )
            }
            // The label stays here: SECTION_GAP, not the component's own spacing, separates it from the card.
            UseSmileIDSampleSectionLabel(text = "USER DETAILS — ATTACHED TO EVERY JOB")
            UseSmileIDSampleSectionSurface {
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
            // Its own section, not a row in the card above: a webhook URL is not a user detail.
            UseSmileIDSampleSectionLabel(text = "CALLBACK URL")
            UseSmileIDSampleSectionSurface {
                UseSmileIDSampleKeyValueEditRow(
                    label = "Webhook URL",
                    value = if (callbackOverride == null) callbackUrl else "",
                    onValueChange = onCallbackUrlChange,
                    placeholder = callbackOverride ?: "Uses your portal default",
                    enabled = callbackOverride == null,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri),
                    testId = UseSmileIDSampleTestIds.PROFILE_CONFIG_CALLBACK_URL,
                )
            }
            if (onDelete != null) {
                UseSmileIDSampleDestructiveRow(
                    text = "Delete profile",
                    onClick = { confirmingDelete = true },
                    testId = UseSmileIDSampleTestIds.PROFILE_CONFIG_DELETE,
                )
            }
        }
        UseSmileIDSampleButton(
            // One slot, as the design has it: the active profile saves its edits, any other also becomes active.
            text = if (isActive) "Save changes" else "Use this profile",
            onClick = onSave,
            enabled = changed || !isActive,
            modifier = Modifier.padding(SmileDimens.spacingMd),
            testId = UseSmileIDSampleTestIds.PROFILE_CONFIG_SAVE,
        )
    }
    if (confirmingDelete && onDelete != null) {
        UseSmileIDSampleConfirmDialog(
            title = "Delete $organisation?",
            text = "Its details and callback URL are removed from this device.",
            confirmLabel = "Delete",
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
