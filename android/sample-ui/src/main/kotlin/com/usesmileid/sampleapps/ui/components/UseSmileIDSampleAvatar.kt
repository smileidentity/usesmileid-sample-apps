package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** Initials in a circle, or a placeholder when there are none. The diameter scales with the font scale, because wrapping the initials instead renders an ellipse at 2x. */
@Composable
fun UseSmileIDSampleAvatar(
    initials: String,
    modifier: Modifier = Modifier,
    size: Dp = SmileDimens.space40,
    containerColor: Color = UseSmileIDSampleTheme.colors.avatar.background,
) {
    val hasInitials = initials.isNotBlank()
    val diameter = size * LocalDensity.current.fontScale
    Surface(
        modifier = modifier.size(diameter),
        shape = CircleShape,
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
