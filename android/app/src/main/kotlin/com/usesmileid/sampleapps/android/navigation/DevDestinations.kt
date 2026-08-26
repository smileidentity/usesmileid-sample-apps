package com.usesmileid.sampleapps.android.navigation

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.runtime.Composable
import com.ramcosta.composedestinations.annotation.Destination
import com.ramcosta.composedestinations.annotation.RootGraph
import com.ramcosta.composedestinations.annotation.parameters.DeepLink
import com.ramcosta.composedestinations.navigation.DestinationsNavigator
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.android.LocalUseSmileIDSampleAppState
import com.usesmileid.sampleapps.android.gallery.ComponentGalleryScreen as ComponentGalleryContent
import com.usesmileid.sampleapps.ui.screens.ScenarioDrawerSheet as ScenarioDrawerContent

/** The dev-only routes. Function names are load-bearing: KSP names each generated `…Destination` after the function. */

/**
 * A layer Settings owns; it is not a destination (R12). Its Settings row is debug-only but this is not:
 * `/debug/scenarios` is how every device flow reaches it, release included.
 */
@Composable
internal fun ScenarioDrawerSheet(onDismissRequest: () -> Unit) {
    // App-level, not sheet-local: the result card reports the same selection.
    val app = LocalUseSmileIDSampleAppState.current
    ScenarioDrawerContent(
        activeScenario = app.flowResult.scenario,
        activeTheme = app.flowResult.theme,
        onScenarioSelect = app.flowResult::selectScenario,
        onThemeSelect = app.flowResult::selectTheme,
        onDismissRequest = onDismissRequest,
    )
}

/** Dev-only, and a shell route by design: `sample-ui` never holds a gallery or a scratchpad. */
@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.COMPONENT_GALLERY)])
@Composable
fun ComponentGalleryScreen() {
    val chrome = LocalUseSmileIDSampleChrome.current
    ComponentGalleryContent(
        contentPadding = PaddingValues(bottom = chrome.navBarHeight + SmileDimens.spacingMd),
    )
}
