package com.usesmileid.sampleapps.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.foundation.BorderStroke
import androidx.compose.ui.graphics.Color
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.TrashGlyph
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleDataFieldRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleEmptyState
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleResultCard
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionLabel
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatusBadge
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBar
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBarButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBarEmphasis
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleResult
import com.usesmileid.sampleapps.ui.model.timeLabel
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/** One verification, and where the flow lands after submission. A missing job is a real state: a deep link can name one this build never had. */
@Composable
fun VerificationDetailsScreen(
    jobId: String,
    job: UseSmileIDSampleJob?,
    result: UseSmileIDSampleResult,
    onBack: () -> Unit,
    onDelete: () -> Unit,
    onCopy: (label: String, value: String) -> Unit,
    /**
     * Pull-to-refresh, which the design draws on this screen's processing state. Always wired rather
     * than hidden when a refresh cannot succeed: a gesture that silently does nothing reads as a bug,
     * so the outcome says why instead.
     */
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
                    // The id is kept in the supporting line: a deep link can name a job this build
                    // never had, and which id was asked for is the whole diagnostic.
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
                    Column(
                        modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
                        verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                    ) {
                        UseSmileIDSampleSectionLabel(text = "DETAILS")
                        Surface(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(SmileDimens.radiusSurface),
                            color = UseSmileIDSampleTheme.colors.surface,
                            border = BorderStroke(SmileDimens.borderWidthHairline, UseSmileIDSampleTheme.colors.card.border),
                        ) {
                            Column {
                                DetailRow("createdAt", "Created_at", job.createdAtLabel())
                                DetailRow("jobId", "Job_id", job.shortId, onCopy = { onCopy("Job ID", job.id) })
                                DetailRow("message", "Message", job.message)
                                // Coloured by the HTTP outcome, not the verdict: a blocked job still shows a green 200.
                                DetailRow("status", "Status", job.httpStatus, valueColor = job.httpStatusColor())
                                DetailRow("userId", "User_id", job.shortUserId, onCopy = { onCopy("User ID", job.userId) })
                                // Which partner submitted it, and against which environment. Both are
                                // carried on the row rather than read from the active profile: by the
                                // time anyone opens this screen either may have moved on.
                                if (job.profileOrganisation.isNotBlank()) {
                                    DetailRow("partner", "Partner", job.profileOrganisation)
                                }
                                DetailRow("environment", "Environment", if (job.sandbox) "Sandbox" else "Production")
                            }
                        }
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

/** Green while the call succeeded, red once it did not. A blank status is neither: colouring it red would invent a failure. */
@Composable
private fun UseSmileIDSampleJob.httpStatusColor(): Color? {
    val code = httpStatus.trimStart()
    if (code.isEmpty()) return null
    val badge = UseSmileIDSampleTheme.colors.badge
    return if (code.startsWith("2")) badge.successText else badge.errorText
}

/** ISO-8601 in UTC, matching the design's row: a machine-readable value, not a display date. */
private fun UseSmileIDSampleJob.createdAtLabel(): String =
    SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        .apply { timeZone = TimeZone.getTimeZone("UTC") }
        .format(Date(createdAtMillis))
