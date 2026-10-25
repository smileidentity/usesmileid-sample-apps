package com.usesmileid.sampleapps.android

import android.content.Intent
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.LocalActivity
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.ScaffoldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.unit.IntOffset
import androidx.core.util.Consumer
import androidx.lifecycle.viewmodel.compose.viewModel
import com.usesmileid.njia.NjiaPresentation
import com.usesmileid.njia.NjiaState
import com.usesmileid.njia.compose.NjiaHost
import com.usesmileid.njia.compose.NjiaSheetStyle
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import com.usesmileid.njia.compose.rememberNjiaState
import com.usesmileid.njia.select
import com.usesmileid.njia.stepOf
import com.usesmileid.njia.isDone
import com.usesmileid.njia.tabBar
import com.usesmileid.sampleapps.android.extension.linkLaunchSession
import com.usesmileid.sampleapps.android.extension.useSmileIDSampleShellExtension
import com.usesmileid.sampleapps.android.flow.runOnly
import com.usesmileid.sampleapps.android.flow.tokenBindsIdDetails
import com.usesmileid.sampleapps.android.navigation.ComponentGalleryScreen
import com.usesmileid.sampleapps.android.navigation.LocalUseSmileIDSampleChrome
import com.usesmileid.sampleapps.android.navigation.LocalUseSmileIDSampleEngine
import com.usesmileid.sampleapps.android.navigation.ProvideUseSmileIDSampleUrlOpener
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleChromeState
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleDeepLinks
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleEngine
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleFact
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleLink
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleNavigationModel
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleStep
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleSteps
import com.usesmileid.sampleapps.android.navigation.go
import com.usesmileid.sampleapps.android.navigation.startRun
import com.usesmileid.sampleapps.android.navigation.useSmileIDSampleFacts
import com.usesmileid.sampleapps.ui.components.LocalUseSmileIDSampleNoticeWindow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleNavBar
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleNavItem
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSelectionBar
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.njia.NjiaNavigator
import kotlin.time.Duration.Companion.seconds
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withTimeoutOrNull

/** njia draws the three tabs' stacks from `spec/njia-graph.json`; each tab's root floats the nav bar over itself, and the shell opens links. */
@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun UseSmileIDSampleShell() {
    val model: UseSmileIDSampleNavigationModel = viewModel()
    val engine = model.engine
    val state by rememberNjiaState(engine)
    val chrome = remember { UseSmileIDSampleChromeState() }
    var galleryOpen by rememberSaveable { mutableStateOf(false) }

    // Seconds in the argument, millis in the local: the notice host counts in millis.
    val noticeWindowMillis = LocalUseSmileIDSampleAppState.current.launchArgs.noticeWindow
        ?.let { it * 1_000L }
        ?: LocalUseSmileIDSampleNoticeWindow.current

    val openLink = rememberLinkOpener(model) { galleryOpen = true }
    OpenLaunchLinkOnce(model, openLink)
    LeaveOnRootBack(model, state.isDone)
    ForwardNewIntentsTo(openLink)
    AutostartFlowOnce(model)

    val top = state.entries.lastOrNull()?.let(engine::stepOf)
    // The fullscreen flow handles its own insets, so the host contributes none (R3).
    val fullscreenFlow = top?.kind == UseSmileIDSampleStep.SdkFlowFullScreen

    Scaffold(
        // UI automation only sees Compose test tags once they are published as resource ids.
        modifier = Modifier.semantics { testTagsAsResourceId = true },
        contentWindowInsets = if (fullscreenFlow) WindowInsets(0) else ScaffoldDefaults.contentWindowInsets,
        bottomBar = {
            // Only select mode gets the slot: the slot insets the content, and the nav bar must not.
            chrome.selection?.let { selection ->
                UseSmileIDSampleSelectionBar(selectedCount = selection.count, onRemove = selection.onRemove)
            }
        },
    ) { contentPadding ->
        Box(modifier = Modifier.fillMaxSize()) {
            CompositionLocalProvider(
                LocalUseSmileIDSampleChrome provides chrome,
                LocalUseSmileIDSampleEngine provides engine,
                // Only automation passes one; without it the local's default is the product's.
                LocalUseSmileIDSampleNoticeWindow provides noticeWindowMillis,
            ) {
                ProvideUseSmileIDSampleUrlOpener {
                    if (galleryOpen) {
                        BackHandler { galleryOpen = false }
                        Box(Modifier.padding(contentPadding).consumeWindowInsets(contentPadding)) { ComponentGalleryScreen() }
                    } else {
                        NjiaHost(
                            engine = engine,
                            steps = UseSmileIDSampleSteps,
                            // The design's own scrim and corners, which njia's default sheet style would replace.
                            sheetStyle = NjiaSheetStyle(UseSmileIDSampleTheme.colors.overlayScrim, UseSmileIDSampleTheme.shapes.sheet),
                            // Consumed, or every screen and the SDK under the shell pad the same inset again.
                            modifier = Modifier.padding(contentPadding).consumeWindowInsets(contentPadding),
                        )
                    }
                }
            }
        }
    }
}

