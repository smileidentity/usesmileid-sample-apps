package com.usesmileid.sampleapps.android

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.State
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.remember
import kotlinx.coroutines.CoroutineScope
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.compose.runtime.saveable.rememberSaveable
import com.usesmileid.sampleapps.android.status.RetrofitJobStatusSource
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleFlowResult
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleForms
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleInterruptedRun
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleJobStore
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleLaunchArgs
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleProfiles
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleSettings
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleStore
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleEndedSession
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import androidx.compose.runtime.staticCompositionLocalOf
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/** Everything the shell hoists: persisted settings, the token session, and the clock that ticks it. */
class UseSmileIDSampleAppState(
    val store: UseSmileIDSampleStore,
    /** Process-lifetime: neither navigation nor activity recreation can cancel a write mid-flight. */
    val storeScope: CoroutineScope,
    private val settingsState: State<UseSmileIDSampleSettings>,
    private val sessionState: State<UseSmileIDSampleTokenSession?>,
    private val endedSessionState: State<UseSmileIDSampleEndedSession?>,
    /** Null until Room's first emission, so "not loaded yet" is not read as "no verifications". */
    private val jobsState: State<List<UseSmileIDSampleJob>?>,
    val jobStore: UseSmileIDSampleJobStore,
    val forms: UseSmileIDSampleForms,
    val profiles: UseSmileIDSampleProfiles,
    val launchArgs: UseSmileIDSampleLaunchArgs,
    val flowResult: UseSmileIDSampleFlowResult,
    val interruptedRun: UseSmileIDSampleInterruptedRun,
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
    val jobs: List<UseSmileIDSampleJob>? get() = jobsState.value

    val nowMillis: Long get() = now.value

    /** The session that ran out, once its token has been deleted. Carries no credential. */
    val endedSession: UseSmileIDSampleEndedSession? get() = endedSessionState.value

    /**
     * True from the deadline onwards. Reads the ended marker as well as the live session because the
     * token is deleted at expiry: the marker is what remains, and the brief window before the delete
     * lands is what the second half covers.
     */
    val sessionExpired: Boolean
        get() = endedSession != null || session?.hasExpired(nowMillis) == true

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
    val endedSessionState = store.endedSession.collectAsStateWithLifecycle(initialValue = null)
    val now = remember { mutableLongStateOf(System.currentTimeMillis()) }
    val jobStore = remember(context) { UseSmileIDSampleJobStore.of(context, RetrofitJobStatusSource()) }
    val jobsState = jobStore.jobs.collectAsStateWithLifecycle<List<UseSmileIDSampleJob>?>(initialValue = null)
    // Automation precondition, never an ordinary launch. Idempotent, so a recreation inserts nothing.
    LaunchedEffect(launchArgs.seedJobs) {
        if (launchArgs.seedJobs) jobStore.seedFixtures(System.currentTimeMillis())
    }
    val forms = rememberSaveable(saver = UseSmileIDSampleForms.Saver) { UseSmileIDSampleForms() }
    val profiles = remember { UseSmileIDSampleProfiles() }
    // Not saveable: the gate hands this straight to the scanner, and the scanner claims it into its
    // own saveable state on arrival, which is what has to survive a rotation mid-scan.
    val interruptedRun = remember { UseSmileIDSampleInterruptedRun() }
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
        // Past the deadline the token is useless, so it is deleted and only the fact of the session
        // is kept. Written on the app scope: a lapse noticed as this screen goes away must still land.
        // A cold start after expiry takes the same path, because the loop above exits immediately.
        UseSmileIDSampleJobStore.writeScope.launch { store.retireTokenSession(live) }
    }

    return UseSmileIDSampleAppState(
        store = store,
        storeScope = UseSmileIDSampleJobStore.writeScope,
        settingsState = settingsState,
        sessionState = sessionState,
        endedSessionState = endedSessionState,
        jobsState = jobsState,
        jobStore = jobStore,
        forms = forms,
        profiles = profiles,
        launchArgs = launchArgs,
        flowResult = flowResult,
        interruptedRun = interruptedRun,
        now = now,
    )
}

/** Provided once at the root, so a destination reads it without the graph threading it through. */
val LocalUseSmileIDSampleAppState = staticCompositionLocalOf<UseSmileIDSampleAppState> {
    error("No UseSmileIDSampleAppState provided")
}

private const val TICK_MILLIS = 1000L
