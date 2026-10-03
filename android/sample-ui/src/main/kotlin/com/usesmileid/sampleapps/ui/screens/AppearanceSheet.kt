package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleBottomSheet
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleOptionRow
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleAppearance

/** The three appearances; System's label names [deviceDark], the device's own theme. */
@Composable
fun AppearanceSheet(
    selected: UseSmileIDSampleAppearance,
    deviceDark: Boolean,
    onSelect: (UseSmileIDSampleAppearance) -> Unit,
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
) {
    UseSmileIDSampleBottomSheet(
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        title = "Theme",
        testId = UseSmileIDSampleTestIds.APPEARANCE_SHEET,
    ) {
        UseSmileIDSampleAppearance.entries.forEach { appearance ->
            UseSmileIDSampleOptionRow(
                label = appearance.label(deviceDark),
                selected = appearance == selected,
                onClick = { onSelect(appearance) },
                testId = UseSmileIDSampleTestIds.appearanceOption(appearance.id),
            )
        }
    }
}
