package com.usesmileid.sampleapps.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.semantics.clearAndSetSemantics
import com.smileid.designsystem.SmileMotion
import com.usesmileid.sampleapps.android.extension.launchUseSmileIDSampleShellExtension
import com.usesmileid.sampleapps.android.flow.UseSmileIDSampleNetworkLog
import com.usesmileid.sampleapps.android.launch.UseSmileIDSampleAppLocale
import com.usesmileid.sampleapps.android.launch.animationsEnabled
import com.usesmileid.sampleapps.android.launch.playsLaunchIntro
import com.usesmileid.sampleapps.android.launch.useSmileIDSampleLaunchArgs
import com.usesmileid.sampleapps.ui.screens.LaunchIntroScreen
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** Single-activity host: every step, including the SDK flow, is drawn from one njia graph. */
class UseSmileIDSampleActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val launchArgs = intent.useSmileIDSampleLaunchArgs()
        val restored = savedInstanceState != null
        val playsIntro = intent.playsLaunchIntro(restored, animationsEnabled())
        UseSmileIDSampleNetworkLog.install(this)
        launchUseSmileIDSampleShellExtension(intent, restored = restored)
        setContent {
            // Read above every override, so these are the device's values, not the app's.
            val deviceLocales = LocalConfiguration.current.locales
            val deviceLanguages = remember(deviceLocales) { deviceLocales.toLanguageTags().split(',') }
            val appState = rememberUseSmileIDSampleAppState(launchArgs, isSystemInDarkTheme(), deviceLanguages)
            var introShowing by rememberSaveable { mutableStateOf(playsIntro) }
            // Outermost, so the SDK's screens get the override too.
            UseSmileIDSampleAppLocale(appState.localeTag) {
                CompositionLocalProvider(LocalUseSmileIDSampleAppState provides appState) {
                    UseSmileIDSampleTheme(darkTheme = appState.resolvedDark) {
                        UseSmileIDSampleSystemBars(appState.resolvedDark || introShowing)
                        Box(Modifier.fillMaxSize()) {
                            // Composed beneath the intro so the app is warm when it fades, but hidden from accessibility until then.
                            Box(if (introShowing) Modifier.clearAndSetSemantics {} else Modifier) {
                                UseSmileIDSampleShell()
                            }
                            AnimatedVisibility(
                                visible = introShowing,
                                enter = EnterTransition.None,
                                exit = fadeOut(tween(SmileMotion.durationSlow.inWholeMilliseconds.toInt())),
                            ) {
                                BackHandler { introShowing = false }
                                LaunchIntroScreen(onFinished = { introShowing = false })
                            }
                        }
                    }
                }
            }
        }
    }
}
