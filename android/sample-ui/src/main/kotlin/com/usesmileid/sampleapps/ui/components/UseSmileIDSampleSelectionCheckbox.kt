package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.selection.toggleable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Surface
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp
import com.smileid.designsystem.SmileDimens
import com.smileid.designsystem.smileBorderStrong
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The select-mode checkbox. Circular rather than a rounded square, which is the design's correction. */
@Composable
fun UseSmileIDSampleSelectionCheckbox(
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
    testId: String? = null,
) {
    val colors = UseSmileIDSampleTheme.colors
    Box(
        modifier = modifier
            .minimumInteractiveComponentSize()
            .toggleable(value = checked, role = Role.Checkbox, onValueChange = onCheckedChange)
            .tagged(testId),
        contentAlignment = Alignment.Center,
    ) {
        Surface(
            modifier = Modifier
                .size(SmileDimens.sizeIconLg)
                .border(
                    // A 2px ring in border-strong: color.border is far too pale to read as a control.
                    width = SmileDimens.borderWidthThick,
                    color = if (checked) colors.primary else smileBorderStrong,
                    shape = CircleShape,
                ),
            shape = CircleShape,
            color = if (checked) colors.primary else colors.surface,
        ) {
            Box(contentAlignment = Alignment.Center) {
                if (checked) CheckGlyph(tint = colors.onPrimary, size = CHECK_SIZE)
            }
        }
    }
}

private val CHECK_SIZE = 11.dp
