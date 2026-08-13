package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.SolidColor
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * A label and a value that edits in place, for the Consent Details Form and the profile defaults.
 *
 * Tapping the value edits it with a caret rather than pushing a form, so the row owns a text field
 * and not a click target. Empty shows the placeholder in muted; filled takes the title colour.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun UseSmileIDSampleKeyValueEditRow(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    placeholder: String = "",
    required: Boolean = false,
    enabled: Boolean = true,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
    testId: String? = null,
) {
    val colors = UseSmileIDSampleTheme.colors
    FlowRow(
        modifier = modifier
            .fillMaxWidth()
            .background(colors.surface)
            .defaultMinSize(minHeight = SmileDimens.sizeControlMd)
            .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingSm),
        horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
        verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs),
        itemVerticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = if (required) "$label *" else label,
            style = UseSmileIDSampleTheme.type.textStyleBodySm,
            color = colors.textMuted,
        )
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            enabled = enabled,
            singleLine = true,
            keyboardOptions = keyboardOptions,
            textStyle = UseSmileIDSampleTheme.type.textStyleBodySm.copy(
                // Muted when disabled, so a row that cannot be edited does not look identical to
                // one that can — the same treatment SelectTrigger gives its disabled state.
                color = if (enabled) colors.textTitle else colors.textMuted,
            ),
            cursorBrush = SolidColor(colors.primary),
            modifier = Modifier.tagged(testId),
            decorationBox = { field ->
                if (value.isEmpty()) {
                    Text(
                        text = placeholder,
                        style = UseSmileIDSampleTheme.type.textStyleBodySm,
                        color = colors.textMuted,
                    )
                }
                field()
            },
        )
    }
}
