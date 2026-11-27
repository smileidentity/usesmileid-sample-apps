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

/** A bar that rises into place rather than appearing between frames. The caller holds what it reads. */
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

internal const val OVERLAY_SLIDE_MS = 220
internal const val OVERLAY_FADE_MS = 160

private val SLIDE = tween<IntOffset>(durationMillis = OVERLAY_SLIDE_MS, easing = FastOutSlowInEasing)
private val FADE = tween<Float>(durationMillis = OVERLAY_FADE_MS, easing = FastOutSlowInEasing)
