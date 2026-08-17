package com.usesmileid.sampleapps.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.IntOffset

/**
 * A bar that arrives over the screen — a snackbar, the selection bar — rising into place instead of
 * appearing between frames. The caller holds whatever the bar reads, so it still has something to
 * draw on the way out.
 */
@Composable
fun UseSmileIDSampleOverlay(
    visible: Boolean,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    AnimatedVisibility(
        visible = visible,
        modifier = modifier,
        enter = slideInVertically(SLIDE) { it } + fadeIn(FADE),
        exit = slideOutVertically(SLIDE) { it } + fadeOut(FADE),
    ) {
        content()
    }
}

private val SLIDE = tween<IntOffset>(durationMillis = 220, easing = FastOutSlowInEasing)
private val FADE = tween<Float>(durationMillis = 160, easing = FastOutSlowInEasing)
