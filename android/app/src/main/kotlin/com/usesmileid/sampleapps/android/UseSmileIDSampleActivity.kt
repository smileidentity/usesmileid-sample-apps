package com.usesmileid.sampleapps.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalConfiguration
import com.usesmileid.sampleapps.android.extension.launchUseSmileIDSampleShellExtension
import com.usesmileid.sampleapps.android.flow.UseSmileIDSampleNetworkLog
import com.usesmileid.sampleapps.android.launch.UseSmileIDSampleAppLocale
import com.usesmileid.sampleapps.android.launch.useSmileIDSampleLaunchArgs
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** Single-activity host: every step, including the SDK flow, is drawn from one njia graph. */
class UseSmileIDSampleActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val launchArgs = intent.useSmileIDSampleLaunchArgs()
        UseSmileIDSampleNetworkLog.install(this)
        launchUseSmileIDSampleShellExtension(intent, restored = savedInstanceState != null)
        setContent {
            // Read above every override, so these are the device's values, not the app's.
            val deviceLocales = LocalConfiguration.current.locales
            val deviceLanguages = remember(deviceLocales) { deviceLocales.toLanguageTags().split(',') }
            val appState = rememberUseSmileIDSampleAppState(launchArgs, isSystemInDarkTheme(), deviceLanguages)
            // Outermost, so the SDK's screens get the override too.
            UseSmileIDSampleAppLocale(appState.localeTag) {
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
