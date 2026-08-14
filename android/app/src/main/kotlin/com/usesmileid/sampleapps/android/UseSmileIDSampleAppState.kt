package com.usesmileid.sampleapps.android

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import kotlinx.coroutines.CoroutineScope
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleSettings
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleStore
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import androidx.compose.runtime.staticCompositionLocalOf
import kotlinx.coroutines.delay

/** Everything the shell hoists: persisted settings, the token session, and the clock that ticks it. */
class UseSmileIDSampleAppState(
    val store: UseSmileIDSampleStore,
    /** Outlives any one screen, so navigating away cannot cancel a write to the store mid-flight. */
    val storeScope: CoroutineScope,
    val settings: UseSmileIDSampleSettings,
    val session: UseSmileIDSampleTokenSession?,
    val nowMillis: Long,
) {
    val sessionExpired: Boolean get() = session != null && session.hasExpired(nowMillis)
    val sessionActive: Boolean get() = session != null && !session.hasExpired(nowMillis)
}

/** Ticks once a second while a session is live. The deadline is absolute, so a restored session needs no recomputing. */
@Composable
fun rememberUseSmileIDSampleAppState(): UseSmileIDSampleAppState {
    val context = LocalContext.current
    val store = remember(context) { UseSmileIDSampleStore(context) }
    val settings by store.settings.collectAsStateWithLifecycle(initialValue = UseSmileIDSampleSettings())
    val session by store.tokenSession.collectAsStateWithLifecycle(initialValue = null)
    var nowMillis by remember { mutableLongStateOf(System.currentTimeMillis()) }

    // Stops at the deadline: the session object does not change when it expires, so a loop keyed
    // only on it would tick for as long as the app is open.
    LaunchedEffect(session) {
        val live = session ?: return@LaunchedEffect
        while (!live.hasExpired(nowMillis)) {
            nowMillis = System.currentTimeMillis()
            delay(TICK_MILLIS)
        }
    }

    return UseSmileIDSampleAppState(
        store = store,
        storeScope = rememberCoroutineScope(),
        settings = settings,
        session = session,
        nowMillis = nowMillis,
    )
}

/** Provided once at the root, so a destination reads it without the graph threading it through. */
val LocalUseSmileIDSampleAppState = staticCompositionLocalOf<UseSmileIDSampleAppState> {
    error("No UseSmileIDSampleAppState provided")
}

private const val TICK_MILLIS = 1000L
