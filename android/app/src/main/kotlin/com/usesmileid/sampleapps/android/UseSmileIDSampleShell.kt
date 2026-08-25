package com.usesmileid.sampleapps.android

import android.content.Intent
import androidx.activity.ComponentActivity
import androidx.activity.compose.LocalActivity
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.ScaffoldDefaults
import androidx.navigation.compose.currentBackStackEntryAsState
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.runtime.remember
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.ui.Alignment
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.unit.IntOffset
import androidx.core.util.Consumer
import androidx.navigation.NavHostController
import androidx.navigation.compose.rememberNavController
import com.ramcosta.composedestinations.DestinationsNavHost
import com.ramcosta.composedestinations.generated.NavGraphs
import com.ramcosta.composedestinations.generated.destinations.ScanTokenScreenDestination
import com.ramcosta.composedestinations.generated.destinations.SdkFlowScreenDestination
import com.ramcosta.composedestinations.generated.navgraphs.ProductsNavGraph
import com.ramcosta.composedestinations.generated.navgraphs.SettingsNavGraph
import com.ramcosta.composedestinations.generated.navgraphs.VerificationsNavGraph
import com.ramcosta.composedestinations.navigation.DestinationsNavigator
import com.ramcosta.composedestinations.spec.DestinationSpec
import com.ramcosta.composedestinations.spec.Direction
import com.ramcosta.composedestinations.utils.currentDestinationAsState
import com.ramcosta.composedestinations.utils.rememberDestinationsNavigator
import com.ramcosta.composedestinations.utils.startDestination
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleNavTransitions
import androidx.compose.runtime.CompositionLocalProvider
import com.usesmileid.sampleapps.android.navigation.LocalUseSmileIDSampleChrome
import com.usesmileid.sampleapps.android.navigation.ProvideUseSmileIDSampleUrlOpener
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleChromeState
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSelectionBar
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleNavBar
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleNavItem

/**
 * Three tabs with preserved per-tab back stacks, plus the detached token affordance. The nav bar
 * shows only inside a tab graph, so a pushed screen or the SDK flow covers it without any screen
 * having to declare that it does.
 */
@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun UseSmileIDSampleShell() {
    val navController = rememberNavController()
    val navigator = navController.rememberDestinationsNavigator()
    val destination by navController.currentDestinationAsState()
    val selectedTab = destination?.tab()
    // Only ever written with a real tab: writing state from the composition body gets it skipped.
    var lastTab by remember { mutableStateOf(UseSmileIDSampleNavItem.Products) }
    LaunchedEffect(selectedTab) { lastTab = selectedTab ?: lastTab }
    val chrome = remember { UseSmileIDSampleChromeState() }

    ForwardNewIntentsTo(navController)
    AutostartFlowOnce(navigator)

    // The fullscreen flow handles its own insets, so the host contributes none (R3).
    val backStackEntry by navController.currentBackStackEntryAsState()
    val fullscreenFlow = backStackEntry?.let { entry ->
        entry.destination.route == SdkFlowScreenDestination.route &&
            SdkFlowScreenDestination.argsFrom(entry).route == UseSmileIDSampleFlowRoute.Fullscreen
    } == true

    Scaffold(
        // UI automation only sees Compose test tags once they are published as resource ids.
        modifier = Modifier.semantics { testTagsAsResourceId = true },
        contentWindowInsets = if (fullscreenFlow) WindowInsets(0) else ScaffoldDefaults.contentWindowInsets,
        bottomBar = {
            // Only select mode gets the slot: the slot insets the content, and the nav bar must not.
            chrome.selection?.let { selection ->
                UseSmileIDSampleSelectionBar(
                    selectedCount = selection.count,
                    onRemove = selection.onRemove,
                )
            }
        },
    ) { contentPadding ->
        val density = LocalDensity.current
        Box(modifier = Modifier.fillMaxSize()) {
            CompositionLocalProvider(LocalUseSmileIDSampleChrome provides chrome) {
                ProvideUseSmileIDSampleUrlOpener {
                    DestinationsNavHost(
                        navGraph = NavGraphs.root,
                        navController = navController,
                        defaultTransitions = UseSmileIDSampleNavTransitions,
                        modifier = Modifier.padding(contentPadding),
                    )
                }
            }
            // Over the content: reserving a row drew a seam with the last row clipped against it.
            AnimatedVisibility(
                visible = selectedTab != null,
                modifier = Modifier.align(Alignment.BottomCenter),
                enter = slideInVertically(NAV_BAR_SPEC) { it } + fadeIn(),
                exit = slideOutVertically(NAV_BAR_SPEC) { it } + fadeOut(),
            ) {
                val app = LocalUseSmileIDSampleAppState.current
                UseSmileIDSampleNavBar(
                    sessionProgress = app.session?.takeIf { app.sessionActive }?.progress(app.nowMillis),
                    selected = lastTab,
                    onSelect = { item ->
                        navigator.navigate(item.graph) {
                            popUpTo(NavGraphs.root.startDestination) { saveState = true }
                            launchSingleTop = true
                            restoreState = true
                        }
                    },
                    onTokenClick = {
                        navigator.navigate(ScanTokenScreenDestination) { launchSingleTop = true }
                    },
                    // Published so a screen can clear a bar it is not inset by.
                    modifier = Modifier.onSizeChanged {
                        chrome.navBarHeight = with(density) { it.height.toDp() }
                    },
                )
            }
        }
    }
}

/** Saveable rather than keyed on the argument: the intent is re-read on recreation, and navigating again would drag a rotated device out of where the run had reached. */
@Composable
private fun AutostartFlowOnce(navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    var started by rememberSaveable { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        val product = app.launchArgs.autostart
        if (started || product == null) return@LaunchedEffect
        started = true
        navigator.navigate(
            SdkFlowScreenDestination(productId = product.id, route = app.launchArgs.route),
        )
    }
}

/**
 * Cold start is handled when the graph is created; a warm deep link arrives as a new intent.
 *
 * A singleTop launcher relaunch lands here too, as a data-less `ACTION_MAIN`, so only the URI intents
 * the manifest's VIEW filter admits are forwarded — widen this for a `NavDeepLinkBuilder` intent, which
 * carries extras rather than data.
 */
@Composable
private fun ForwardNewIntentsTo(navController: NavHostController) {
    val activity = LocalActivity.current as? ComponentActivity ?: return
    DisposableEffect(activity, navController) {
        val listener = Consumer<Intent> { intent ->
            if (intent.action == Intent.ACTION_VIEW && intent.data != null) {
                navController.handleDeepLink(intent)
            }
        }
        activity.addOnNewIntentListener(listener)
        onDispose { activity.removeOnNewIntentListener(listener) }
    }
}

/** The tab a destination IS — its graph's START destination. Membership put a bar on a pushed detail screen. */
private fun DestinationSpec.tab(): UseSmileIDSampleNavItem? = when (this) {
    ProductsNavGraph.startDestination -> UseSmileIDSampleNavItem.Products
    VerificationsNavGraph.startDestination -> UseSmileIDSampleNavItem.Verifications
    SettingsNavGraph.startDestination -> UseSmileIDSampleNavItem.Settings
    else -> null
}

private val UseSmileIDSampleNavItem.graph: Direction
    get() = when (this) {
        UseSmileIDSampleNavItem.Products -> ProductsNavGraph
        UseSmileIDSampleNavItem.Verifications -> VerificationsNavGraph
        UseSmileIDSampleNavItem.Settings -> SettingsNavGraph
    }

/** Matches the route transition, so the bar and the screen move together. */
private val NAV_BAR_SPEC = tween<IntOffset>(durationMillis = 280)
