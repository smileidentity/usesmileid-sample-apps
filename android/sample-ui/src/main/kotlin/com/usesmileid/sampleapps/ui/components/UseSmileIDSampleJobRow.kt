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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * One verification in the list: a tinted product tile, the product name, a secondary line carrying
 * the truncated job id and time, and the status badge.
 *
 * The secondary line is the design's own correction — a row is not title-plus-badge, and the job id
 * is what a flow reads to identify the row.
 *
 * A [FlowRow] holds the text block and the badge so the badge drops below the title at 2x rather
 * than squeezing the product name into an ellipsis.
 *
 * Select mode's checkbox is deliberately not a slot here: the design puts it *beside* the card and
 * narrows the card to suit, so the screen composes a row of checkbox plus this. Holding it inside
 * cost the title enough width to wrap at default scale on a 393dp screen.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun UseSmileIDSampleJobRow(
    product: String,
    jobId: String,
    time: String,
    status: UseSmileIDSampleStatus,
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null,
    tileColor: Color = UseSmileIDSampleTheme.colors.surfaceAlt,
    testId: String? = null,
    // Defaulted rather than attached outright: the badge sits inside a repeated row, so a list
    // screen overrides it with the row's suffix instead of tagging every badge the same.
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
        FlowRow(
            modifier = Modifier
                .defaultMinSize(minHeight = SmileDimens.space64)
                .padding(SmileDimens.spacingSm),
            horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
            verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
            itemVerticalAlignment = Alignment.CenterVertically,
        ) {
            Surface(
                modifier = Modifier.size(SmileDimens.space40),
                shape = RoundedCornerShape(SmileDimens.radiusSm),
                color = tileColor,
            ) {
                Box(contentAlignment = Alignment.Center) {
                    ProductMarkGlyph(tint = colors.textTitle)
                }
            }
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs),
            ) {
                // Neither line caps its line count: the caller already elides the job id, and a row
                // that ellipsises the product name at 2x is the clipping the predicate forbids.
                Text(
                    text = product,
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
