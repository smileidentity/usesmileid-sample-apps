package com.usesmileid.sampleapps.ui.components

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import com.smileid.designsystem.SmileMotion

/** Content that fades in over duration-fast when it first appears, as a list does when it replaces its loading state. */
@Composable
fun UseSmileIDSampleFadeIn(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    val reduceMotion = useSmileIDSampleReducedMotion()
    val alpha = remember { Animatable(if (reduceMotion) 1f else 0f) }
    LaunchedEffect(Unit) {
        if (!reduceMotion) alpha.animateTo(1f, tween(SmileMotion.durationFast.inWholeMilliseconds.toInt()))
    }
    Box(modifier.graphicsLayer { this.alpha = alpha.value }) { content() }
}
