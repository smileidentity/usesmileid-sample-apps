package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** A status filter with its live count. The count is a separate node, because it is what a delete is asserted on. */
@Composable
fun UseSmileIDSampleFilterChip(
    label: String,
    count: Int,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    testId: String? = null,
    countTestId: String? = null,
) {
    val colors = UseSmileIDSampleTheme.colors
    Surface(
        modifier = modifier
            .minimumInteractiveComponentSize()
            .selectable(selected = selected, role = Role.Tab, onClick = onClick)
            .tagged(testId),
        shape = RoundedCornerShape(SmileDimens.radiusChip),
        color = if (selected) colors.primary else colors.filterChip.background,
        border = if (selected) null else BorderStroke(SmileDimens.borderWidthHairline, colors.filterChip.border),
    ) {
        Row(
            modifier = Modifier
                .defaultMinSize(minHeight = SmileDimens.space32)
                .padding(horizontal = SmileDimens.spacingSm, vertical = SmileDimens.spacingXs),
            horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = label,
                style = UseSmileIDSampleTheme.type.filterChipFont,
                color = if (selected) colors.onPrimary else colors.filterChip.label,
            )
            Text(
                text = count.toString(),
                style = UseSmileIDSampleTheme.type.textStyleCaption,
                color = if (selected) colors.onPrimary else colors.filterChip.value,
                modifier = Modifier.tagged(countTestId),
            )
        }
    }
}
