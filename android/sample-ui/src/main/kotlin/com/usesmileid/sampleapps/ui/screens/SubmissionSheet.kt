package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.UseSmileIDSampleStrings
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleBottomSheet
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleOptionRow
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleSubmission

/** config.skipApiSubmission's two values: submit the job, or hand the captured job back. */
@Composable
fun SubmissionSheet(
    selected: UseSmileIDSampleSubmission,
    onSelect: (UseSmileIDSampleSubmission) -> Unit,
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
) {
    UseSmileIDSampleBottomSheet(
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        title = UseSmileIDSampleStrings.submissionTitle,
        testId = UseSmileIDSampleTestIds.SUBMISSION_SHEET,
    ) {
        UseSmileIDSampleSubmission.entries.forEach { submission ->
            UseSmileIDSampleOptionRow(
                label = submission.label(),
                selected = submission == selected,
                onClick = { onSelect(submission) },
                testId = UseSmileIDSampleTestIds.submissionOption(submission.id),
            )
        }
    }
}

/** The row's name for this choice. */
@Composable
fun UseSmileIDSampleSubmission.label(): String = when (this) {
    UseSmileIDSampleSubmission.Submit -> UseSmileIDSampleStrings.submissionSubmit
    UseSmileIDSampleSubmission.Skip -> UseSmileIDSampleStrings.submissionSkip
}
