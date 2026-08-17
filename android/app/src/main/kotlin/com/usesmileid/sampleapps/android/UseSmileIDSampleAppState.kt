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
import androidx.compose.runtime.saveable.rememberSaveable
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJobs
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleFlowResult
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleForms
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleLaunchArgs
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleProfiles
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
    val jobs: UseSmileIDSampleJobs,
    val forms: UseSmileIDSampleForms,
    val profiles: UseSmileIDSampleProfiles,
    val launchArgs: UseSmileIDSampleLaunchArgs,
    val flowResult: UseSmileIDSampleFlowResult,
    val nowMillis: Long,
) {
    val sessionExpired: Boolean get() = session != null && session.hasExpired(nowMillis)
    val sessionActive: Boolean get() = session != null && !session.hasExpired(nowMillis)
}

/** Ticks once a second while a session is live. The deadline is absolute, so a restored session needs no recomputing. */
@Composable
fun rememberUseSmileIDSampleAppState(
    launchArgs: UseSmileIDSampleLaunchArgs = UseSmileIDSampleLaunchArgs(),
): UseSmileIDSampleAppState {
    val context = LocalContext.current
    val store = remember(context) { UseSmileIDSampleStore(context) }
    val settings by store.settings.collectAsStateWithLifecycle(initialValue = UseSmileIDSampleSettings())
    val session by store.tokenSession.collectAsStateWithLifecycle(initialValue = null)
    var nowMillis by remember { mutableLongStateOf(System.currentTimeMillis()) }
    // Seeded sample data until jobs arrive from the SDK; in memory, so it resets on process death.
    val jobs = remember { UseSmileIDSampleJobs.seeded(System.currentTimeMillis()) }
    val forms = rememberSaveable(saver = UseSmileIDSampleForms.Saver) { UseSmileIDSampleForms() }
    val profiles = remember { UseSmileIDSampleProfiles() }
    // Saveable, so the arguments seed the first launch only and a recreation keeps the drawer's choice.
    val flowResult = rememberSaveable(saver = UseSmileIDSampleFlowResult.Saver) {
        UseSmileIDSampleFlowResult(
            scenario = launchArgs.scenario,
            theme = launchArgs.theme,
            route = launchArgs.route,
        )
    }

    // Stops at the deadline: the session object does not change on expiry, so the key alone never ends this.
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
        jobs = jobs,
        forms = forms,
        profiles = profiles,
        launchArgs = launchArgs,
        flowResult = flowResult,
        nowMillis = nowMillis,
    )
}

/** Provided once at the root, so a destination reads it without the graph threading it through. */
val LocalUseSmileIDSampleAppState = staticCompositionLocalOf<UseSmileIDSampleAppState> {
    error("No UseSmileIDSampleAppState provided")
}

private const val TICK_MILLIS = 1000L
