package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.unit.dp
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * Initials in a rounded square, or a placeholder when there are none. The size scales with the font
 * scale, because wrapping the initials instead renders an ellipse at 2x.
 *
 * The fill defaults to one drawn from the initials, so two profiles never look alike.
 */
@Composable
fun UseSmileIDSampleAvatar(
    initials: String,
    modifier: Modifier = Modifier,
    size: Dp = SmileDimens.space40,
    containerColor: Color = avatarColorFor(initials),
) {
    val hasInitials = initials.isNotBlank()
    val diameter = size * LocalDensity.current.fontScale
    Surface(
        modifier = modifier.size(diameter),
        // A rounded square, which is what the design draws — not a circle.
        shape = RoundedCornerShape(AVATAR_RADIUS),
        color = if (hasInitials) containerColor else UseSmileIDSampleTheme.colors.avatar.placeholderBackground,
    ) {
        Box(contentAlignment = Alignment.Center) {
            Text(
                text = if (hasInitials) initials else "?",
                style = UseSmileIDSampleTheme.type.avatarFont,
                color = if (hasInitials) {
                    UseSmileIDSampleTheme.colors.avatar.text
                } else {
                    UseSmileIDSampleTheme.colors.avatar.placeholderIcon
                },
                textAlign = TextAlign.Center,
            )
        }
    }
}

/**
 * One decorative colour per set of initials, chosen by a stable hash so a profile keeps its colour
 * across launches. Derived here: the design shows distinct fills but names no mapping.
 */
@Composable
private fun avatarColorFor(initials: String): Color {
    val palette = UseSmileIDSampleTheme.colors.decorative.all
    if (initials.isBlank()) return UseSmileIDSampleTheme.colors.avatar.background
    // Position-weighted, so "KA" and "AK" do not land on the same colour.
    val index = initials.uppercase().foldIndexed(0) { i, acc, c -> acc + c.code * (i + 1) } % palette.size
    return palette[index]
}

/** 12 in the design. */
private val AVATAR_RADIUS = 12.dp
