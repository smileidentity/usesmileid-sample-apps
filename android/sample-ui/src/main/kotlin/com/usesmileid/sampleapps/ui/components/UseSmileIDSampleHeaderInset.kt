package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.calculateEndPadding
import androidx.compose.foundation.layout.calculateStartPadding
import androidx.compose.foundation.layout.displayCutout
import androidx.compose.foundation.layout.statusBars
import androidx.compose.runtime.Composable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.smileid.designsystem.SmileDimens

/** True inside a host's large-screen frame, which keeps the status bar outside it. */
val LocalUseSmileIDSampleLargeScreenFramed = staticCompositionLocalOf { false }

/** The gap a header keeps below the status bar under a top camera cutout, which the bar ends flush with where an iPhone's safe area leaves room. */
@Composable
fun useSmileIDSampleHeaderTopGap(): Dp {
    val density = LocalDensity.current
    val underCutout = WindowInsets.statusBars.getTop(density) > 0 && WindowInsets.displayCutout.getTop(density) > 0
    return if (underCutout && !LocalUseSmileIDSampleLargeScreenFramed.current) SmileDimens.spacingSm else 0.dp
}

/** [contentPadding] with the header gap added on top, so a tab's list scrolls the gap away with its header. */
@Composable
fun useSmileIDSampleHeaderContentPadding(contentPadding: PaddingValues): PaddingValues {
    val direction = LocalLayoutDirection.current
    return PaddingValues(
        start = contentPadding.calculateStartPadding(direction),
        top = contentPadding.calculateTopPadding() + useSmileIDSampleHeaderTopGap(),
        end = contentPadding.calculateEndPadding(direction),
        bottom = contentPadding.calculateBottomPadding(),
    )
}
