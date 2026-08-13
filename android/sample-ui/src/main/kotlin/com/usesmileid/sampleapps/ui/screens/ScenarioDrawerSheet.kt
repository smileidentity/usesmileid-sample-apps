package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.SampleTestIds

/**
 * The debug scenario drawer. A shipped affordance, not test-only scaffolding: it and the launch
 * arguments are the two ways automation puts the app into a known state.
 */
@Composable
fun ScenarioDrawerSheet(modifier: Modifier = Modifier) {
    PlaceholderScreen(SampleTestIds.SCENARIO_DRAWER, "Scenarios", modifier = modifier)
}
