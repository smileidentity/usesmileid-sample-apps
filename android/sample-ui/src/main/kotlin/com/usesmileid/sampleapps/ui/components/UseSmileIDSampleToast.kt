package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * A message, optionally with an action. The action is part of the contract rather than decoration —
 * it is the undo on the delete flow, and the flow asserts on it.
 *
 * Both ids are attached here rather than by the caller, because the spec assigns them to the toast
 * itself. The `elevation.floating` shadow token the contract names has no Compose equivalent in the
 * generated output — that emitter omits shadows entirely — so the pill is separated from the content
 * behind it by a hairline border instead.
 */
@Composable
fun UseSmileIDSampleToast(
    message: String,
    modifier: Modifier = Modifier,
    actionLabel: String? = null,
    onAction: (() -> Unit)? = null,
) {
    Surface(
        modifier = modifier
            .defaultMinSize(minHeight = SmileDimens.sizeControlMd)
            .testTag(UseSmileIDSampleTestIds.TOAST),
        shape = RoundedCornerShape(SmileDimens.radiusControl),
        color = UseSmileIDSampleTheme.colors.surfaceAlt,
        border = BorderStroke(SmileDimens.borderWidthHairline, UseSmileIDSampleTheme.colors.border),
    ) {
        // A FlowRow rather than a Row so a cramped action moves onto its own line whole. In a Row the
        // action is squeezed instead, and at the largest font scale "Undo" breaks across two lines.
        FlowRow(
            modifier = Modifier.padding(
                horizontal = SmileDimens.spacingMd,
                vertical = SmileDimens.spacingSm,
            ),
            horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
            verticalArrangement = Arrangement.spacedBy(SmileDimens.space4),
            itemVerticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = message,
                style = UseSmileIDSampleTheme.type.bannerTextFont,
                color = UseSmileIDSampleTheme.colors.textBody,
            )
            if (actionLabel != null && onAction != null) {
                Text(
                    text = actionLabel,
                    style = UseSmileIDSampleTheme.type.linkFont,
                    color = UseSmileIDSampleTheme.colors.textLink,
                    softWrap = false,
                    modifier = Modifier
                        .testTag(UseSmileIDSampleTestIds.TOAST_UNDO)
                        .clickable(role = Role.Button, onClick = onAction),
                )
            }
        }
    }
}
