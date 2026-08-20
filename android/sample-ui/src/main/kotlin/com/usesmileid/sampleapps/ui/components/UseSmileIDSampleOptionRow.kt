package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
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
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.sp
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** One row in the country or ID-type picker; country rows lead with a flag. Selected takes a pale fill as well as a check. */
@Composable
fun UseSmileIDSampleOptionRow(
    label: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    leadingText: String? = null,
    testId: String? = null,
) {
    val colors = UseSmileIDSampleTheme.colors
    Surface(
        modifier = modifier
            .fillMaxWidth()
            .selectable(selected = selected, role = Role.RadioButton, onClick = onClick)
            .tagged(testId),
        shape = RoundedCornerShape(SmileDimens.radiusField),
        // An unselected row is transparent over the sheet; only the selected one takes a fill.
        color = if (selected) UseSmileIDSampleTheme.colors.surfaceMuted else Color.Transparent,
    ) {
        Row(
            modifier = Modifier
                .defaultMinSize(minHeight = SmileDimens.sizeControlMd)
                .padding(horizontal = SmileDimens.spacingSm, vertical = SmileDimens.spacingXs),
            horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (leadingText != null) {
                Text(text = leadingText, style = UseSmileIDSampleTheme.type.textStyleBody.copy(fontSize = FLAG_SIZE))
            }
            Text(
                text = label,
                style = UseSmileIDSampleTheme.type.textStyleBodyStrong.copy(fontSize = OPTION_LABEL_SIZE),
                color = colors.textTitle,
                modifier = Modifier.weight(1f),
            )
            if (selected) {
                Box(modifier = Modifier.size(SmileDimens.sizeIconMd), contentAlignment = Alignment.Center) {
                    CheckGlyph(tint = colors.primary)
                }
            }
        }
    }
}

private val FLAG_SIZE = 19.sp
private val OPTION_LABEL_SIZE = 14.sp
