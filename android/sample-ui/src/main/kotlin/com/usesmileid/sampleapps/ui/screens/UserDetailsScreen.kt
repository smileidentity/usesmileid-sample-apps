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
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.ProductMarkGlyph
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleKeyValueEditRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionLabel
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRow
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
                    ) {
                        Column {
                            UseSmileIDSampleUserField.entries.forEach { field ->
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
                    style = UseSmileIDSampleTheme.type.textStyleBodySm,
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
                    ) {
                        UseSmileIDSampleSettingRow(
                            title = "Remember these details",
                            supportingText = "Reuse them on the next job",
                            leading = { tint -> ProductMarkGlyph(tint = tint) },
                            trailing = {
                                UseSmileIDSampleSwitch(
                                    checked = rememberDetails,
                                    onCheckedChange = onRememberChange,
                                    testId = UseSmileIDSampleTestIds.REMEMBER_DETAILS_SWITCH,
                                )
                            },
                        )
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
