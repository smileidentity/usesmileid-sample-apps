package com.usesmileid.sampleapps.android

import android.graphics.Color
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.LocalActivity
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.graphics.toArgb
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** Keys both system bars to the Dark mode switch, which overrides the device's appearance just as the theme does. */
@Composable
fun UseSmileIDSampleSystemBars(darkMode: Boolean) {
    val activity = LocalActivity.current as? ComponentActivity ?: return
    // Only drawn below API 29; from 29 the system enforces the navigation bar's contrast itself.
    val scrim = UseSmileIDSampleTheme.colors.background.toArgb()
    LaunchedEffect(activity, darkMode, scrim) {
        // `auto` without a detector reads the device's night mode, so a dark phone drew white icons on the light app.
        activity.enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.auto(Color.TRANSPARENT, Color.TRANSPARENT) { darkMode },
            navigationBarStyle = SystemBarStyle.auto(scrim, scrim) { darkMode },
        )
    }
}
