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
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.PlusGlyph
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleProfileRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionLabel
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBar
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleProfile

/** Every profile the app can act as. Tapping one configures it; switching happens on the sheet. */
@Composable
fun ProfilesScreen(
    profiles: List<UseSmileIDSampleProfile>,
    activeId: String,
    onProfileClick: (UseSmileIDSampleProfile) -> Unit,
    onCreate: () -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    contentPadding: PaddingValues = PaddingValues(),
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .testTag(UseSmileIDSampleTestIds.PROFILES_SCREEN),
    ) {
        UseSmileIDSampleTopAppBar(title = "Profiles", onBack = onBack)
        LazyColumn(
            contentPadding = contentPadding,
            verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
        ) {
            item {
                UseSmileIDSampleSectionLabel(
                    text = "PROFILES",
                    modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
                )
            }
            items(profiles) { profile ->
                UseSmileIDSampleProfileRow(
                    organisation = profile.organisation,
                    supportingText = profile.person,
                    initials = profile.initials,
                    selected = profile.id == activeId,
                    onClick = { onProfileClick(profile) },
                    modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
                    testId = UseSmileIDSampleTestIds.profileRow(profile.id),
                )
            }
            item {
                UseSmileIDSampleSettingRow(
                    title = "Create a profile",
                    supportingText = "Add another organisation",
                    onClick = onCreate,
                    modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
                    leading = { tint -> PlusGlyph(tint = tint) },
                    testId = UseSmileIDSampleTestIds.CREATE_PROFILE,
                )
            }
            item { Spacer(modifier = Modifier.height(SmileDimens.space64)) }
        }
    }
}

/** The profile-switch sheet. Selecting one switches immediately, which is why it needs no save action. */
@Composable
fun ProfileSwitchSheet(
    profiles: List<UseSmileIDSampleProfile>,
    activeId: String,
    onSelect: (UseSmileIDSampleProfile) -> Unit,
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
) {
    com.usesmileid.sampleapps.ui.components.UseSmileIDSampleBottomSheet(
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        title = "Switch profile",
        testId = UseSmileIDSampleTestIds.PROFILE_SWITCH_SHEET,
    ) {
        profiles.forEach { profile ->
            UseSmileIDSampleProfileRow(
                organisation = profile.organisation,
                supportingText = profile.person,
                initials = profile.initials,
                selected = profile.id == activeId,
                onClick = { onSelect(profile) },
                testId = UseSmileIDSampleTestIds.profileRow(profile.id),
            )
        }
    }
}

private fun androidx.compose.foundation.lazy.LazyListScope.items(
    profiles: List<UseSmileIDSampleProfile>,
    row: @Composable (UseSmileIDSampleProfile) -> Unit,
) = profiles.forEach { profile -> item(key = profile.id) { row(profile) } }
