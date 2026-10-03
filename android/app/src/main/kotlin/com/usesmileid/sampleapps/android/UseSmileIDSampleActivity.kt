package com.usesmileid.sampleapps.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.CompositionLocalProvider
import com.usesmileid.sampleapps.android.launch.UseSmileIDSampleAppLocale
import com.usesmileid.sampleapps.android.launch.useSmileIDSampleLaunchArgs
import com.usesmileid.sampleapps.android.navigation.foldUseSmileIDSampleSheetLink
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** Single-activity host: every route, including the SDK flow, is a destination in one graph. */
class UseSmileIDSampleActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        intent.foldUseSmileIDSampleSheetLink()
        val launchArgs = intent.useSmileIDSampleLaunchArgs()
        setContent {
            // Outermost, so the override reaches the SDK's screens too.
            UseSmileIDSampleAppLocale(launchArgs.appLocale) {
                // Read here, above every override, so it is the device's theme and never the app's.
                val appState = rememberUseSmileIDSampleAppState(launchArgs, deviceDark = isSystemInDarkTheme())
                CompositionLocalProvider(LocalUseSmileIDSampleAppState provides appState) {
                    UseSmileIDSampleTheme(darkTheme = appState.resolvedDark) {
                        UseSmileIDSampleSystemBars(appState.resolvedDark)
                        UseSmileIDSampleShell()
                    }
                }
            }
        }
    }
}
