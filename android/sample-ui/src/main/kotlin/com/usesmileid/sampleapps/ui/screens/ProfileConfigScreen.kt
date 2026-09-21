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
    callbackUrl: String = "",
    onCallbackUrlChange: (String) -> Unit = {},
    /** Non-null while a token session is live: its text replaces the value, and the row stops editing. */
    callbackOverride: String? = null,
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
