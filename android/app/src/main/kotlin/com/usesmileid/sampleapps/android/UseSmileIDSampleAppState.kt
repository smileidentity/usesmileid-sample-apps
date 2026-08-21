package com.usesmileid.sampleapps.android

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.State
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import kotlinx.coroutines.CoroutineScope
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.compose.runtime.saveable.rememberSaveable
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleFlowResult
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleForms
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleJobStore
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
    private val settingsState: State<UseSmileIDSampleSettings>,
    private val sessionState: State<UseSmileIDSampleTokenSession?>,
    /** From Room, behind [State] for the same reason as [now]: a value would invalidate the whole subtree on every write. */
    private val jobsState: State<List<UseSmileIDSampleJob>>,
    val jobStore: UseSmileIDSampleJobStore,
    val forms: UseSmileIDSampleForms,
    val profiles: UseSmileIDSampleProfiles,
    val launchArgs: UseSmileIDSampleLaunchArgs,
    val flowResult: UseSmileIDSampleFlowResult,
    /**
     * Read through [State] rather than held as a value, so the once-a-second tick recomposes only
     * what reads the clock. Held as a value it changed this object's identity every second, and
     * because it is provided through a `staticCompositionLocalOf` that invalidated the whole tree —
     * the hosted SDK flow included, where the SDK re-runs `build()` on every recomposition.
     */
    private val now: State<Long>,
) {
    val settings: UseSmileIDSampleSettings get() = settingsState.value
    val session: UseSmileIDSampleTokenSession? get() = sessionState.value
    val jobs: List<UseSmileIDSampleJob> get() = jobsState.value

    val nowMillis: Long get() = now.value

    val sessionExpired: Boolean get() = session?.hasExpired(nowMillis) == true
    val sessionActive: Boolean get() = session?.hasExpired(nowMillis) == false

    /** The only place the environment is decided, so the chip and the builder cannot disagree. */
    val useSandbox: Boolean get() = launchArgs.sandbox ?: settings.useSandbox

    /** True while the launch argument owns the choice, so Settings shows the row read-only. */
    val environmentPinned: Boolean get() = launchArgs.sandbox != null

    val environment: UseSmileIDSampleEnvironment
        get() = if (useSandbox) UseSmileIDSampleEnvironment.Sandbox else UseSmileIDSampleEnvironment.Production
}

/** Ticks once a second while a session is live. The deadline is absolute, so a restored session needs no recomputing. */
@Composable
fun rememberUseSmileIDSampleAppState(
    launchArgs: UseSmileIDSampleLaunchArgs = UseSmileIDSampleLaunchArgs(),
): UseSmileIDSampleAppState {
    val context = LocalContext.current
    val store = remember(context) { UseSmileIDSampleStore(context) }
    val settingsState = store.settings.collectAsStateWithLifecycle(initialValue = UseSmileIDSampleSettings())
    val sessionState = store.tokenSession.collectAsStateWithLifecycle(initialValue = null)
    val now = remember { mutableLongStateOf(System.currentTimeMillis()) }
    val jobStore = remember(context) { UseSmileIDSampleJobStore.of(context) }
    val jobsState = jobStore.jobs.collectAsStateWithLifecycle(initialValue = emptyList())
    // Automation precondition, never an ordinary launch. Idempotent, so a recreation inserts nothing.
    LaunchedEffect(launchArgs.seedJobs) {
        if (launchArgs.seedJobs) jobStore.seedFixtures(System.currentTimeMillis())
    }
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
    LaunchedEffect(sessionState.value) {
        val live = sessionState.value ?: return@LaunchedEffect
        while (!live.hasExpired(now.longValue)) {
            now.longValue = System.currentTimeMillis()
            delay(TICK_MILLIS)
        }
    }

    return UseSmileIDSampleAppState(
        store = store,
        storeScope = rememberCoroutineScope(),
        settingsState = settingsState,
        sessionState = sessionState,
        jobsState = jobsState,
        jobStore = jobStore,
        forms = forms,
        profiles = profiles,
        launchArgs = launchArgs,
        flowResult = flowResult,
        now = now,
    )
}

/** Provided once at the root, so a destination reads it without the graph threading it through. */
val LocalUseSmileIDSampleAppState = staticCompositionLocalOf<UseSmileIDSampleAppState> {
    error("No UseSmileIDSampleAppState provided")
}

private const val TICK_MILLIS = 1000L
