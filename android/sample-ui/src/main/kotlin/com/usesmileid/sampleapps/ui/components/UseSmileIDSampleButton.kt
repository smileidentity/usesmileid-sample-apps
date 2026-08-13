package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * The full-width primary action. Pill radius, and a minimum height rather than a fixed one so the
 * label wraps instead of clipping at large font scales.
 *
 * Loading is a distinct state from disabled: the button stops accepting taps but keeps its enabled
 * colours, because a form that greys out mid-submission reads as having rejected the input.
 */
@Composable
fun UseSmileIDSampleButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    loading: Boolean = false,
    testId: String? = null,
) {
    Button(
        onClick = onClick,
        modifier = modifier
            .fillMaxWidth()
            .defaultMinSize(minHeight = SmileDimens.sizeControlLg)
            .tagged(testId),
        enabled = enabled && !loading,
        shape = RoundedCornerShape(SmileDimens.radiusControl),
        colors = ButtonDefaults.buttonColors(
            containerColor = UseSmileIDSampleTheme.colors.button.primaryBackground,
            contentColor = UseSmileIDSampleTheme.colors.button.primaryText,
            disabledContainerColor = if (loading) {
                UseSmileIDSampleTheme.colors.button.primaryBackground
            } else {
                UseSmileIDSampleTheme.colors.button.disabledBackground
            },
            disabledContentColor = if (loading) {
                UseSmileIDSampleTheme.colors.button.primaryText
            } else {
                UseSmileIDSampleTheme.colors.button.disabledText
            },
        ),
        contentPadding = ButtonDefaults.ContentPadding,
    ) {
        Box(contentAlignment = Alignment.Center) {
            if (loading) {
                CircularProgressIndicator(
                    modifier = Modifier.size(SmileDimens.sizeIconMd),
                    color = UseSmileIDSampleTheme.colors.button.primaryText,
                    strokeWidth = SmileDimens.borderWidthThick,
                )
            } else {
                Text(
                    text = text,
                    style = UseSmileIDSampleTheme.type.buttonFont,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(vertical = SmileDimens.space4),
                )
            }
        }
    }
}
