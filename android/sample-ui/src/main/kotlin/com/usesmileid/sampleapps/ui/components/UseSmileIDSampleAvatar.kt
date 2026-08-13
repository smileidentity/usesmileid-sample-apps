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

/**
 * Initials in a circle, falling back to a neutral placeholder when there are none.
 *
 * [containerColor] exists because the background is per-profile rather than one avatar colour; the
 * designer still owes the profile→hue list, so the avatar token is the default until it lands.
 *
 * `avatar.size-md` and `avatar.radius` have no dimension token in the Compose output — the upstream
 * emitter drops component dimensions — so the nearest scale token stands in.
 *
 * The diameter is multiplied by the font scale rather than left to wrap its content. A wrapping
 * circle grows only as wide as the initials need and turns into an ellipse, which is plainly visible
 * at the largest font scale; scaling it keeps the shape square and the initials proportionate.
 */
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
