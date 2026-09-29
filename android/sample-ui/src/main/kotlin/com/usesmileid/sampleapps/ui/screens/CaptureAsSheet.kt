package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleBottomSheet
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleOptionRow
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCaptureAs
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleResolvedCaptureAs

/** How the SDK photographs the document: Match document first, then the overrides; Generic document hands over to its sheet. */
@Composable
fun CaptureAsSheet(
    /** Null is Match document. */
    selected: UseSmileIDSampleCaptureAs?,
    /** What Match document resolves to for the chosen row, which its row names. */
    matched: UseSmileIDSampleResolvedCaptureAs,
    onSelect: (UseSmileIDSampleCaptureAs?) -> Unit,
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
) {
    UseSmileIDSampleBottomSheet(
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        title = "Capture as",
        testId = UseSmileIDSampleTestIds.CAPTURE_AS_SHEET,
    ) {
        UseSmileIDSampleOptionRow(
            label = matched.matchRowLabel,
            selected = selected == null,
            onClick = { onSelect(null) },
            testId = UseSmileIDSampleTestIds.captureAsOption(UseSmileIDSampleCaptureAs.MATCH_DOCUMENT_ID),
        )
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
