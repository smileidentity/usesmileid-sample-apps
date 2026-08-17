package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * One verification: a product tile, its name, a secondary line of job id and time, and the status badge.
 *
 * Select mode's checkbox is not a slot — the design puts it beside the card, and inside it cost the title width.
 *
 * @param statusTestId defaulted rather than attached by the caller; a list screen overrides it with the row's suffix.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun UseSmileIDSampleJobRow(
    product: UseSmileIDSampleProduct,
    jobId: String,
    time: String,
    status: UseSmileIDSampleStatus,
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null,
    testId: String? = null,
    statusTestId: String? = UseSmileIDSampleTestIds.JOB_ROW_STATUS,
) {
    val colors = UseSmileIDSampleTheme.colors
    Surface(
        modifier = modifier
            .fillMaxWidth()
            .then(if (onClick != null) Modifier.clickable(role = Role.Button, onClick = onClick) else Modifier)
            .tagged(testId),
        shape = RoundedCornerShape(SmileDimens.radiusSurface),
        color = colors.card.background,
        border = BorderStroke(SmileDimens.borderWidthHairline, colors.card.border),
    ) {
        // FlowRow so the badge drops below the title at 2x rather than ellipsising the name.
        FlowRow(
            modifier = Modifier
                .defaultMinSize(minHeight = SmileDimens.space64)
                .padding(SmileDimens.spacingSm),
            horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
            verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
            itemVerticalAlignment = Alignment.CenterVertically,
        ) {
            val hue = product.hue
            Surface(
                modifier = Modifier.size(SmileDimens.space40),
                shape = RoundedCornerShape(SmileDimens.radiusSm),
                color = hue.from.copy(alpha = TILE_TINT_ALPHA),
            ) {
                Box(contentAlignment = Alignment.Center) {
                    val icon = product.iconRes
                    if (icon != null) {
                        UseSmileIDSampleIcon(id = icon, tint = hue.icon)
                    } else {
                        ProductMarkGlyph(tint = hue.icon)
                    }
                }
            }
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs),
            ) {
                Text(
                    text = product.label,
                    style = UseSmileIDSampleTheme.type.textStyleBodyStrong,
                    color = colors.card.title,
                )
                Text(
                    text = "$jobId · $time",
                    style = UseSmileIDSampleTheme.type.textStyleBodySm,
                    color = colors.textMuted,
                )
            }
            UseSmileIDSampleStatusBadge(status = status, testId = statusTestId)
        }
    }
}

private const val TILE_TINT_ALPHA = 0.16f
