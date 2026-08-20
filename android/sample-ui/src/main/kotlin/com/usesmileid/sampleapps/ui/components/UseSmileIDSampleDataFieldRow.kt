package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
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
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.sp
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** A label/value pair on the verification-details card, optionally with a copy control. */
@Composable
fun UseSmileIDSampleDataFieldRow(
    label: String,
    value: String,
    modifier: Modifier = Modifier,
    testId: String? = null,
    onCopy: (() -> Unit)? = null,
    copyTestId: String? = null,
    /** Set only where the design colours the value, as the Status row's HTTP code is. */
    valueColor: Color? = null,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .defaultMinSize(minHeight = SmileDimens.space40)
            .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingSm)
            .tagged(testId),
        horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = label,
            style = UseSmileIDSampleTheme.type.dataFieldLabelFont.copy(fontSize = FIELD_TEXT_SIZE),
            color = UseSmileIDSampleTheme.colors.dataField.label,
        )
        // A column of its own, wrapping inside it: a FlowRow sent long values to a line below the label.
        Text(
            text = value,
            style = UseSmileIDSampleTheme.type.dataFieldValueFont.copy(
                fontSize = FIELD_TEXT_SIZE,
                fontWeight = if (valueColor == null) FontWeight.SemiBold else FontWeight.Bold,
            ),
            color = valueColor ?: UseSmileIDSampleTheme.colors.dataField.value,
            textAlign = TextAlign.End,
            modifier = Modifier.weight(1f),
        )
        if (onCopy != null) {
            CopyButton(label = label, onCopy = onCopy, testId = copyTestId)
        }
    }
}

@Composable
private fun CopyButton(label: String, onCopy: () -> Unit, testId: String?) {
    Surface(
        onClick = onCopy,
        modifier = Modifier
            .size(SmileDimens.sizeIconLg)
            .semantics { contentDescription = "Copy $label" }
            .tagged(testId),
        shape = RoundedCornerShape(SmileDimens.radiusSm),
        color = UseSmileIDSampleTheme.colors.surfaceTile,
    ) {
        Box(contentAlignment = Alignment.Center) {
            CopyGlyph(tint = UseSmileIDSampleTheme.colors.textMuted)
        }
    }
}

private val FIELD_TEXT_SIZE = 13.sp
