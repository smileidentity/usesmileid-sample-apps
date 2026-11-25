package com.usesmileid.sampleapps.ui.components

import android.database.ContentObserver
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext

/** The scale a product card draws at: smaller while held, unless it is disabled or animations are off. */
internal fun useSmileIDSamplePressScale(pressed: Boolean, enabled: Boolean, reduceMotion: Boolean): Float =
    if (pressed && enabled && !reduceMotion) PRESSED_SCALE else 1f

/** The system's "remove animations" switch, which is Android's reduced-motion signal, kept current while shown. */
@Composable
internal fun useSmileIDSampleReducedMotion(): Boolean {
    val resolver = LocalContext.current.contentResolver
    val read = { Settings.Global.getFloat(resolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f }
    var reduced by remember(resolver) { mutableStateOf(read()) }
    DisposableEffect(resolver) {
        val observer = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean) {
                reduced = read()
            }
        }
        resolver.registerContentObserver(Settings.Global.getUriFor(Settings.Global.ANIMATOR_DURATION_SCALE), false, observer)
        onDispose { resolver.unregisterContentObserver(observer) }
    }
    return reduced
}

private const val PRESSED_SCALE = 0.97f
