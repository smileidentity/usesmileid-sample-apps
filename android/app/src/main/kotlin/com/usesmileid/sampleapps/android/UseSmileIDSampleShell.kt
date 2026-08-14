package com.usesmileid.sampleapps.android

import android.content.Intent
import androidx.activity.ComponentActivity
import androidx.activity.compose.LocalActivity
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.core.util.Consumer
import androidx.navigation.NavHostController
import com.ramcosta.composedestinations.DestinationsNavHost
import com.ramcosta.composedestinations.generated.NavGraphs
import com.ramcosta.composedestinations.generated.destinations.ScanTokenScreenDestination
import com.ramcosta.composedestinations.generated.navgraphs.ProductsNavGraph
import com.ramcosta.composedestinations.generated.navgraphs.SettingsNavGraph
import com.ramcosta.composedestinations.generated.navgraphs.VerificationsNavGraph
import com.ramcosta.composedestinations.rememberNavHostEngine
import com.ramcosta.composedestinations.spec.DestinationSpec
import com.ramcosta.composedestinations.spec.Direction
import com.ramcosta.composedestinations.utils.contains
import com.ramcosta.composedestinations.utils.currentDestinationAsState
import com.ramcosta.composedestinations.utils.rememberDestinationsNavigator
import com.ramcosta.composedestinations.utils.startDestination
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
    val engine = rememberNavHostEngine()
    val navController = engine.rememberNavController()
    val navigator = navController.rememberDestinationsNavigator()
    val destination by navController.currentDestinationAsState()
    val selectedTab = destination?.tab()

    ForwardNewIntentsTo(navController)

    Scaffold(
        // UI automation only sees Compose test tags once they are published as resource ids.
        modifier = Modifier.semantics { testTagsAsResourceId = true },
        bottomBar = {
            if (selectedTab != null) {
                val app = LocalUseSmileIDSampleAppState.current
                UseSmileIDSampleNavBar(
                    sessionProgress = app.session?.takeIf { app.sessionActive }?.progress(app.nowMillis),
                    selected = selectedTab,
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
                )
            }
        },
    ) { contentPadding ->
        DestinationsNavHost(
            navGraph = NavGraphs.root,
            navController = navController,
            modifier = Modifier.padding(contentPadding),
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

/** The tab a destination belongs to, or null when it is not inside the shell. */
private fun DestinationSpec.tab(): UseSmileIDSampleNavItem? = when {
    ProductsNavGraph.contains(this) -> UseSmileIDSampleNavItem.Products
    VerificationsNavGraph.contains(this) -> UseSmileIDSampleNavItem.Verifications
    SettingsNavGraph.contains(this) -> UseSmileIDSampleNavItem.Settings
    else -> null
}

private val UseSmileIDSampleNavItem.graph: Direction
    get() = when (this) {
        UseSmileIDSampleNavItem.Products -> ProductsNavGraph
        UseSmileIDSampleNavItem.Verifications -> VerificationsNavGraph
        UseSmileIDSampleNavItem.Settings -> SettingsNavGraph
    }
