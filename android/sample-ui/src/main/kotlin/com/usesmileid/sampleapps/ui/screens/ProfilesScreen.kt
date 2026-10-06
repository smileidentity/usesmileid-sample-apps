package com.usesmileid.sampleapps.ui.screens

import com.usesmileid.sampleapps.ui.UseSmileIDSampleStrings
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
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
    activeId: String?,
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
        UseSmileIDSampleTopAppBar(title = UseSmileIDSampleStrings.profilesTitle, onBack = onBack)
        LazyColumn(
            contentPadding = contentPadding,
            verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
        ) {
            itemsIndexed(profiles, key = { _, profile -> profile.id }) { index, profile ->
                UseSmileIDSampleProfileRow(
                    avatarColor = avatarColorForProfile(index),
                    organisation = profile.title,
                    supportingText = if (profile.id == activeId) profile.caption + UseSmileIDSampleStrings.profilesActiveSuffix else profile.caption,
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
        }
    }
}

/** The last row: no card and no border, a pale primary tile with a plus. */
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
                text = UseSmileIDSampleStrings.profilesCreate,
                style = UseSmileIDSampleTheme.type.textStyleBodyStrong.copy(fontSize = CREATE_TITLE_SIZE),
                color = colors.textTitle,
            )
            Text(
                text = UseSmileIDSampleStrings.profilesCreateHint,
                style = UseSmileIDSampleTheme.type.textStyleCaption,
                color = colors.textMuted,
            )
        }
    }
}

private val CREATE_PADDING_X = 14.dp
private val CREATE_TILE_RADIUS = 12.dp
private val CREATE_TITLE_SIZE = 14.5.sp
