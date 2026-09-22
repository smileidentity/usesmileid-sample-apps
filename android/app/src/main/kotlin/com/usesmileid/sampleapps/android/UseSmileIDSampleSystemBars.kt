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

/** Keys both system bars to the Dark mode switch rather than the device. */
@Composable
fun UseSmileIDSampleSystemBars(darkMode: Boolean) {
    val activity = LocalActivity.current as? ComponentActivity ?: return
    val colors = UseSmileIDSampleTheme.colors
    // Below API 26 the dark scrim is always drawn, because the buttons cannot turn dark.
    val lightScrim = colors.background.toArgb()
    val darkScrim = colors.overlayScrim.toArgb()
    // In composition order, so it is set before the SDK's capture screen saves it.
    DisposableEffect(activity, darkMode, lightScrim, darkScrim) {
        activity.enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.auto(Color.TRANSPARENT, Color.TRANSPARENT) { darkMode },
            navigationBarStyle = SystemBarStyle.auto(lightScrim, darkScrim) { darkMode },
        )
        onDispose { }
    }
}
