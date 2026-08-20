package com.usesmileid.sampleapps.ui.golden

import androidx.compose.runtime.Composable
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJobFilter
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
    fun verification_details() = goldens("screen_verification_details") { Details() }

    @Test
    fun verification_details_max_font_scale() = assertSurvivesMaxFontScale { Details() }

    @Test
    fun verification_details_unknown_job() = goldens("screen_verification_details_unknown") { UnknownDetails() }

    @Test
    fun verification_details_queued() = goldens("screen_verification_details_queued") { Details(QUEUED) }

    @Test
    fun verification_details_queued_max_font_scale() = assertSurvivesMaxFontScale { Details(QUEUED) }

    private companion object {
        /** 2026-07-16T11:50:12Z, the instant the design's rows are dated from. */
        const val FIXED_NOW = 1_784_202_612_000L
        val JOBS = JobFixtures.jobs(FIXED_NOW)

        /** What a real 202 looks like: a message long enough to need a second line of its own column. */
        val QUEUED = JOBS.first().copy(
            message = "Request accepted and queued for processing.",
            httpStatus = "202 Accepted",
        )
    }

    @Composable
    private fun Verifications(
        filter: UseSmileIDSampleJobFilter = UseSmileIDSampleJobFilter.All,
        selectMode: Boolean = false,
        selectFirst: Boolean = false,
    ) = VerificationsScreen(
        state = UseSmileIDSampleVerificationsState(
            jobs = JOBS,
            counts = UseSmileIDSampleJobFilter.entries.associateWith { f -> JOBS.count(f::matches) },
            filter = filter,
            selectMode = selectMode,
            selected = if (selectFirst) JOBS.take(2).map { it.id }.toSet() else emptySet(),
            nowMillis = FIXED_NOW,
        ),
        onFilterChange = {},
        onSelectModeChange = {},
        onSelectionChange = { _, _ -> },
        onJobClick = {},
        onRemove = {},
    )

    @Composable
    private fun Details(job: UseSmileIDSampleJob = JOBS.first()) = VerificationDetailsScreen(
        jobId = job.id,
        job = job,
        result = ResultFixtures.Succeeded,
        onBack = {},
        onDelete = {},
        onCopy = { _, _ -> },
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