/** The floating nav bar a tab's root draws over itself, so a sheet over the root covers the bar as it covers the root. */
@Composable
internal fun UseSmileIDSampleTabRootBar(tab: UseSmileIDSampleNavItem, navigator: NjiaNavigator, modifier: Modifier) {
    val app = LocalUseSmileIDSampleAppState.current
    val engine = LocalUseSmileIDSampleEngine.current
    val chrome = LocalUseSmileIDSampleChrome.current
    val density = LocalDensity.current
    // Select mode replaces the bottom chrome: the design has no nav bar behind the selection bar.
    if (chrome.selection != null) return
    UseSmileIDSampleNavBar(
        sessionProgress = app.session?.takeIf { app.sessionActive }?.progress(app.nowMillis),
        selected = tab,
        onSelect = { item -> engine.select(item.step.wireName) },
        onTokenClick = { navigator.go(UseSmileIDSampleStep.ScanToken) },
        // Published so a screen can clear a bar it is not inset by.
        modifier = modifier.onSizeChanged { chrome.navBarHeight = with(density) { it.height.toDp() } },
    )
}

/** The tab root each nav bar item selects. */
internal val UseSmileIDSampleNavItem.step: UseSmileIDSampleStep
    get() = when (this) {
        UseSmileIDSampleNavItem.Products -> UseSmileIDSampleStep.Products
        UseSmileIDSampleNavItem.Verifications -> UseSmileIDSampleStep.Verifications
        UseSmileIDSampleNavItem.Settings -> UseSmileIDSampleStep.Settings
    }

/** Opens an app URI as a new flow, under the facts its product runs with, or the dev gallery for its link. */
@Composable
private fun rememberLinkOpener(model: UseSmileIDSampleNavigationModel, openGallery: () -> Unit): (String) -> Unit {
    val app by rememberUpdatedState(LocalUseSmileIDSampleAppState.current)
    return remember(model) {
        { uri ->
            if (uri.substringBefore('?').substringBefore('#').trimEnd('/') == UseSmileIDSampleDeepLinks.COMPONENT_GALLERY) {
                openGallery()
            } else {
                UseSmileIDSampleDeepLinks.linkOf(uri)?.let { link -> model.open(link.path, app.factsFor(link)) }
            }
        }
    }
}

/** The facts a link's run starts with: its product's, on the route it asked for, or the launch's. */
private fun UseSmileIDSampleAppState.factsFor(link: UseSmileIDSampleLink): Set<UseSmileIDSampleFact> {
    val product = UseSmileIDSampleProduct.entries.firstOrNull { it.id == UseSmileIDSampleDeepLinks.productIdOf(link) } ?: return emptySet()
    return useSmileIDSampleFacts(product, tokenBindsIdDetails(product), link.route ?: launchArgs.route)
}

/** Back from the products tab's root finishes the flow: the app goes to the background, as a root back does, and comes back on a fresh one. */
@Composable
private fun LeaveOnRootBack(model: UseSmileIDSampleNavigationModel, done: Boolean) {
    val activity = LocalActivity.current
    LaunchedEffect(done) {
        if (!done) return@LaunchedEffect
        model.restart()
        activity?.moveTaskToBack(true)
    }
}

/** The launching intent's link, once: saveable, and skipped when the flow came back from saved state. */
@Composable
private fun OpenLaunchLinkOnce(model: UseSmileIDSampleNavigationModel, openLink: (String) -> Unit) {
    val activity = LocalActivity.current ?: return
    var opened by rememberSaveable { mutableStateOf(model.restored) }
    LaunchedEffect(Unit) {
        if (opened) return@LaunchedEffect
        opened = true
        activity.intent?.takeIf { it.action == Intent.ACTION_VIEW }?.data?.toString()?.let(openLink)
    }
}

/** A warm deep link arrives as a new intent; a singleTop launcher relaunch is a data-less `ACTION_MAIN` and is left alone. */
@Composable
private fun ForwardNewIntentsTo(openLink: (String) -> Unit) {
    val activity = LocalActivity.current as? ComponentActivity ?: return
    DisposableEffect(activity, openLink) {
        val listener = Consumer<Intent> { intent ->
            val data = intent.data
            if (intent.action == Intent.ACTION_VIEW && data != null) openLink(data.toString())
        }
        activity.addOnNewIntentListener(listener)
        onDispose { activity.removeOnNewIntentListener(listener) }
    }
}

/** Saveable rather than keyed on the argument: the intent is re-read on recreation, and starting again would drag a rotated device out of where the run had reached. */
@Composable
private fun AutostartFlowOnce(model: UseSmileIDSampleNavigationModel) {
    val app = LocalUseSmileIDSampleAppState.current
    var started by rememberSaveable { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        if (started) return@LaunchedEffect
        // Linked and loaded before autostart, which snapshots the session as the flow opens; marked after, so a recreation mid-link redoes it.
        linkLaunchSession(useSmileIDSampleShellExtension, app.store::linkTokenSession)?.let { linked ->
            // The write has landed and only the store's emission is awaited; it trails by seconds while the first frames jank.
            withTimeoutOrNull(LINKED_SESSION_WAIT) { snapshotFlow { app.session?.id }.first { it == linked.id } }
        }
        started = true
        val product = app.launchArgs.autostart ?: return@LaunchedEffect
        withTimeoutOrNull(LAUNCH_SESSION_WAIT) { snapshotFlow { app.sessionLoaded }.first { it } }
        // Read now, not at composition: a launch link opened during the waits swaps the engine.
        val engine = model.engine
        engine.startRun(engine.state.entries.last(), product, app.runOnly(product, app.launchArgs.route))
    }
}

private val LAUNCH_SESSION_WAIT = 5.seconds

/** Bounds a wait on a write that already landed, so only a store that never emits ends it; 5 s sent cold launches to the scanner. */
private val LINKED_SESSION_WAIT = 30.seconds
