package com.usesmileid.sampleapps.android.navigation

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.android.BuildConfig
import com.usesmileid.sampleapps.android.LocalUseSmileIDSampleAppState
import com.usesmileid.sampleapps.android.extension.useSmileIDSampleShellExtension
import com.usesmileid.sampleapps.android.gallery.ComponentGalleryScreen as ComponentGalleryContent
import com.usesmileid.sampleapps.ui.screens.ScenarioDrawerSheet as ScenarioDrawerContent

/** The scenario drawer over Settings: its row is debug-only, but `/debug/scenarios` reaches it on every build, as device flows do. */
@Composable
internal fun ScenarioDrawerSheet(scope: UseSmileIDSampleStepScope) {
    // App-level, not sheet-local: the result card reports the same selection.
    val app = LocalUseSmileIDSampleAppState.current
    ScenarioDrawerContent(
        activeScenario = app.flowResult.scenario,
        activeTheme = app.flowResult.theme,
        onScenarioSelect = app.flowResult::selectScenario,
        onThemeSelect = app.flowResult::selectTheme,
        onDismissRequest = scope.navigator::back,
    )
}

/** Dev-only, and a shell screen by design: `sample-ui` never holds a gallery or a scratchpad. */
@Composable
internal fun ComponentGalleryScreen() {
    val chrome = LocalUseSmileIDSampleChrome.current
    ComponentGalleryContent(
        contentPadding = PaddingValues(bottom = chrome.navBarHeight + SmileDimens.spacingMd),
    )
}

/** A sheet the extension draws for one of its DEBUG rows; a release build, or one with no extension, closes it at once. */
@Composable
internal fun DebugSheet(scope: UseSmileIDSampleStepScope) {
    val extension = useSmileIDSampleShellExtension
    if (extension == null || !debugSheetOpens(BuildConfig.DEBUG, hasExtension = true)) {
        LaunchedEffect(Unit) { scope.navigator.back() }
        return
    }
    extension.DebugSheet(sheetId = scope.entry.arg.orEmpty(), onDismissRequest = scope.navigator::back)
}

/** Whether a debug sheet opens: only a debug build with an extension has one to draw. */
internal fun debugSheetOpens(debugBuild: Boolean, hasExtension: Boolean): Boolean = debugBuild && hasExtension
