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
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.ui.Alignment
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRowChevron
import androidx.compose.material3.Text
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.components.avatarColorForProfile
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
            items(profiles) { profile ->
                UseSmileIDSampleProfileRow(
                    avatarColor = avatarColorForProfile(profiles.indexOf(profile)),
                    organisation = profile.organisation,
                    // The design marks the active profile in its supporting line, not with a check.
                    supportingText = if (profile.id == activeId) profile.person + ACTIVE_SUFFIX else profile.person,
                    initials = profile.initials,
                    selected = false,
                    onClick = { onProfileClick(profile) },
                    modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
                    testId = UseSmileIDSampleTestIds.profileRow(profile.id),
                    trailing = { UseSmileIDSampleSettingRowChevron() },
                )
            }
            item {
                CreateProfileRow(
                    onClick = onCreate,
                    modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
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
                avatarColor = avatarColorForProfile(profiles.indexOf(profile)),
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

/**
 * The last row of the list: no card and no border, a pale primary tile with a plus. `primary-soft` has
 * no token of its own and resolves to the same value as the generated soft info ground.
 */
@Composable
private fun CreateProfileRow(onClick: () -> Unit, modifier: Modifier = Modifier) {
    val colors = UseSmileIDSampleTheme.colors
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable(role = Role.Button, onClick = onClick)
            .padding(horizontal = CREATE_PADDING_X, vertical = SmileDimens.spacingSm)
            .testTag(UseSmileIDSampleTestIds.CREATE_PROFILE),
        horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Surface(
            modifier = Modifier.size(SmileDimens.sizeControlMd),
            shape = RoundedCornerShape(CREATE_TILE_RADIUS),
            color = colors.badge.infoBackground,
        ) {
            Box(contentAlignment = Alignment.Center) {
                PlusGlyph(tint = colors.primary, size = SmileDimens.sizeIconMd)
            }
        }
        Column(verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs)) {
            Text(
                text = "Create new profile",
                style = UseSmileIDSampleTheme.type.textStyleBodyStrong.copy(fontSize = CREATE_TITLE_SIZE),
                color = colors.textTitle,
            )
            Text(
                text = "Its user details will live under it",
                style = UseSmileIDSampleTheme.type.textStyleCaption,
                color = colors.textMuted,
            )
        }
    }
}

/** The design appends this to the active profile's supporting line. */
private const val ACTIVE_SUFFIX = " \u00b7 active"

/** 14, 12 and 14.5 in the design; no token carries them. */
private val CREATE_PADDING_X = 14.dp
private val CREATE_TILE_RADIUS = 12.dp
private val CREATE_TITLE_SIZE = 14.5.sp
