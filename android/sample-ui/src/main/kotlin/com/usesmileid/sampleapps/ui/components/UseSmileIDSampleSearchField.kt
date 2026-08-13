package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * The sheet search field: a magnifier, then the query. `search.gap` sits between the two.
 *
 * The glyph is drawn rather than imported — `material-icons` is not on this module's classpath and
 * a whole icon dependency for one magnifier is not worth it.
 */
@Composable
fun UseSmileIDSampleSearchField(
    query: String,
    onQueryChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    placeholder: String = "",
    testId: String? = null,
) {
    val interactionSource = remember { MutableInteractionSource() }
    val focused by interactionSource.collectIsFocusedAsState()
    val colors = UseSmileIDSampleTheme.colors

    Row(
        modifier = modifier
            .fillMaxWidth()
            .defaultMinSize(minHeight = SmileDimens.sizeControlMd)
            .background(
                color = colors.search.background,
                shape = RoundedCornerShape(SmileDimens.radiusField),
            )
            .border(
                width = if (focused) SmileDimens.borderWidthThin else SmileDimens.borderWidthHairline,
                color = if (focused) colors.search.borderFocus else colors.search.border,
                shape = RoundedCornerShape(SmileDimens.radiusField),
            )
            .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingSm),
        horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        MagnifierGlyph(tint = colors.search.icon)
        Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.CenterStart) {
            if (query.isEmpty()) {
                Text(
                    text = placeholder,
                    style = UseSmileIDSampleTheme.type.searchFont,
                    color = colors.search.placeholder,
                )
            }
            BasicTextField(
                value = query,
                onValueChange = onQueryChange,
                singleLine = true,
                interactionSource = interactionSource,
                textStyle = UseSmileIDSampleTheme.type.searchFont.copy(color = colors.search.text),
                cursorBrush = SolidColor(colors.search.borderFocus),
                modifier = Modifier
                    .fillMaxWidth()
                    .tagged(testId),
            )
        }
    }
}

@Composable
private fun MagnifierGlyph(tint: Color) {
    Canvas(modifier = Modifier.size(SmileDimens.sizeIconMd)) {
        val stroke = Stroke(width = 1.5.dp.toPx(), cap = StrokeCap.Round)
        val radius = size.minDimension * 0.32f
        val centre = Offset(radius + stroke.width, radius + stroke.width)
        drawCircle(color = tint, radius = radius, center = centre, style = stroke)
        drawLine(
            color = tint,
            start = Offset(centre.x + radius * 0.7f, centre.y + radius * 0.7f),
            end = Offset(size.width - stroke.width, size.height - stroke.width),
            strokeWidth = stroke.width,
            cap = StrokeCap.Round,
        )
    }
}
