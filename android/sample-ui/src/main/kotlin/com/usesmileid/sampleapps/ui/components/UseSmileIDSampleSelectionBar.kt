package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** Replaces the nav bar in select mode. The count is its own node, so a flow asserts equality rather than parsing prose. */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun UseSmileIDSampleSelectionBar(
    selectedCount: Int,
    onRemove: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = UseSmileIDSampleTheme.colors
    val edge = colors.border
    Surface(
        modifier = modifier
            .fillMaxWidth()
            .testTag(UseSmileIDSampleTestIds.SELECTION_BAR)
            // A top edge only, so a Surface border is wrong — that would outline all four sides.
            .drawBehind {
                val stroke = EDGE_WIDTH.toPx()
                drawLine(edge, Offset(0f, stroke / 2f), Offset(size.width, stroke / 2f), stroke)
            },
        color = colors.surface,
    ) {
        FlowRow(
            modifier = Modifier
                .fillMaxWidth()
                .windowInsetsPadding(WindowInsets.navigationBars)
                .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingSm),
            horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
            verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
            itemVerticalAlignment = Alignment.CenterVertically,
        ) {
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs),
            ) {
                Text(
                        text = "$selectedCount selected",
                    style = UseSmileIDSampleTheme.type.textStyleBodyStrong.copy(
                        fontSize = COUNT_SIZE,
                        fontWeight = FontWeight.Bold,
                    ),
                    color = colors.textTitle,
                    modifier = Modifier.testTag(UseSmileIDSampleTestIds.SELECTION_COUNT),
                )
                Text(
                    text = if (selectedCount == 0) "Tap rows to select" else "Tap \"Hide from List\" to confirm",
                    style = UseSmileIDSampleTheme.type.textStyleBodySm.copy(fontSize = HINT_SIZE),
                    color = colors.textMuted,
                )
            }
            RemoveAction(enabled = selectedCount > 0, onRemove = onRemove)
        }
    }
}

/** The soft error pair, dimmed rather than recoloured when disabled, so a disabled action still reads as the strong one. */
@Composable
private fun RemoveAction(enabled: Boolean, onRemove: () -> Unit) {
    val colors = UseSmileIDSampleTheme.colors
    Surface(
        onClick = onRemove,
        enabled = enabled,
        modifier = Modifier
            .semantics { role = Role.Button }
            .testTag(UseSmileIDSampleTestIds.SELECTION_REMOVE)
            .alpha(if (enabled) 1f else DISABLED_ALPHA),
        shape = RoundedCornerShape(SmileDimens.radiusControl),
        color = colors.badge.errorBackground,
    ) {
        Row(
            modifier = Modifier
                .defaultMinSize(minHeight = SmileDimens.space40)
                .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingXs),
            horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(modifier = Modifier.size(SmileDimens.sizeIconSm), contentAlignment = Alignment.Center) {
                TrashGlyph(tint = colors.badge.errorText)
            }
            Text(
                text = "Hide from List",
                style = UseSmileIDSampleTheme.type.textStyleBodyStrong.copy(
                    fontSize = REMOVE_SIZE,
                    fontWeight = FontWeight.Bold,
                ),
                color = colors.badge.errorText,
            )
        }
    }
}

private val COUNT_SIZE = 14.sp
private val HINT_SIZE = 11.5.sp
private val REMOVE_SIZE = 13.5.sp
private val EDGE_WIDTH = SmileDimens.borderWidthHairline
private const val DISABLED_ALPHA = 0.45f
