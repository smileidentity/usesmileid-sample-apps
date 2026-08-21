package com.usesmileid.sampleapps.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.graphics.Color
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.TrashGlyph
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleDataFieldRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleEmptyState
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleResultCard
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionSurface
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatusBadge
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBar
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBarButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBarEmphasis
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleResult
import com.usesmileid.sampleapps.ui.model.createdAtLabel
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** One verification, and where the flow lands after submission. A missing job is a real state: a deep link can name one this build never had. */
@Composable
fun VerificationDetailsScreen(
    jobId: String,
    job: UseSmileIDSampleJob?,
    result: UseSmileIDSampleResult,
    onBack: () -> Unit,
    onDelete: () -> Unit,
    onCopy: (label: String, value: String) -> Unit,
    /** Pull-to-refresh, which the design draws in the processing state. Always wired: the outcome says why when it cannot succeed. */
    onRefresh: () -> Unit = {},
    refreshing: Boolean = false,
    modifier: Modifier = Modifier,
    contentPadding: PaddingValues = PaddingValues(),
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .testTag(UseSmileIDSampleTestIds.VERIFICATION_DETAILS_SCREEN),
    ) {
        UseSmileIDSampleTopAppBar(title = "Verification details", onBack = onBack) {
            if (job != null) {
                UseSmileIDSampleTopAppBarButton(
                    contentDescription = "Delete verification",
                    onClick = onDelete,
                    emphasis = UseSmileIDSampleTopAppBarEmphasis.Destructive,
                    testId = UseSmileIDSampleTestIds.DETAILS_DELETE,
                ) { tint -> TrashGlyph(tint = tint) }
            }
        }
        PullToRefreshBox(
            isRefreshing = refreshing,
            onRefresh = onRefresh,
            modifier = Modifier
                .weight(1f)
                .testTag(UseSmileIDSampleTestIds.DETAILS_REFRESH),
        ) {
            LazyColumn(
                contentPadding = contentPadding,
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
            ) {
            if (job == null) {
                item {
                    // The id stays in the supporting line: which one was asked for is the whole diagnostic.
                    UseSmileIDSampleEmptyState(
                        text = "No verification here",
                        supportingText = "Nothing stored for jobId = $jobId",
                        testId = UseSmileIDSampleTestIds.DETAILS_EMPTY,
                    )
                }
            } else {
                item {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingXs),
                        horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(
                                    text = job.product.label,
                            style = UseSmileIDSampleTheme.type.textStyleTitle,
                            color = UseSmileIDSampleTheme.colors.textTitle,
                            modifier = Modifier.weight(1f),
                        )
                        UseSmileIDSampleStatusBadge(
                            status = job.status,
                            testId = UseSmileIDSampleTestIds.STATUS_BADGE,
                        )
                    }
                }
                item {
                    UseSmileIDSampleSectionSurface(
                        modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
                        label = "DETAILS",
                    ) {
                        DetailRow("createdAt", "Created_at", job.createdAtLabel())
                        DetailRow("jobId", "Job_id", job.shortId, onCopy = { onCopy("Job ID", job.id) })
                        DetailRow("message", "Message", job.message)
                        // Coloured by the HTTP outcome, not the verdict: a blocked job still shows a green 200.
                        DetailRow("status", "Status", job.httpStatusLabel(), valueColor = job.httpStatusColor())
                        DetailRow("userId", "User_id", job.shortUserId, onCopy = { onCopy("User ID", job.userId) })
                    }
                }
            }
            // Rendered even with no job: a flow that failed before submission has nothing else to show.
            item {
                UseSmileIDSampleResultCard(
                    result = result,
                    modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
                )
                }
            }
        }
    }
}

@Composable
private fun DetailRow(
    field: String,
    label: String,
    value: String,
    onCopy: (() -> Unit)? = null,
    valueColor: Color? = null,
) {
    UseSmileIDSampleDataFieldRow(
        label = label,
        value = value,
        testId = UseSmileIDSampleTestIds.detailField(field),
        onCopy = onCopy,
        copyTestId = UseSmileIDSampleTestIds.detailCopy(field),
        valueColor = valueColor,
    )
}

/** The design's row shows "200 OK"; only the codes the app actually writes get a reason phrase. */
private fun UseSmileIDSampleJob.httpStatusLabel(): String = when (httpStatus) {
    null -> ""
    200 -> "200 OK"
    202 -> "202 Accepted"
    else -> httpStatus.toString()
}

/** Green while the call succeeded, red once it did not. No status is neither: colouring it red would invent a failure. */
@Composable
private fun UseSmileIDSampleJob.httpStatusColor(): Color? {
    val code = httpStatus ?: return null
    val badge = UseSmileIDSampleTheme.colors.badge
    return if (code in 200..299) badge.successText else badge.errorText
}
