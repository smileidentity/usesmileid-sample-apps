package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.SolidColor
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * A single-line text field drawn from the input tokens.
 *
 * [BasicTextField] rather than Material's `OutlinedTextField`, because that brings its own
 * container, label and indicator chrome which would have to be fought back to these tokens.
 *
 * The four contract states are all visible here: empty shows the placeholder, filled shows the
 * value, focused swaps the border for `input.border-focus`, and error swaps it for
 * `input.border-error` and reveals the message. Error outranks focus — a field that hides its error
 * as soon as the user taps back into it is how a form becomes unfixable.
 */
@Composable
fun UseSmileIDSampleTextInput(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    placeholder: String = "",
    enabled: Boolean = true,
    isError: Boolean = false,
    errorMessage: String? = null,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
    testId: String? = null,
) {
    val interactionSource = remember { MutableInteractionSource() }
    val focused by interactionSource.collectIsFocusedAsState()
    val colors = UseSmileIDSampleTheme.colors
    val borderColor = when {
        isError -> colors.input.borderError
        focused -> colors.input.borderFocus
        else -> colors.input.border
    }

    Column(modifier = modifier) {
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            enabled = enabled,
            singleLine = true,
            keyboardOptions = keyboardOptions,
            interactionSource = interactionSource,
            textStyle = UseSmileIDSampleTheme.type.inputFont.copy(
                color = if (enabled) colors.input.text else colors.textMuted,
            ),
            cursorBrush = SolidColor(colors.input.borderFocus),
            modifier = Modifier
                .fillMaxWidth()
                .tagged(testId),
            decorationBox = { field ->
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .defaultMinSize(minHeight = SmileDimens.sizeControlMd)
                        .background(
                            color = if (enabled) colors.input.background else colors.surfaceMuted,
                            shape = RoundedCornerShape(SmileDimens.radiusField),
                        )
                        .border(
                            width = if (focused || isError) SmileDimens.borderWidthThin else SmileDimens.borderWidthHairline,
                            color = borderColor,
                            shape = RoundedCornerShape(SmileDimens.radiusField),
                        )
                        .padding(
                            horizontal = SmileDimens.spacingMd,
                            vertical = SmileDimens.spacingSm,
                        ),
                    contentAlignment = Alignment.CenterStart,
                ) {
                    if (value.isEmpty()) {
                        Text(
                            text = placeholder,
                            style = UseSmileIDSampleTheme.type.inputFont,
                            color = colors.input.placeholder,
                        )
                    }
                    field()
                }
            },
        )
        if (isError && !errorMessage.isNullOrBlank()) {
            Text(
                text = errorMessage,
                style = UseSmileIDSampleTheme.type.textStyleCaption,
                color = colors.input.borderError,
                modifier = Modifier.padding(
                    start = SmileDimens.spacingMd,
                    top = SmileDimens.space4,
                ),
            )
        }
    }
}
