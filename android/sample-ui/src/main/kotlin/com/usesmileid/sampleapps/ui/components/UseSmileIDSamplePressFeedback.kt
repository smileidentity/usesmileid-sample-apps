package com.usesmileid.sampleapps.ui.components

import android.content.ContentResolver
import android.database.ContentObserver
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext

/** The scale a product card draws at: smaller while held, unless it is disabled or animations are off. */
internal fun useSmileIDSamplePressScale(pressed: Boolean, enabled: Boolean, reduceMotion: Boolean): Float =
    if (pressed && enabled && !reduceMotion) PRESSED_SCALE else 1f

/** The system's "remove animations" switch, which is Android's reduced-motion signal, kept current while shown. */
@Composable
internal fun useSmileIDSampleReducedMotion(): Boolean {
    val resolver = LocalContext.current.applicationContext.contentResolver
    val reduced = remember(resolver) { mutableStateOf(ReducedMotionWatch.read(resolver)) }
    DisposableEffect(resolver) {
        val reader: (Boolean) -> Unit = { reduced.value = it }
        ReducedMotionWatch.attach(resolver, reader)
        onDispose { ReducedMotionWatch.detach(reader) }
    }
    return reduced.value
}

/** One observer of the animation setting for every reader on screen, dropped with the last one; each reader keeps its own state. */
private object ReducedMotionWatch {
    private val uri = Settings.Global.getUriFor(Settings.Global.ANIMATOR_DURATION_SCALE)
    private val readers = mutableSetOf<(Boolean) -> Unit>()
    private var observer: ContentObserver? = null
    private var watched: ContentResolver? = null

    fun attach(resolver: ContentResolver, reader: (Boolean) -> Unit) {
        readers += reader
        reader(read(resolver))
        if (observer != null && watched === resolver) return
        stopWatching()
        observer = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean) {
                val reduced = read(resolver)
                readers.toList().forEach { it(reduced) }
            }
        }.also { resolver.registerContentObserver(uri, false, it) }
        watched = resolver
    }

    fun detach(reader: (Boolean) -> Unit) {
        readers -= reader
        if (readers.isEmpty()) stopWatching()
    }

    private fun stopWatching() {
        observer?.let { watched?.unregisterContentObserver(it) }
        observer = null
        watched = null
    }

    fun read(resolver: ContentResolver) =
        Settings.Global.getFloat(resolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f
}

private const val PRESSED_SCALE = 0.97f
