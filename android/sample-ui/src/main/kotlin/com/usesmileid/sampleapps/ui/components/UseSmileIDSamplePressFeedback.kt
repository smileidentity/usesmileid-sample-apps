package com.usesmileid.sampleapps.ui.components

import android.provider.Settings
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext

/** The scale a product card draws at: smaller while held, unless it is disabled or animations are off. */
fun useSmileIDSamplePressScale(pressed: Boolean, enabled: Boolean, reduceMotion: Boolean): Float =
    if (pressed && enabled && !reduceMotion) PRESSED_SCALE else 1f

/** The system's "remove animations" switch, which is Android's reduced-motion signal. */
@Composable
internal fun useSmileIDSampleReducedMotion(): Boolean {
    val resolver = LocalContext.current.contentResolver
    return remember(resolver) {
        Settings.Global.getFloat(resolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f
    }
}

private const val PRESSED_SCALE = 0.97f
