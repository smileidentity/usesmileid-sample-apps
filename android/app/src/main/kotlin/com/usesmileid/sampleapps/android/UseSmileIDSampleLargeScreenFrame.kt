package com.usesmileid.sampleapps.android

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.max
import androidx.compose.ui.unit.min
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The largest Android phone's frame the app's own screens draw in on a large screen, from `spec/large-screen-frame.json`. */
internal object UseSmileIDSampleLargeScreen {
    /** The shorter side a large screen starts at. */
    val minSide = 600.dp

    /** The Galaxy S26 Ultra's screen at its default display size, the SDK's own large-screen frame. */
    val frame = DpSize(384.dp, 832.dp)
}

/** The app's size in a [window] whose safe area is [safeArea]: the frame, each side the safe area's where shorter, on a large screen; null on a phone. */
internal fun largeScreenFrameSize(window: DpSize, safeArea: DpSize): DpSize? {
    if (min(window.width, window.height) < UseSmileIDSampleLargeScreen.minSide) return null
    val frame = UseSmileIDSampleLargeScreen.frame
    return DpSize(min(max(safeArea.width, 0.dp), frame.width), min(max(safeArea.height, 0.dp), frame.height))
}

/** Draws [content] on a large screen as the largest phone shows it, centred on the screen background; a phone, or [framed] false, fills the window. */
@Composable
internal fun UseSmileIDSampleLargeScreenFrame(framed: Boolean, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    BoxWithConstraints(modifier) {
        val window = DpSize(maxWidth, maxHeight)
        val large = framed && largeScreenFrameSize(window, window) != null
        Box(
            modifier = Modifier
                .fillMaxSize()
                .then(if (large) Modifier.background(UseSmileIDSampleTheme.colors.background).windowInsetsPadding(WindowInsets.safeDrawing) else Modifier),
            contentAlignment = Alignment.Center,
        ) {
            // Measured inside the inset padding, which skips insets a host already took.
            BoxWithConstraints(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                val frame = if (large) largeScreenFrameSize(window, DpSize(maxWidth, maxHeight)) else null
                Box(if (frame == null) Modifier.fillMaxSize() else Modifier.size(frame).clipToBounds()) { content() }
            }
        }
    }
}
