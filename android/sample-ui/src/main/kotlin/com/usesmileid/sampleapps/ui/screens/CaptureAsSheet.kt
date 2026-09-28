package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleBottomSheet
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleOptionRow
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCaptureAs

/** How the SDK photographs the document; choosing Custom hands over to the custom-document sheet. */
@Composable
fun CaptureAsSheet(
    selected: UseSmileIDSampleCaptureAs,
    onSelect: (UseSmileIDSampleCaptureAs) -> Unit,
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
) {
    UseSmileIDSampleBottomSheet(
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        title = "Capture as",
        testId = UseSmileIDSampleTestIds.CAPTURE_AS_SHEET,
    ) {
        UseSmileIDSampleCaptureAs.entries.forEach { option ->
            UseSmileIDSampleOptionRow(
                label = option.label,
                selected = option == selected,
                onClick = { onSelect(option) },
                testId = UseSmileIDSampleTestIds.captureAsOption(option.id),
            )
        }
    }
}
