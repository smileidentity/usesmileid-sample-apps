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
import androidx.compose.ui.unit.sp
import com.smileid.designsystem.SmileDimens
import com.smileid.designsystem.smileCardStrokeColor
import com.smileid.designsystem.smileCardStrokeWidth
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleKeyValueEditRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionSurface
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRowDivider
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSwitch
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBar
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetailsRequirement
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
    /** What is still outstanding once the token's own bindings are taken off the SDK's rule. */
    requirement: UseSmileIDSampleUserDetailsRequirement = UseSmileIDSampleUserDetailsRequirement(),
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
                UseSmileIDSampleSectionSurface(
                    modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
                    label = "YOUR DETAILS",
                ) {
                    UseSmileIDSampleUserField.entries.forEachIndexed { index, field ->
                        if (index > 0) UseSmileIDSampleSettingRowDivider()
                        // Shown as provided, not asked again — the value is vaulted, so it
                        // cannot be prefilled either.
                        val supplied = requirement.supplies(field)
                        UseSmileIDSampleKeyValueEditRow(
                            label = requirement.labelFor(field),
                            value = if (supplied) "" else field.read(details),
                            onValueChange = { onFieldChange(field, it) },
                            placeholder = if (supplied) "Provided by token" else field.placeholder,
                            required = false,
                            enabled = !supplied,
                            testId = UseSmileIDSampleTestIds.userDetailsField(field.id),
                        )
                    }
                }
            }
            item {
                Text(
                    text = if (details.satisfies(requirement)) "Tap any field to edit." else requirement.prompt,
                    style = UseSmileIDSampleTheme.type.textStyleCaption,
                    color = UseSmileIDSampleTheme.colors.textMuted,
                    modifier = Modifier
                        .testTag(UseSmileIDSampleTestIds.USER_DETAILS_HINT)
                        .padding(horizontal = SmileDimens.spacingMd),
                )
            }
            // Only once the details are worth remembering, which is how the design shows it.
            if (details.satisfies(requirement)) {
                item {
                    Surface(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = SmileDimens.spacingMd),
                        shape = RoundedCornerShape(SmileDimens.radiusSurface),
                        color = UseSmileIDSampleTheme.colors.surface,
                        border = BorderStroke(smileCardStrokeWidth, smileCardStrokeColor),
                    ) {
                        // One line of body text beside the switch: no icon and no supporting line, so not a SettingRow.
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
                                style = UseSmileIDSampleTheme.type.textStyleSubtitle.copy(fontSize = REMEMBER_TEXT_SIZE),
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
            enabled = details.satisfies(requirement),
            modifier = Modifier.padding(SmileDimens.spacingMd),
            testId = UseSmileIDSampleTestIds.USER_DETAILS_CONTINUE,
        )
    }
}

private val REMEMBER_TEXT_SIZE = 13.5.sp
