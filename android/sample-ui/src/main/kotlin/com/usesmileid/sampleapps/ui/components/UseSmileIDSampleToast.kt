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
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextAlign
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** A message with an optional action. Both ids are attached here because the spec assigns them to the toast itself; `elevation.floating` has no Compose equivalent, so a hairline border separates the pill. */
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
        // FlowRow so a cramped action moves onto its own line whole; a Row breaks "Undo" in half.
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
                    textAlign = TextAlign.Center,
                    // clickable before the sizing modifiers, so the tap target is the padded box and
                    // not the ~20dp line box the link text would otherwise occupy.
                    modifier = Modifier
                        .testTag(UseSmileIDSampleTestIds.TOAST_UNDO)
                        .clickable(role = Role.Button, onClick = onAction)
                        .minimumInteractiveComponentSize()
                        .padding(horizontal = SmileDimens.spacingXs),
                )
            }
        }
    }
}
