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
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * Replaces the nav bar in select mode: the running count, a hint that changes with it, and Remove.
 *
 * The count is exposed as its own text node so a flow asserts equality rather than parsing prose.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun UseSmileIDSampleSelectionBar(
    selectedCount: Int,
    onRemove: () -> Unit,
    modifier: Modifier = Modifier,
    testId: String? = null,
    countTestId: String? = null,
    removeTestId: String? = null,
) {
    val colors = UseSmileIDSampleTheme.colors
    Surface(
        modifier = modifier.fillMaxWidth().tagged(testId),
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
                    style = UseSmileIDSampleTheme.type.textStyleBodyStrong,
                    color = colors.textTitle,
                    modifier = Modifier.tagged(countTestId),
                )
                Text(
                    text = if (selectedCount == 0) "Tap rows to select" else "Tap Remove to confirm",
                    style = UseSmileIDSampleTheme.type.textStyleBodySm,
                    color = colors.textMuted,
                )
            }
            RemoveAction(
                enabled = selectedCount > 0,
                onRemove = onRemove,
                testId = removeTestId,
            )
        }
    }
}

/**
 * The design fills this pill with a soft red and keeps the label red. Those soft variants are the
 * ones still pending in the design system, and the saturated `badge.error.*` pair draws red on red —
 * an invisible label. So it takes the saturated fill with its own on-colour, the same stopgap
 * [UseSmileIDSampleStatusBadge] ships, until the soft variants land.
 */
@Composable
private fun RemoveAction(enabled: Boolean, onRemove: () -> Unit, testId: String?) {
    val colors = UseSmileIDSampleTheme.colors
    val tint = if (enabled) colors.onError else colors.textMuted
    Surface(
        onClick = onRemove,
        enabled = enabled,
        modifier = Modifier
            .semantics { role = Role.Button }
            .tagged(testId),
        shape = RoundedCornerShape(SmileDimens.radiusControl),
        color = if (enabled) colors.errorFill else colors.surfaceMuted,
    ) {
        Row(
            modifier = Modifier
                .defaultMinSize(minHeight = SmileDimens.space40)
                .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingXs),
            horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(modifier = Modifier.size(SmileDimens.sizeIconMd), contentAlignment = Alignment.Center) {
                TrashGlyph(tint = tint)
            }
            Text(
                text = "Remove",
                style = UseSmileIDSampleTheme.type.textStyleBodyStrong,
                color = tint,
            )
        }
    }
}
