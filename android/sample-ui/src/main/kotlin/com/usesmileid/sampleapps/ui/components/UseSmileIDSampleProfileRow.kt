package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** An organisation and a supporting line — the person on the switch sheet, "Tap to configure" in settings. Hue varies per profile, so the caller passes it. */
@Composable
fun UseSmileIDSampleProfileRow(
    organisation: String,
    supportingText: String,
    initials: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    avatarColor: Color = UseSmileIDSampleTheme.colors.avatar.background,
    testId: String? = null,
    trailing: @Composable (() -> Unit)? = null,
) {
    val colors = UseSmileIDSampleTheme.colors
    Surface(
        modifier = modifier
            .fillMaxWidth()
            .selectable(selected = selected, role = Role.RadioButton, onClick = onClick)
            .tagged(testId),
        shape = RoundedCornerShape(SmileDimens.radiusField),
        color = if (selected) colors.surfaceAlt else colors.surface,
    ) {
        Row(
            modifier = Modifier
                .defaultMinSize(minHeight = SmileDimens.space64)
                .padding(horizontal = SmileDimens.spacingSm, vertical = SmileDimens.spacingSm),
            horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            UseSmileIDSampleAvatar(
                initials = initials,
                size = SmileDimens.sizeControlMd,
                containerColor = avatarColor,
            )
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs),
            ) {
                Text(
                    text = organisation,
                    style = UseSmileIDSampleTheme.type.textStyleBodyStrong,
                    color = colors.textTitle,
                )
                Text(
                    text = supportingText,
                    style = UseSmileIDSampleTheme.type.textStyleBodySm,
                    color = colors.textMuted,
                )
            }
            if (trailing != null) {
                trailing()
            } else if (selected) {
                Box(modifier = Modifier.size(SmileDimens.sizeIconMd), contentAlignment = Alignment.Center) {
                    CheckGlyph(tint = colors.primary)
                }
            }
        }
    }
}
