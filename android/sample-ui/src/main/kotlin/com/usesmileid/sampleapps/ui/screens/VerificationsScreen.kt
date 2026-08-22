package com.usesmileid.sampleapps.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.Text
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleDateGroupHeader
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleEmptyState
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleFilterChip
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleJobRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSelectionCheckbox
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSwipeAction
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJobFilter
import com.usesmileid.sampleapps.ui.model.groupByDay
import com.usesmileid.sampleapps.ui.model.timeLabel
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** Everything the list renders, so the screen owns no clock, store or selection of its own. */
data class UseSmileIDSampleVerificationsState(
    /** Null until the rows have loaded, so an empty state cannot be drawn over a list that is coming. */
    val jobs: List<UseSmileIDSampleJob>?,
    val counts: Map<UseSmileIDSampleJobFilter, Int>,
    val filter: UseSmileIDSampleJobFilter = UseSmileIDSampleJobFilter.All,
    val selectMode: Boolean = false,
    val selected: Set<String> = emptySet(),
    val nowMillis: Long,
)

/** The verifications, grouped by day. Counts come from the whole list, because the count dropping is what proves a delete. */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun VerificationsScreen(
    state: UseSmileIDSampleVerificationsState,
    onFilterChange: (UseSmileIDSampleJobFilter) -> Unit,
    onSelectModeChange: (Boolean) -> Unit,
    onSelectionChange: (String, Boolean) -> Unit,
    onJobClick: (UseSmileIDSampleJob) -> Unit,
    onRemove: (Set<String>) -> Unit,
    modifier: Modifier = Modifier,
    contentPadding: PaddingValues = PaddingValues(),
) {
    val visible = state.jobs.orEmpty().filter(state.filter::matches)
    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .testTag(UseSmileIDSampleTestIds.VERIFICATIONS_SCREEN)
            .windowInsetsPadding(WindowInsets.statusBars),
        contentPadding = contentPadding,
        verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
    ) {
        item {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingXs),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = "Verifications",
                    style = UseSmileIDSampleTheme.type.textStyleHeadingPage,
                    color = UseSmileIDSampleTheme.colors.textTitle,
                    modifier = Modifier.weight(1f),
                )
                Text(
                    text = if (state.selectMode) "Cancel" else "Select",
                    style = UseSmileIDSampleTheme.type.linkFont.copy(fontWeight = FontWeight.Bold),
                    color = UseSmileIDSampleTheme.colors.primary,
                    softWrap = false,
                    modifier = Modifier
                        .testTag(UseSmileIDSampleTestIds.SELECT_TOGGLE)
                        .clickable(role = Role.Button) { onSelectModeChange(!state.selectMode) }
                        .minimumInteractiveComponentSize()
                        .padding(horizontal = SmileDimens.spacingXs),
                )
            }
        }

        item {
            FlowRow(
                modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
                horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
            ) {
                UseSmileIDSampleJobFilter.entries.forEach { filter ->
                    UseSmileIDSampleFilterChip(
                        label = filter.label,
                        count = state.counts[filter] ?: 0,
                        selected = filter == state.filter,
                        onClick = { onFilterChange(filter) },
                        testId = UseSmileIDSampleTestIds.filterChip(filter.id),
                        countTestId = UseSmileIDSampleTestIds.filterCount(filter.id),
                    )
                }
            }
        }

        // Two messages: "nothing yet" and "nothing matching this filter" are different things to be told.
        if (state.jobs != null && visible.isEmpty()) {
            item {
                if (state.jobs.isEmpty()) {
                    UseSmileIDSampleEmptyState(
                        text = "No verifications yet",
                        supportingText = "Start a product above and the job lands here.",
                        testId = UseSmileIDSampleTestIds.VERIFICATIONS_EMPTY,
                    )
                } else {
                    UseSmileIDSampleEmptyState(
                        text = "Nothing ${state.filter.label.lowercase()}",
                        supportingText = "Other filters still have verifications.",
                        testId = UseSmileIDSampleTestIds.VERIFICATIONS_EMPTY,
                    )
                }
            }
        }

        visible.groupByDay(state.nowMillis).forEach { day ->
            item {
                UseSmileIDSampleDateGroupHeader(
                    relative = day.relative,
                    absolute = day.absolute,
                    modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
                )
            }
            itemsIndexedByJob(day.jobs, visible) { index, job ->
                JobListRow(
                    job = job,
                    index = index,
                    selectMode = state.selectMode,
                    checked = job.id in state.selected,
                    onCheckedChange = { onSelectionChange(job.id, it) },
                    onClick = { onJobClick(job) },
                    onRemove = { onRemove(setOf(job.id)) },
                )
            }
        }

        // Trailing space, so the last row clears the floating nav bar or the selection bar.
        item { Spacer(modifier = Modifier.height(SmileDimens.space64 * 2)) }
    }
}

/** Row ids are suffixed with the index in the whole visible list, not within the day group. */
private fun androidx.compose.foundation.lazy.LazyListScope.itemsIndexedByJob(
    jobs: List<UseSmileIDSampleJob>,
    visible: List<UseSmileIDSampleJob>,
    row: @Composable (Int, UseSmileIDSampleJob) -> Unit,
) = jobs.forEach { job -> item(key = job.id) { row(visible.indexOf(job), job) } }

@Composable
private fun JobListRow(
    job: UseSmileIDSampleJob,
    index: Int,
    selectMode: Boolean,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    onClick: () -> Unit,
    onRemove: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = SmileDimens.spacingMd),
        horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        // Beside the card, not inside it: the design narrows the card to make room.
        if (selectMode) {
            UseSmileIDSampleSelectionCheckbox(
                checked = checked,
                onCheckedChange = onCheckedChange,
                modifier = Modifier.testTag(UseSmileIDSampleTestIds.selectionCheckbox(index)),
            )
        }
        Box(modifier = Modifier.weight(1f)) {
            val rowContent = @Composable {
                UseSmileIDSampleJobRow(
                    product = job.product,
                    jobId = job.shortId,
                    time = job.timeLabel(),
                    status = job.status,
                    onClick = if (selectMode) null else onClick,
                    testId = UseSmileIDSampleTestIds.jobRow(index),
                    statusTestId = UseSmileIDSampleTestIds.JOB_ROW_STATUS,
                )
            }
            // Swipe is off in select mode, where the gesture would fight the checkbox.
            if (selectMode) rowContent() else UseSmileIDSampleSwipeAction(onRemove = onRemove) { rowContent() }
        }
    }
}
