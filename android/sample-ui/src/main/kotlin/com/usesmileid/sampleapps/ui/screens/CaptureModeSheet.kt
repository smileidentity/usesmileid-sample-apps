package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.UseSmileIDSampleStrings
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleBottomSheet
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleOptionRow
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCaptureMode

/** DocumentCaptureConfig.captureMode's three values; the fallback keeps the SDK's 10 seconds. */
@Composable
fun CaptureModeSheet(
    selected: UseSmileIDSampleCaptureMode,
    onSelect: (UseSmileIDSampleCaptureMode) -> Unit,
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
) {
    UseSmileIDSampleBottomSheet(
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        title = UseSmileIDSampleStrings.captureModeTitle,
        testId = UseSmileIDSampleTestIds.CAPTURE_MODE_SHEET,
    ) {
        UseSmileIDSampleCaptureMode.entries.forEach { mode ->
            UseSmileIDSampleOptionRow(
                label = mode.label(),
                selected = mode == selected,
                onClick = { onSelect(mode) },
                testId = UseSmileIDSampleTestIds.captureModeOption(mode.id),
            )
        }
    }
}

/** The row's name for this mode. */
@Composable
fun UseSmileIDSampleCaptureMode.label(): String = when (this) {
    UseSmileIDSampleCaptureMode.Auto -> UseSmileIDSampleStrings.captureModeAuto
    UseSmileIDSampleCaptureMode.Manual -> UseSmileIDSampleStrings.captureModeManual
    UseSmileIDSampleCaptureMode.AutoWithFallback -> UseSmileIDSampleStrings.captureModeAutoWithFallback
}
