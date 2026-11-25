package com.usesmileid.sampleapps.ui.components

import android.content.ContentResolver
import android.database.ContentObserver
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.State
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext

/** The scale a product card draws at: smaller while held, unless it is disabled or animations are off. */
internal fun useSmileIDSamplePressScale(pressed: Boolean, enabled: Boolean, reduceMotion: Boolean): Float =
    if (pressed && enabled && !reduceMotion) PRESSED_SCALE else 1f

/** The system's "remove animations" switch, which is Android's reduced-motion signal, kept current while shown. */
@Composable
internal fun useSmileIDSampleReducedMotion(): Boolean {
    val resolver = LocalContext.current.contentResolver
    val state = remember(resolver) { ReducedMotionWatch.state(resolver) }
    DisposableEffect(resolver) {
        ReducedMotionWatch.attach(resolver)
        onDispose { ReducedMotionWatch.detach(resolver) }
    }
    return state.value
}

/** One observer of the animation setting for every reader on screen, dropped with the last one. */
private object ReducedMotionWatch {
    private val uri = Settings.Global.getUriFor(Settings.Global.ANIMATOR_DURATION_SCALE)
    private var current: MutableState<Boolean>? = null
    private var readers = 0
    private var observer: ContentObserver? = null

    fun state(resolver: ContentResolver): State<Boolean> = mutable(resolver)

    fun attach(resolver: ContentResolver) {
        readers++
        if (observer != null) return
        val state = mutable(resolver)
        state.value = read(resolver)
        observer = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean) {
                state.value = read(resolver)
            }
        }.also { resolver.registerContentObserver(uri, false, it) }
    }

    fun detach(resolver: ContentResolver) {
        readers--
        if (readers > 0) return
        observer?.let(resolver::unregisterContentObserver)
        observer = null
    }

    private fun mutable(resolver: ContentResolver): MutableState<Boolean> =
        current ?: mutableStateOf(read(resolver)).also { current = it }

    private fun read(resolver: ContentResolver) =
        Settings.Global.getFloat(resolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f
}

private const val PRESSED_SCALE = 0.97f
