package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds

/** The debug scenario drawer: a shipped affordance, not test-only scaffolding. */
@Composable
fun ScenarioDrawerSheet(modifier: Modifier = Modifier) {
    PlaceholderScreen(UseSmileIDSampleTestIds.SCENARIO_DRAWER, "Scenarios", modifier = modifier)
}
