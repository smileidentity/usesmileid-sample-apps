package com.usesmileid.sampleapps.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Text
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.listSaver
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
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
import com.usesmileid.sampleapps.ui.model.timeLabels
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * The list's own UI state. Saveable policy, per field: [filter], [selectMode] and [selected]
 * survive recreation (a rotated device keeps its selection); nothing here survives process death.
 */
@Stable
class UseSmileIDSampleVerificationsScreenState(
    filter: UseSmileIDSampleJobFilter,
    selectMode: Boolean,
    selected: Set<String>,
) {
    var filter by mutableStateOf(filter)
    var selectMode by mutableStateOf(selectMode)
        private set
    var selected by mutableStateOf(selected)
        private set

    /** Cleared on the way IN, so the bar still shows its count while it slides away. */
    fun changeSelectMode(on: Boolean) {
        selectMode = on
        if (on) selected = emptySet()
    }

    fun setSelection(id: String, checked: Boolean) {
        selected = if (checked) selected + id else selected - id
    }

    companion object {
        /** listSaver keeps the three fields; the set flattens to a list and back. */
        val Saver: Saver<UseSmileIDSampleVerificationsScreenState, Any> = listSaver(
            save = { listOf(it.filter.name, it.selectMode, it.selected.toList()) },
            restore = {
                @Suppress("UNCHECKED_CAST")
                UseSmileIDSampleVerificationsScreenState(
                    filter = UseSmileIDSampleJobFilter.valueOf(it[0] as String),
                    selectMode = it[1] as Boolean,
                    selected = (it[2] as List<String>).toSet(),
                )
            },
        )
    }
}

@Composable
fun rememberVerificationsScreenState(): UseSmileIDSampleVerificationsScreenState =
    rememberSaveable(saver = UseSmileIDSampleVerificationsScreenState.Saver) {
        UseSmileIDSampleVerificationsScreenState(
            filter = UseSmileIDSampleJobFilter.All,
            selectMode = false,
            selected = emptySet(),
        )
    }

/** Everything the list renders, so the screen owns no clock, store or selection of its own. */
data class UseSmileIDSampleVerificationsState(
    /** Null until the rows have loaded, so an empty state cannot be drawn over a list that is coming. */
    val jobs: List<UseSmileIDSampleJob>?,
    val counts: Map<UseSmileIDSampleJobFilter, Int>,
    val filter: UseSmileIDSampleJobFilter = UseSmileIDSampleJobFilter.All,
    val selectMode: Boolean = false,
    val selected: Set<String> = emptySet(),
    /** Midnight, not the current instant: only the TODAY/YESTERDAY bucket reads the clock. */
    val todayStartMillis: Long,
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
    val visible = remember(state.jobs, state.filter) { state.jobs.orEmpty().filter(state.filter::matches) }
    val days = remember(visible, state.todayStartMillis) { visible.groupByDay(state.todayStartMillis) }
    // Row ids carry the index in the whole visible list, not the one within the day group.
    val rowIndex = remember(visible) { visible.withIndex().associate { it.value.id to it.index } }
    val timeLabels = remember(visible) { visible.timeLabels() }
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

        days.forEach { day ->
            item {
                UseSmileIDSampleDateGroupHeader(
                    relative = day.relative,
                    absolute = day.absolute,
                    modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
                )
            }
            items(day.jobs, key = { it.id }) { job ->
                JobListRow(
                    job = job,
                    index = rowIndex.getValue(job.id),
                    timeLabel = timeLabels.getValue(job.id),
                    selectMode = state.selectMode,
                    checked = job.id in state.selected,
                    onCheckedChange = { onSelectionChange(job.id, it) },
                    onClick = { onJobClick(job) },
                    onRemove = { onRemove(setOf(job.id)) },
                )
            }
        }
    }
}

@Composable
private fun JobListRow(
    job: UseSmileIDSampleJob,
    index: Int,
    timeLabel: String,
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
                    time = timeLabel,
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
