package com.usesmileid.sampleapps.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.CompositionLocalProvider
import com.usesmileid.sampleapps.android.launch.UseSmileIDSampleAppLocale
import com.usesmileid.sampleapps.android.launch.useSmileIDSampleLaunchArgs
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** Single-activity host: every route, including the SDK flow, is a destination in one graph. */
class UseSmileIDSampleActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        val launchArgs = intent.useSmileIDSampleLaunchArgs()
        setContent {
            // Outermost, so the override reaches the SDK's own screens as well as this app's.
            UseSmileIDSampleAppLocale(launchArgs.appLocale) {
                // Collected above the theme, because the Dark mode switch is what the theme reads.
                val appState = rememberUseSmileIDSampleAppState(launchArgs)
                CompositionLocalProvider(LocalUseSmileIDSampleAppState provides appState) {
                    UseSmileIDSampleTheme(darkTheme = appState.settings.darkMode) {
                        UseSmileIDSampleShell()
                    }
                }
            }
        }
    }
}
