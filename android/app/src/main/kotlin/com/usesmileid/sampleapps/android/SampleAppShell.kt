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
import com.usesmileid.sampleapps.ui.components.SampleNavBar
import com.usesmileid.sampleapps.ui.components.SampleNavItem

/**
 * The navigation shell: three tabs with preserved per-tab back stacks, plus the detached token
 * affordance.
 *
 * The nav bar is shown only for destinations inside one of the three tab graphs, which is also
 * what decides the selected tab — so a pushed detail screen, a form or the SDK flow covers it
 * without any screen having to declare that it does.
 */
@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun SampleAppShell() {
    val engine = rememberNavHostEngine()
    val navController = engine.rememberNavController()
    val navigator = navController.rememberDestinationsNavigator()
    val destination by navController.currentDestinationAsState()
    val selectedTab = destination?.tab()

    ForwardNewIntentsTo(navController)

    Scaffold(
        // Compose test tags are invisible to UI automation unless they are published as resource
        // ids. Device flows assert on sample_* ids, so this line is load-bearing.
        modifier = Modifier.semantics { testTagsAsResourceId = true },
        bottomBar = {
            if (selectedTab != null) {
                SampleNavBar(
                    selected = selectedTab,
                    onSelect = { item ->
                        navigator.navigate(item.graph) {
                            // The multi-back-stack recipe: pop to the root's start destination
                            // saving each tab's stack, then restore the target tab's.
                            popUpTo(NavGraphs.root.startDestination) { saveState = true }
                            launchSingleTop = true
                            restoreState = true
                        }
                    },
                    onTokenClick = {
                        // Single top: the affordance is reachable from all three tabs, and
                        // tapping it twice should not stack two scan screens.
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
 * The launch intent is handled by the NavController when the graph is created, which covers cold
 * start. A warm start does not go through that path: the activity is `singleTop`, so a second
 * deep link arrives as a new intent and is silently dropped unless it is forwarded — the app
 * stays exactly where it was while looking like the link worked.
 */
@Composable
private fun ForwardNewIntentsTo(navController: NavHostController) {
    val activity = LocalActivity.current as? ComponentActivity ?: return
    DisposableEffect(activity, navController) {
        val listener = Consumer<Intent> { intent -> navController.handleDeepLink(intent) }
        activity.addOnNewIntentListener(listener)
        onDispose { activity.removeOnNewIntentListener(listener) }
    }
}

/** The tab a destination belongs to, or null when it is not inside the shell. */
private fun DestinationSpec.tab(): SampleNavItem? = when {
    ProductsNavGraph.contains(this) -> SampleNavItem.Products
    VerificationsNavGraph.contains(this) -> SampleNavItem.Verifications
    SettingsNavGraph.contains(this) -> SampleNavItem.Settings
    else -> null
}

private val SampleNavItem.graph: Direction
    get() = when (this) {
        SampleNavItem.Products -> ProductsNavGraph
        SampleNavItem.Verifications -> VerificationsNavGraph
        SampleNavItem.Settings -> SettingsNavGraph
    }
