package com.usesmileid.sampleapps.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Row
import androidx.compose.material3.HorizontalDivider
import androidx.compose.ui.unit.sp
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleKeyValueEditRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionLabel
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSwitch
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBar
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserField
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The Consent Details Form, shown for every product. Sample-owned and ahead of the flow, which is why it needs no SDK change. */
@Composable
fun UserDetailsScreen(
    productLabel: String,
    details: UseSmileIDSampleUserDetails,
    rememberDetails: Boolean,
    onFieldChange: (UseSmileIDSampleUserField, String) -> Unit,
    onRememberChange: (Boolean) -> Unit,
    onBack: () -> Unit,
    onContinue: () -> Unit,
    modifier: Modifier = Modifier,
    contentPadding: PaddingValues = PaddingValues(),
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .testTag(UseSmileIDSampleTestIds.USER_DETAILS_SCREEN),
    ) {
        UseSmileIDSampleTopAppBar(title = productLabel, onBack = onBack)
        LazyColumn(
            modifier = Modifier.weight(1f),
            contentPadding = contentPadding,
            verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
        ) {
            item {
                Column(
                    modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
                    verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                ) {
                    UseSmileIDSampleSectionLabel(text = "YOUR DETAILS")
                    Surface(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(SmileDimens.radiusSurface),
                        color = UseSmileIDSampleTheme.colors.surface,
                        border = BorderStroke(SmileDimens.borderWidthHairline, UseSmileIDSampleTheme.colors.card.border),
                    ) {
                        Column {
                            UseSmileIDSampleUserField.entries.forEachIndexed { index, field ->
                                // The design separates the rows with a rule rather than spacing them apart.
                                if (index > 0) {
                                    HorizontalDivider(
                                        thickness = SmileDimens.borderWidthHairline,
                                        color = UseSmileIDSampleTheme.colors.card.border,
                                    )
                                }
                                UseSmileIDSampleKeyValueEditRow(
                                    label = field.label,
                                    value = field.read(details),
                                    onValueChange = { onFieldChange(field, it) },
                                    placeholder = field.placeholder,
                                    required = field.required,
                                    testId = UseSmileIDSampleTestIds.userDetailsField(field.id),
                                )
                            }
                        }
                    }
                }
            }
            item {
                Text(
                    text = if (details.isComplete) "Tap any field to edit." else "First and last name are required.",
                    // Caption in the design (12/500), not the 14/400 small-body style.
                    style = UseSmileIDSampleTheme.type.textStyleCaption,
                    color = UseSmileIDSampleTheme.colors.textMuted,
                    modifier = Modifier
                        .testTag(UseSmileIDSampleTestIds.USER_DETAILS_HINT)
                        .padding(horizontal = SmileDimens.spacingMd),
                )
            }
            // Only once the details are worth remembering, which is how the design shows it.
            if (details.isComplete) {
                item {
                    Surface(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = SmileDimens.spacingMd),
                        shape = RoundedCornerShape(SmileDimens.radiusSurface),
                        color = UseSmileIDSampleTheme.colors.surface,
                        border = BorderStroke(SmileDimens.borderWidthHairline, UseSmileIDSampleTheme.colors.card.border),
                    ) {
                        // One line of body text beside the switch — the design gives this row no icon
                        // and no supporting line, so it is not a SettingRow.
                        Row(
                            modifier = Modifier.padding(
                                start = SmileDimens.spacingMd,
                                end = SmileDimens.spacingSm,
                                top = SmileDimens.spacingSm,
                                bottom = SmileDimens.spacingSm,
                            ),
                            horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(
                                text = "Remember these details for next time",
                                style = UseSmileIDSampleTheme.type.textStyleBody.copy(fontSize = REMEMBER_TEXT_SIZE),
                                color = UseSmileIDSampleTheme.colors.textBody,
                                modifier = Modifier.weight(1f),
                            )
                            UseSmileIDSampleSwitch(
                                checked = rememberDetails,
                                onCheckedChange = onRememberChange,
                                testId = UseSmileIDSampleTestIds.REMEMBER_DETAILS_SWITCH,
                            )
                        }
                    }
                }
            }
            item { Spacer(modifier = Modifier.height(SmileDimens.spacingLg)) }
        }
        UseSmileIDSampleButton(
            text = "Continue",
            onClick = onContinue,
            enabled = details.isComplete,
            modifier = Modifier.padding(SmileDimens.spacingMd),
            testId = UseSmileIDSampleTestIds.USER_DETAILS_CONTINUE,
        )
    }
}

/** 13.5 in the design. */
private val REMEMBER_TEXT_SIZE = 13.5.sp
