package com.usesmileid.sampleapps.android

import android.graphics.Color
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.LocalActivity
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.ui.graphics.toArgb
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** Keys both system bars to the theme the app renders, which a pinned appearance can set against the device. */
@Composable
fun UseSmileIDSampleSystemBars(dark: Boolean) {
    val activity = LocalActivity.current as? ComponentActivity ?: return
    val colors = UseSmileIDSampleTheme.colors
    // Below API 26 the dark scrim is always drawn, because the buttons cannot turn dark.
    val lightScrim = colors.background.toArgb()
    val darkScrim = colors.overlayScrim.toArgb()
    // A DisposableEffect runs in the apply pass, before the SDK capture screen's own effect saves this value.
    DisposableEffect(activity, dark, lightScrim, darkScrim) {
        activity.enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.auto(Color.TRANSPARENT, Color.TRANSPARENT) { dark },
            navigationBarStyle = SystemBarStyle.auto(lightScrim, darkScrim) { dark },
        )
        onDispose { }
    }
}
