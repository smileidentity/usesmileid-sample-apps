package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
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
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * A label/value pair on the verification-details card, optionally with a copy control.
 *
 * A [FlowRow] rather than a weighted [Row]: at 2x font scale a timestamp value cannot share a line
 * with its label, and wrapping it below is right where squeezing it into an ellipsis is not.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun UseSmileIDSampleDataFieldRow(
    label: String,
    value: String,
    modifier: Modifier = Modifier,
    testId: String? = null,
    onCopy: (() -> Unit)? = null,
    copyTestId: String? = null,
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
        FlowRow(
            modifier = Modifier.weight(1f),
            horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
            verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs),
        ) {
            Text(
                text = label,
                style = UseSmileIDSampleTheme.type.dataFieldLabelFont,
                color = UseSmileIDSampleTheme.colors.dataField.label,
            )
            Text(
                text = value,
                style = UseSmileIDSampleTheme.type.dataFieldValueFont,
                color = UseSmileIDSampleTheme.colors.dataField.value,
            )
        }
        if (onCopy != null) {
            CopyButton(label = label, onCopy = onCopy, testId = copyTestId)
        }
    }
}

@Composable
private fun CopyButton(label: String, onCopy: () -> Unit, testId: String?) {
    Surface(
        onClick = onCopy,
        // 24dp glyph; Material expands the touch target around it to the platform minimum.
        modifier = Modifier
            .size(SmileDimens.sizeIconLg)
            .semantics { contentDescription = "Copy $label" }
            .tagged(testId),
        shape = RoundedCornerShape(SmileDimens.radiusSm),
        color = UseSmileIDSampleTheme.colors.surfaceAlt,
    ) {
        Box(contentAlignment = Alignment.Center) {
            CopyGlyph(tint = UseSmileIDSampleTheme.colors.textMuted)
        }
    }
}
