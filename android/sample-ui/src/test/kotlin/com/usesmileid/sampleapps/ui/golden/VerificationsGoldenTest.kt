package com.usesmileid.sampleapps.ui.golden

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleToast
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJobFilter
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleJobStore
import com.usesmileid.sampleapps.ui.model.startOfDayMillis
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleVerificationsState
import com.usesmileid.sampleapps.ui.screens.VerificationDetailsScreen
import com.usesmileid.sampleapps.ui.screens.VerificationsScreen
import org.junit.Test

/** The clock is fixed, so the date headers a golden records are the ones it compares against tomorrow. */
class VerificationsGoldenTest : GoldenTest() {

    @Test
    fun verifications() = goldens("screen_verifications") { Verifications() }

    @Test
    fun verifications_max_font_scale() = assertSurvivesMaxFontScale { Verifications() }

    @Test
    fun verifications_select_mode() = goldens("screen_verifications_select") { Verifications(selectMode = true) }

    @Test
    fun verifications_items_selected() =
        goldens("screen_verifications_selected") { Verifications(selectMode = true, selectFirst = true) }

    @Test
    fun verifications_filtered() =
        goldens("screen_verifications_filtered") { Verifications(filter = UseSmileIDSampleJobFilter.Attention) }

    @Test
    fun verifications_nothing_stored() =
        goldens("screen_verifications_empty") { Verifications(jobs = emptyList()) }

    @Test
    fun verifications_nothing_matching_filter() = goldens("screen_verifications_filter_empty") {
        Verifications(
            filter = UseSmileIDSampleJobFilter.Blocked,
            jobs = JOBS.filter { it.status == UseSmileIDSampleStatus.Clear },
        )
    }

    /** The shell's copy word for word: the rows are hidden from this app's list, not deleted. */
    @Test
    fun verifications_after_delete() = goldens("screen_verifications_after_delete") {
        Box(modifier = Modifier.fillMaxSize()) {
            Verifications(jobs = AFTER_DELETE)
            UseSmileIDSampleToast(
                message = "2 verifications hidden from App list",
                actionLabel = "Undo",
                onAction = {},
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingXxs),
            )
        }
    }

    @Test
    fun verifications_swipe_to_delete() = goldens(
        name = "screen_verifications_swipe_open",
        interact = { dragLeft(UseSmileIDSampleTestIds.jobRow(0), SWIPE_REVEAL) },
    ) { Verifications() }

    @Test
    fun verification_details_clear() = goldens("screen_verification_details_clear") { Details(CLEAR) }

    @Test
    fun verification_details_max_font_scale() = assertSurvivesMaxFontScale { Details(CLEAR) }

    @Test
    fun verification_details_attention() = goldens("screen_verification_details_attention") { Details(ATTENTION) }

    @Test
    fun verification_details_blocked() = goldens("screen_verification_details_blocked") { Details(BLOCKED) }

    @Test
    fun verification_details_processing() = goldens("screen_verification_details_processing") { Details(PROCESSING) }

    @Test
    fun verification_details_processing_max_font_scale() = assertSurvivesMaxFontScale { Details(PROCESSING) }

    @Test
    fun verification_details_unknown_job() = goldens("screen_verification_details_unknown") { UnknownDetails() }

    @Test
    fun verification_details_without_probes() =
        goldens("screen_verification_details_no_probes") { Details(showProbes = false) }

    private companion object {
        /** 2026-07-16T11:50:12Z, the instant the design's rows are dated from. */
        const val FIXED_NOW = 1_784_202_612_000L
        val JOBS = UseSmileIDSampleJobStore.fixtures(FIXED_NOW)

        /** One fixture per status, so a state's picture carries the badge the spec names it after. */
        val CLEAR = JOBS.first { it.status == UseSmileIDSampleStatus.Clear }
        val ATTENTION = JOBS.first { it.status == UseSmileIDSampleStatus.Attention }
        val BLOCKED = JOBS.first { it.status == UseSmileIDSampleStatus.Blocked }

        /** What a real 202 says: a message long enough to need a second line of its own column. */
        val PROCESSING = JOBS.first { it.status == UseSmileIDSampleStatus.Processing }
            .copy(message = "Request accepted and queued for processing.")

        /** The count the shell reports after the selection bar hides two rows. */
        val AFTER_DELETE = JOBS.drop(2)

        /** The backdrop's own width, so the row settles flush against it rather than past it. */
        val SWIPE_REVEAL = SmileDimens.space64 + SmileDimens.spacingMd
    }

    @Composable
    private fun Verifications(
        filter: UseSmileIDSampleJobFilter = UseSmileIDSampleJobFilter.All,
        selectMode: Boolean = false,
        selectFirst: Boolean = false,
        jobs: List<UseSmileIDSampleJob> = JOBS,
    ) = VerificationsScreen(
        state = UseSmileIDSampleVerificationsState(
            jobs = jobs,
            counts = UseSmileIDSampleJobFilter.entries.associateWith { f -> jobs.count(f::matches) },
            filter = filter,
            selectMode = selectMode,
            selected = if (selectFirst) jobs.take(2).map { it.id }.toSet() else emptySet(),
            todayStartMillis = startOfDayMillis(FIXED_NOW),
        ),
        onFilterChange = {},
        onSelectModeChange = {},
        onSelectionChange = { _, _ -> },
        onJobClick = {},
        onRemove = {},
    )

    @Composable
    private fun Details(
        job: UseSmileIDSampleJob = JOBS.first(),
        showProbes: Boolean = true,
    ) = VerificationDetailsScreen(
        jobId = job.id,
        job = job,
        result = ResultFixtures.Succeeded,
        onBack = {},
        onDelete = {},
        onCopy = { _, _ -> },
        showProbes = showProbes,
    )

    @Composable
    private fun UnknownDetails() = VerificationDetailsScreen(
        jobId = "job_missing",
        job = null,
        result = ResultFixtures.Failed,
        onBack = {},
        onDelete = {},
        onCopy = { _, _ -> },
    )
}
