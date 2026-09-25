package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleBottomSheet
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleProfileRow
import com.usesmileid.sampleapps.ui.components.avatarColorForProfile
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleProfile

/** The profile-switch sheet. Selecting one switches immediately, which is why it needs no save action. */
@Composable
fun ProfileSwitchSheet(
    profiles: List<UseSmileIDSampleProfile>,
    activeId: String?,
    onSelect: (UseSmileIDSampleProfile) -> Unit,
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
    /** Null hides the row, for a host that offers no way to create one. */
    onCreate: (() -> Unit)? = null,
) {
    UseSmileIDSampleBottomSheet(
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        title = "Switch profile",
        testId = UseSmileIDSampleTestIds.PROFILE_SWITCH_SHEET,
    ) {
        profiles.forEachIndexed { index, profile ->
            UseSmileIDSampleProfileRow(
                avatarColor = avatarColorForProfile(index),
                organisation = profile.title,
                supportingText = profile.caption,
                initials = profile.initials,
                selected = profile.id == activeId,
                onClick = { onSelect(profile) },
                testId = UseSmileIDSampleTestIds.profileRow(profile.id),
            )
        }
        if (onCreate != null) {
            UseSmileIDSampleProfileRow(
                organisation = "New profile",
                supportingText = "Run jobs as someone else",
                initials = "",
                selected = false,
                onClick = onCreate,
                testId = UseSmileIDSampleTestIds.PROFILE_SWITCH_NEW,
            )
        }
    }
}
