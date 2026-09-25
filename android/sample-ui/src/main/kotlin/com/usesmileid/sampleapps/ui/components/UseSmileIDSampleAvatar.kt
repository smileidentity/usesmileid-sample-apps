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
import com.smileid.designsystem.smileProfileHues
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** Initials in a rounded square, or a placeholder without them. The size scales with the font scale, because wrapping the initials renders an ellipse at 2x. */
@Composable
fun UseSmileIDSampleAvatar(
    initials: String,
    modifier: Modifier = Modifier,
    size: Dp = SmileDimens.space40,
    containerColor: Color = smileProfileHues.first(),
) {
    val hasInitials = initials.isNotBlank()
    val diameter = size * LocalDensity.current.fontScale
    Surface(
        modifier = modifier.size(diameter),
        shape = RoundedCornerShape(AVATAR_RADIUS),
        color = if (hasInitials) containerColor else UseSmileIDSampleTheme.colors.avatar.placeholderBackground,
    ) {
        Box(contentAlignment = Alignment.Center) {
            Text(
                text = if (hasInitials) initials else "+",
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

/** The avatar fill for a profile at [profileIndex], cycled. Position, not a hash of the initials, which reproduces no design order. */
fun avatarColorForProfile(profileIndex: Int): Color =
    smileProfileHues[profileIndex.coerceAtLeast(0) % smileProfileHues.size]

private val AVATAR_RADIUS = 12.dp
