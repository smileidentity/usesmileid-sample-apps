package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.border
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * Looks like an input, behaves like a button: tapping it opens a picker sheet rather than a keyboard.
 *
 * Disabled is load-bearing rather than decorative — the ID-type trigger stays greyed until a country
 * is chosen, which is the dependency the ID form is built around.
 */
@Composable
fun UseSmileIDSampleSelectTrigger(
    value: String?,
    placeholder: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    testId: String? = null,
    leading: @Composable ((Color) -> Unit)? = null,
) {
    val colors = UseSmileIDSampleTheme.colors
    val contentColor = when {
        !enabled -> colors.textMuted
        value != null -> colors.textTitle
        else -> colors.input.placeholder
    }
    Surface(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier
            .fillMaxWidth()
            .semantics { role = Role.Button }
            .tagged(testId),
        shape = RoundedCornerShape(SmileDimens.radiusField),
        color = if (enabled) colors.input.background else colors.surfaceMuted,
    ) {
        Row(
            modifier = Modifier
                .defaultMinSize(minHeight = SmileDimens.sizeControlMd)
                .border(
                    width = SmileDimens.borderWidthHairline,
                    color = colors.input.border,
                    shape = RoundedCornerShape(SmileDimens.radiusField),
                )
                .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingSm),
            horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (leading != null) {
                Box(modifier = Modifier.size(SmileDimens.sizeIconMd), contentAlignment = Alignment.Center) {
                    leading(contentColor)
                }
            }
            Text(
                text = value ?: placeholder,
                style = UseSmileIDSampleTheme.type.inputFont,
                color = contentColor,
                modifier = Modifier.weight(1f),
            )
            ChevronRightGlyph(tint = contentColor)
        }
    }
}
