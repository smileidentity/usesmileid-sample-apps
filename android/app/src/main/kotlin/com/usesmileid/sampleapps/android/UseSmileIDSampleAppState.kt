package com.usesmileid.sampleapps.android

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.State
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.remember
import kotlinx.coroutines.CoroutineScope
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.compose.runtime.saveable.rememberSaveable
import android.content.Context
import com.usesmileid.sampleapps.android.catalogue.RetrofitCatalogueSource
import com.usesmileid.sampleapps.android.status.RetrofitJobStatusSource
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleCatalogueSource
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleCatalogueStore
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleFixtureCatalogueSource
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleSessionAwareCatalogueSource
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleUnreachableCatalogueSource
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueMode
import java.util.Locale
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleFlowResult
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleForms
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleInterruptedRun
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleJobStore
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleLaunchArgs
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleProfiles
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleAppearance
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleSettings
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleStore
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleEndedSession
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleSessionRecord
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import com.usesmileid.sampleapps.ui.state.catalogueFamily
import androidx.compose.runtime.staticCompositionLocalOf
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.first
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleProfilesRecord
import kotlinx.coroutines.launch

/** Everything the shell hoists: persisted settings, the token session, and the clock that ticks it. */
class UseSmileIDSampleAppState(
    val store: UseSmileIDSampleStore,
    /** Process-lifetime: neither navigation nor activity recreation can cancel a write mid-flight. */
    val storeScope: CoroutineScope,
    private val settingsState: State<UseSmileIDSampleSettings>,
    /** One value, so the live session and the ended marker can never come from different writes. */
    /** Null until the store's first read, so a cold link into a run cannot mistake a stored session for none. */
    private val sessionState: State<UseSmileIDSampleSessionRecord?>,
    /** Null until Room's first emission, so "not loaded yet" is not read as "no verifications". */
    private val jobsState: State<List<UseSmileIDSampleJob>?>,
    val jobStore: UseSmileIDSampleJobStore,
    val forms: UseSmileIDSampleForms,
    val profiles: UseSmileIDSampleProfiles,
    val launchArgs: UseSmileIDSampleLaunchArgs,
    val flowResult: UseSmileIDSampleFlowResult,
    val interruptedRun: UseSmileIDSampleInterruptedRun,
    /** The ID form's lists for the current run; the `catalogue` launch argument picks where they come from. */
    val catalogue: UseSmileIDSampleCatalogueStore,
    /**
     * Read through [State] rather than held as a value, so the once-a-second tick recomposes only
     * what reads the clock. Held as a value it changed this object's identity every second, and
     * because it is provided through a `staticCompositionLocalOf` that invalidated the whole tree —
     * the hosted SDK flow included, where the SDK re-runs `build()` on every recomposition.
     */
    private val now: State<Long>,
    /** The device's own theme, read at the Activity, which never forces night mode. */
    val deviceDark: Boolean,
) {
    val settings: UseSmileIDSampleSettings get() = settingsState.value

    /** What the app renders: the theme, the bars and the SDK all read this one value. */
    val resolvedDark: Boolean get() = settings.appearance.isDark(deviceDark)
    val session: UseSmileIDSampleTokenSession? get() = sessionState.value?.live

    /** Whether the stored session has been read; nothing may decide the run needs a token before it has. */
    val sessionLoaded: Boolean get() = sessionState.value != null
    val jobs: List<UseSmileIDSampleJob>? get() = jobsState.value

    val nowMillis: Long get() = now.value

    /** The session that ran out, once its token has been deleted. Carries no credential. */
    val endedSession: UseSmileIDSampleEndedSession? get() = sessionState.value?.ended

    /** True from the deadline on. Reads the marker too, since the token is deleted at expiry. */
    val sessionExpired: Boolean
        get() = endedSession != null || session?.hasExpired(nowMillis) == true

    val sessionActive: Boolean get() = session?.hasExpired(nowMillis) == false

    /** The only place the environment is decided. The linked session owns it; no session is sandbox, which is every automation run. */
    val useSandbox: Boolean get() = session?.environment != UseSmileIDSampleEnvironment.Production

    /** Where the catalogue asks: the session's environment, as status refresh chooses it. */
    val environment: UseSmileIDSampleEnvironment
        get() = if (useSandbox) UseSmileIDSampleEnvironment.Sandbox else UseSmileIDSampleEnvironment.Production

    /** The API translates document and country names; an unsupported locale comes back in en-GB. */
    val catalogueLocale: String get() = Locale.getDefault().toLanguageTag()

    /** Starts [product]'s lists if nothing has; Enhanced Document Verification's also needs the session's own list. */
    fun ensureCatalogue(product: UseSmileIDSampleProduct?) {
        if (product?.catalogueFamily == null) return
        catalogue.ensure(environment, catalogueLocale)
        if (product == UseSmileIDSampleProduct.EnhancedDocumentVerification) {
            catalogue.ensureEnabled(environment, catalogueLocale, session)
        }
    }
}

