package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
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
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
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
        // A Row at the design's scale keeps the badge inline; a FlowRow above it lets the badge drop.
        // One layout cannot do both: weight() inside a FlowRow claims the whole line.
        val stacks = LocalDensity.current.fontScale > 1f
        val padding = Modifier
            .defaultMinSize(minHeight = SmileDimens.space64)
            .padding(SmileDimens.spacingSm)
        if (stacks) {
            FlowRow(
                modifier = padding,
                horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                itemVerticalAlignment = Alignment.CenterVertically,
            ) {
                JobRowTile(product = product)
                JobRowText(product = product, jobId = jobId, time = time, stacks = true)
                UseSmileIDSampleStatusBadge(status = status, testId = statusTestId)
            }
        } else {
            Row(
                modifier = padding,
                horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                JobRowTile(product = product)
                JobRowText(
                    product = product,
                    jobId = jobId,
                    time = time,
                    stacks = false,
                    modifier = Modifier.weight(1f),
                )
                UseSmileIDSampleStatusBadge(status = status, testId = statusTestId)
            }
        }
    }
}

@Composable
private fun JobRowTile(product: UseSmileIDSampleProduct) {
    val hue = product.hue
    Surface(
        modifier = Modifier.size(TILE_SIZE),
        shape = RoundedCornerShape(TILE_RADIUS),
        color = hue.tile,
    ) {
        Box(contentAlignment = Alignment.Center) {
            val icon = product.iconRes
            if (icon != null) {
                UseSmileIDSampleIcon(id = icon, tint = hue.icon, size = TILE_ICON_SIZE)
            } else {
                ProductMarkGlyph(tint = hue.icon)
            }
        }
    }
}

@Composable
private fun JobRowText(
    product: UseSmileIDSampleProduct,
    jobId: String,
    time: String,
    stacks: Boolean,
    modifier: Modifier = Modifier,
) {
    val colors = UseSmileIDSampleTheme.colors
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs)) {
        Text(
            text = product.label,
            style = UseSmileIDSampleTheme.type.textStyleBodyStrong,
            color = colors.card.title,
            // One line at the design's scale; enlarged type wraps, because eliding it would clip.
            maxLines = if (stacks) Int.MAX_VALUE else 1,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            text = "$jobId · $time",
            style = UseSmileIDSampleTheme.type.textStyleBodySm,
            color = colors.textMuted,
            // Ellipsised like the title, so every row is the same height at the design's scale.
            maxLines = if (stacks) Int.MAX_VALUE else 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

private val TILE_SIZE = 36.dp
private val TILE_RADIUS = 10.dp
private val TILE_ICON_SIZE = 18.dp
