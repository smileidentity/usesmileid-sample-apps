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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The design leads each trigger with an emoji rather than a glyph, so it carries no tint. */
@Composable
fun UseSmileIDSampleTriggerEmoji(emoji: String) = Text(
    text = emoji,
    style = UseSmileIDSampleTheme.type.inputFont.copy(fontSize = TRIGGER_EMOJI_SIZE),
)

/** Looks like an input, behaves like a button. Disabled is load-bearing: ID type stays greyed until a country is chosen. */
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
        // The disabled pair, not textMuted on an almost-white surface, which does not read as disabled.
        !enabled -> colors.button.disabledText
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
        color = if (enabled) colors.input.background else colors.button.disabledBackground,
    ) {
        Row(
            modifier = Modifier
                .defaultMinSize(minHeight = SmileDimens.sizeControlMd)
                .border(
                    // The design outlines an actionable trigger in primary and a disabled one in border.
                    width = SmileDimens.borderWidthThin,
                    color = if (enabled) colors.primary else colors.input.border,
                    shape = RoundedCornerShape(SmileDimens.radiusField),
                )
                .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingSm),
            horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (leading != null) {
                // A minimum, not a fixed size: the leading slot may hold an emoji, which grows with font scale.
                Box(
                    modifier = Modifier.defaultMinSize(minWidth = SmileDimens.sizeIconMd, minHeight = SmileDimens.sizeIconMd),
                    contentAlignment = Alignment.Center,
                ) {
                    leading(contentColor)
                }
            }
            Text(
                // 15/600 in the design, where inputFont is 14/400.
                text = value ?: placeholder,
                style = UseSmileIDSampleTheme.type.inputFont.copy(
                    fontSize = TRIGGER_TEXT_SIZE,
                    fontWeight = FontWeight.SemiBold,
                ),
                color = contentColor,
                modifier = Modifier.weight(1f),
            )
            ChevronDownGlyph(tint = contentColor, size = CHEVRON_SIZE)
        }
    }
}

/** 15, 18 and 12 in the design; no token carries them. */
private val TRIGGER_TEXT_SIZE = 15.sp
private val TRIGGER_EMOJI_SIZE = 18.sp
private val CHEVRON_SIZE = 12.dp
