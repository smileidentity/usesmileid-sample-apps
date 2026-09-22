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

/** Keys both system bars to the Dark mode switch, which overrides the device's appearance just as the theme does. */
@Composable
fun UseSmileIDSampleSystemBars(darkMode: Boolean) {
    val activity = LocalActivity.current as? ComponentActivity ?: return
    val colors = UseSmileIDSampleTheme.colors
    // Only drawn below API 29, and below 26 the dark one always is, because its buttons cannot turn dark.
    val lightScrim = colors.background.toArgb()
    val darkScrim = colors.overlayScrim.toArgb()
    // Applied in composition order, not a frame later: the SDK's capture screen saves this value to restore it.
    DisposableEffect(activity, darkMode, lightScrim, darkScrim) {
        // Without a detector, `auto` reads the device's night mode rather than the app's.
        activity.enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.auto(Color.TRANSPARENT, Color.TRANSPARENT) { darkMode },
            navigationBarStyle = SystemBarStyle.auto(lightScrim, darkScrim) { darkMode },
        )
        onDispose { }
    }
}
