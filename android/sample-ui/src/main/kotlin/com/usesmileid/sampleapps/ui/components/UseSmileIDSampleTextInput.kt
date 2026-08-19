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
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** A single-line field on the input tokens. [BasicTextField] avoids `OutlinedTextField`'s competing chrome, and error outranks focus so tapping back in does not hide the message. */
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
    /** Masks the value and marks the field a password, keeping a credential out of screenshots and
     *  out of the view hierarchy an automated run dumps on failure. */
    masked: Boolean = false,
    testId: String? = null,
    /** The leading glyph the new-profile fields carry. */
    leading: @Composable ((Color) -> Unit)? = null,
    /** An action inside the field's border, which is where the design draws the scan sheet's Paste. */
    trailing: @Composable ((Color) -> Unit)? = null,
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
            keyboardOptions = if (masked) {
                keyboardOptions.copy(keyboardType = KeyboardType.Password, autoCorrectEnabled = false)
            } else {
                keyboardOptions
            },
            visualTransformation = if (masked) PasswordVisualTransformation() else VisualTransformation.None,
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
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        if (leading != null) {
                            Box(
                                modifier = Modifier.defaultMinSize(minWidth = LEADING_SIZE, minHeight = LEADING_SIZE),
                                contentAlignment = Alignment.Center,
                            ) {
                                leading(colors.input.placeholder)
                            }
                        }
                        // Weighted so a trailing action keeps its width; with no trailing the field still fills.
                        Box(modifier = Modifier.weight(1f), contentAlignment = Alignment.CenterStart) {
                    if (value.isEmpty()) {
                        Text(
                            text = placeholder,
                            style = UseSmileIDSampleTheme.type.inputFont,
                            color = colors.input.placeholder,
                        )
                    }
                    field()
                        }
                        trailing?.invoke(colors.input.placeholder)
                    }
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

private val LEADING_SIZE = 17.dp
