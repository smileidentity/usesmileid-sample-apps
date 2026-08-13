package com.usesmileid.sampleapps.ui.screens

import androidx.compose.foundation.layout.Column
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleBottomSheet
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleOptionRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionLabel
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario

/** A shipped affordance, not scaffolding. Theme scenarios apply on top of the flow scenario, so the two are separate selections. */
@Composable
fun ScenarioDrawerSheet(
    activeScenario: UseSmileIDSampleScenario,
    activeTheme: UseSmileIDSampleThemeScenario,
    onScenarioSelect: (UseSmileIDSampleScenario) -> Unit,
    onThemeSelect: (UseSmileIDSampleThemeScenario) -> Unit,
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
) {
    UseSmileIDSampleBottomSheet(
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        title = "Scenarios",
        testId = UseSmileIDSampleTestIds.SCENARIO_DRAWER,
    ) {
        UseSmileIDSampleSectionLabel(text = "FLOW")
        Column {
            UseSmileIDSampleScenario.entries.forEach { scenario ->
                UseSmileIDSampleOptionRow(
                    label = scenario.label,
                    selected = scenario == activeScenario,
                    onClick = { onScenarioSelect(scenario) },
                    testId = UseSmileIDSampleTestIds.scenarioItem(scenario.id),
                )
            }
        }
        UseSmileIDSampleSectionLabel(text = "THEME")
        Column {
            UseSmileIDSampleThemeScenario.entries.forEach { theme ->
                UseSmileIDSampleOptionRow(
                    label = theme.label,
                    selected = theme == activeTheme,
                    onClick = { onThemeSelect(theme) },
                    testId = UseSmileIDSampleTestIds.themeItem(theme.id),
                )
            }
        }
    }
}
