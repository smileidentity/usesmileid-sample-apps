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
import com.smileid.designsystem.smileCardStrokeWidth
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleButton
import com.usesmileid.sampleapps.ui.components.ChevronDownGlyph
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleKeyValueEditRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleProfileRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionSurface
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRowDivider
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSwitch
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBar
import androidx.compose.ui.graphics.Color
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleProfile
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleProfiles
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetailsRequirement
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserField
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The Consent Details Form, shown for every product. Sample-owned and ahead of the flow, which is why it needs no SDK change. */
@Composable
fun UserDetailsScreen(
    productLabel: String,
    details: UseSmileIDSampleUserDetails,
    /** Who this run is for; null while there is no profile, when the form offers to create one. */
    profile: UseSmileIDSampleProfile?,
    profileColor: Color,
    saveToProfile: Boolean,
    onFieldChange: (UseSmileIDSampleUserField, String) -> Unit,
    onSaveToProfileChange: (Boolean) -> Unit,
    onProfileClick: () -> Unit,
    onBack: () -> Unit,
    onContinue: () -> Unit,
    modifier: Modifier = Modifier,
    contentPadding: PaddingValues = PaddingValues(),
    /** What is still outstanding once the token's own bindings are taken off the SDK's rule. */
    requirement: UseSmileIDSampleUserDetailsRequirement = UseSmileIDSampleUserDetailsRequirement(),
    organisation: String = "",
    onOrganisationChange: (String) -> Unit = {},
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
                UseSmileIDSampleProfileRow(
                    organisation = profile?.title ?: UseSmileIDSampleProfiles.NO_PROFILE_LABEL,
                    supportingText = if (profile == null) "Your details below will create one" else "Tap to switch profile",
                    initials = profile?.initials.orEmpty(),
                    avatarColor = profileColor,
                    selected = false,
                    onClick = onProfileClick,
                    modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
                    testId = UseSmileIDSampleTestIds.USER_DETAILS_PROFILE,
                    trailing = { ChevronDownGlyph(tint = UseSmileIDSampleTheme.colors.textMuted) },
                )
            }
            item {
                UseSmileIDSampleSectionSurface(
                    modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
                    label = "YOUR DETAILS",
                ) {
                    if (profile == null) {
                        UseSmileIDSampleKeyValueEditRow(
                            label = "Profile name (optional)",
                            value = organisation,
                            onValueChange = onOrganisationChange,
                            placeholder = "Shown on the consent screen",
                            required = false,
                            testId = UseSmileIDSampleTestIds.userDetailsField(ORGANISATION_FIELD_ID),
                        )
                        UseSmileIDSampleSettingRowDivider()
                    }
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
            if (details.satisfies(requirement) && (profile == null || details != profile.defaults)) {
                item {
                    Surface(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = SmileDimens.spacingMd),
                        shape = RoundedCornerShape(SmileDimens.radiusSurface),
                        color = UseSmileIDSampleTheme.colors.surface,
                        border = BorderStroke(smileCardStrokeWidth, UseSmileIDSampleTheme.colors.cardStroke),
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
                                text = profile?.let { "Save to ${it.title}" } ?: "Save as a new profile",
                                style = UseSmileIDSampleTheme.type.textStyleSubtitle.copy(fontSize = REMEMBER_TEXT_SIZE),
                                color = UseSmileIDSampleTheme.colors.textBody,
                                modifier = Modifier.weight(1f),
                            )
                            UseSmileIDSampleSwitch(
                                checked = saveToProfile,
                                onCheckedChange = onSaveToProfileChange,
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

/** The organisation row's id suffix, beside the four user fields'. */
internal const val ORGANISATION_FIELD_ID = "organisation"