/** Ticks once a second while a session is live. The deadline is absolute, so a restored session needs no recomputing. */
@Composable
fun rememberUseSmileIDSampleAppState(
    launchArgs: UseSmileIDSampleLaunchArgs,
    deviceDark: Boolean,
): UseSmileIDSampleAppState {
    val context = LocalContext.current
    val store = remember(context) { UseSmileIDSampleStore(context) }
    // Saved across recreation: a sheet restored on the first frame fixes its bar icons then, before the store has answered.
    var savedAppearance by rememberSaveable { mutableStateOf(UseSmileIDSampleAppearance.System) }
    val settingsState = store.settings.collectAsStateWithLifecycle(
        initialValue = UseSmileIDSampleSettings(appearance = savedAppearance),
    )
    LaunchedEffect(settingsState.value.appearance) { savedAppearance = settingsState.value.appearance }
    val sessionState = store.session.collectAsStateWithLifecycle<UseSmileIDSampleSessionRecord?>(initialValue = null)
    val now = remember { mutableLongStateOf(System.currentTimeMillis()) }
    val jobStore = remember(context) { UseSmileIDSampleJobStore.of(context, RetrofitJobStatusSource()) }
    val jobsState = jobStore.jobs.collectAsStateWithLifecycle<List<UseSmileIDSampleJob>?>(initialValue = null)
    // Automation precondition, never an ordinary launch. Idempotent, so a recreation inserts nothing.
    LaunchedEffect(launchArgs.seedJobs) {
        if (launchArgs.seedJobs) jobStore.seedFixtures(System.currentTimeMillis())
    }
    val forms = rememberSaveable(saver = UseSmileIDSampleForms.Saver) { UseSmileIDSampleForms() }
    val profiles = remember(launchArgs) { UseSmileIDSampleProfilesHolder.profilesFor(launchArgs, store) }
    LaunchedEffect(profiles) { if (!profiles.loaded) profiles.restore(store.profiles.first()) }
    LaunchedEffect(store) { store.sealLegacyToken() }
    val catalogue = remember(context, launchArgs.catalogue) {
        UseSmileIDSampleCatalogueStore(catalogueSource(context, launchArgs.catalogue), UseSmileIDSampleJobStore.writeScope)
    }
    // Not saveable: the scanner claims it into its own saveable state, which survives a rotation.
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
    LaunchedEffect(sessionState.value?.live) {
        val live = sessionState.value?.live ?: return@LaunchedEffect
        while (!live.hasExpired(now.longValue)) {
            now.longValue = System.currentTimeMillis()
            delay(TICK_MILLIS)
        }
        // Past the deadline the token is useless. On the app scope so a lapse still lands as this
        // screen goes away; a cold start after expiry takes the same path, the loop exiting at once.
        UseSmileIDSampleJobStore.writeScope.launch { store.retireTokenSession(live) }
    }

    return UseSmileIDSampleAppState(
        store = store,
        storeScope = UseSmileIDSampleJobStore.writeScope,
        settingsState = settingsState,
        sessionState = sessionState,
        jobsState = jobsState,
        jobStore = jobStore,
        forms = forms,
        profiles = profiles,
        launchArgs = launchArgs,
        flowResult = flowResult,
        interruptedRun = interruptedRun,
        catalogue = catalogue,
        now = now,
        deviceDark = deviceDark,
    )
}

/** Provided once at the root, so a destination reads it without the graph threading it through. */
val LocalUseSmileIDSampleAppState = staticCompositionLocalOf<UseSmileIDSampleAppState> {
    error("No UseSmileIDSampleAppState provided")
}

private const val TICK_MILLIS = 1000L

/** `fixture` reads the copy of spec/catalogue-fixture.json the build bundles, so no flow touches the network. */
private fun catalogueSource(context: Context, mode: UseSmileIDSampleCatalogueMode): UseSmileIDSampleCatalogueSource =
    when (mode) {
        UseSmileIDSampleCatalogueMode.Live -> UseSmileIDSampleSessionAwareCatalogueSource(RetrofitCatalogueSource(), fixtureSource(context))
        UseSmileIDSampleCatalogueMode.Unreachable -> UseSmileIDSampleUnreachableCatalogueSource
        UseSmileIDSampleCatalogueMode.Fixture -> fixtureSource(context)
    }

private fun fixtureSource(context: Context) = UseSmileIDSampleFixtureCatalogueSource(
    context.assets.open(CATALOGUE_FIXTURE_ASSET).bufferedReader().use { it.readText() },
)

private const val CATALOGUE_FIXTURE_ASSET = "catalogue-fixture.json"

/** Process-wide, so a recreated activity keeps the loaded profiles and their one writer. */
private object UseSmileIDSampleProfilesHolder {
    private val writes = MutableStateFlow<Pair<UseSmileIDSampleStore, UseSmileIDSampleProfilesRecord>?>(null)
    private var current: Pair<UseSmileIDSampleLaunchArgs, UseSmileIDSampleProfiles>? = null

    init {
        UseSmileIDSampleJobStore.writeScope.launch {
            writes.filterNotNull().collect { (store, record) -> store.setProfiles(record) }
        }
    }

    fun profilesFor(args: UseSmileIDSampleLaunchArgs, store: UseSmileIDSampleStore): UseSmileIDSampleProfiles =
        current?.takeIf { it.first == args }?.second
            ?: UseSmileIDSampleProfiles.forLaunch(args) { writes.value = store to it }.also { current = args to it }
}
