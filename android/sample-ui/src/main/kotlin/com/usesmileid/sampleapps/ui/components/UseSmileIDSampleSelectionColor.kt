package com.usesmileid.sampleapps.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import com.smileid.designsystem.SmileMotion

/** A picked or unpicked colour that eases to [target] over duration-fast, instantly when the system removes animations. */
@Composable
internal fun useSmileIDSampleSelectionColor(target: Color, label: String): Color =
    animateColorAsState(target, tween(SmileMotion.durationFast.inWholeMilliseconds.toInt()), label = label).value
