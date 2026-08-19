package com.usesmileid.sampleapps.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.sp
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScanState
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * The scanner's state, over the viewfinder. One pill so the eye has a single place to look, coloured
 * from the feedback tokens rather than by inventing a palette: informational while decoding, success
 * once linked, error on a rejection — which is the only state that offers an action, because it is
 * the only one the person can do anything about.
 */
@Composable
fun UseSmileIDSampleScanStatus(
    state: UseSmileIDSampleScanState,
    onRetry: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = UseSmileIDSampleTheme.colors
    val (background, foreground) = when (state) {
        UseSmileIDSampleScanState.Searching -> colors.surface to colors.textTitle
        UseSmileIDSampleScanState.Found -> colors.infoFill to colors.onInfo
        is UseSmileIDSampleScanState.Linked -> colors.successFill to colors.onSuccess
        is UseSmileIDSampleScanState.Rejected -> colors.errorFill to colors.onError
    }
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(SmileDimens.radiusSurface),
        color = background,
    ) {
        Column(
            modifier = Modifier.padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingSm),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs),
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                if (state is UseSmileIDSampleScanState.Linked) {
                    Box(modifier = Modifier.size(SmileDimens.sizeIconMd), contentAlignment = Alignment.Center) {
                        CheckGlyph(tint = foreground)
                    }
                }
                Text(
                    text = state.headline(),
                    style = UseSmileIDSampleTheme.type.textStyleBodyStrong,
                    color = foreground,
                    textAlign = TextAlign.Center,
                )
            }
            state.detail()?.let { detail ->
                Text(
                    text = detail,
                    style = UseSmileIDSampleTheme.type.textStyleCaption.copy(fontSize = DETAIL_SIZE),
                    color = foreground,
                    textAlign = TextAlign.Center,
                )
            }
            // Only a rejection is actionable: everything else resolves itself in a beat.
            AnimatedVisibility(
                visible = state is UseSmileIDSampleScanState.Rejected,
                enter = fadeIn() + slideInVertically { it / 2 },
                exit = fadeOut() + slideOutVertically { it / 2 },
            ) {
                Text(
                    text = "Try again",
                    style = UseSmileIDSampleTheme.type.linkFont.copy(fontWeight = FontWeight.Bold),
                    color = foreground,
                    modifier = Modifier
                        .clickable(role = Role.Button, onClick = onRetry)
                        .minimumInteractiveComponentSize()
                        .padding(horizontal = SmileDimens.spacingXs),
                )
            }
        }
    }
}

private fun UseSmileIDSampleScanState.headline(): String = when (this) {
    UseSmileIDSampleScanState.Searching -> "Point at a Smile token QR"
    UseSmileIDSampleScanState.Found -> "Token found"
    is UseSmileIDSampleScanState.Linked -> "Session linked"
    is UseSmileIDSampleScanState.Rejected -> "That is not a token"
}

private fun UseSmileIDSampleScanState.detail(): String? = when (this) {
    UseSmileIDSampleScanState.Searching -> null
    UseSmileIDSampleScanState.Found -> "Reading it now"
    // The handle and the time it has left: never the token, which no surface here may show.
    is UseSmileIDSampleScanState.Linked -> "$handle · $remaining left"
    is UseSmileIDSampleScanState.Rejected -> reason
}

private val DETAIL_SIZE = 12.5.sp
