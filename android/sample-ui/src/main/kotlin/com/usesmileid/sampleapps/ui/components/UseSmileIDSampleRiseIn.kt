package com.usesmileid.sampleapps.ui.components

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch

/** Content that rises its own height into place, fading in, when it first appears; the toast's own entrance. */
@Composable
fun UseSmileIDSampleRiseIn(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    val reduceMotion = useSmileIDSampleReducedMotion()
    val rise = remember { Animatable(if (reduceMotion) 1f else 0f) }
    val fade = remember { Animatable(if (reduceMotion) 1f else 0f) }
    LaunchedEffect(Unit) {
        if (reduceMotion) return@LaunchedEffect
        launchRise(rise, fade)
    }
    Box(
        modifier.graphicsLayer {
            translationY = (1f - rise.value) * size.height
            alpha = fade.value
        },
    ) { content() }
}

private suspend fun launchRise(rise: Animatable<Float, *>, fade: Animatable<Float, *>) = coroutineScope {
    launch { rise.animateTo(1f, tween(RISE_MS, easing = FastOutSlowInEasing)) }
    launch { fade.animateTo(1f, tween(FADE_MS, easing = FastOutSlowInEasing)) }
}

private const val RISE_MS = 220
private const val FADE_MS = 160
