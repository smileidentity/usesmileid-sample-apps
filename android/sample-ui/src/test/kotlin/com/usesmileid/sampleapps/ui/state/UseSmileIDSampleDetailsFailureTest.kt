package com.usesmileid.sampleapps.ui.state

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowStatus
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleStatus
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** Which failure verification details states, and how its banner reads. */
class UseSmileIDSampleDetailsFailureTest {

    private val serverError = UseSmileIDSampleErrorHandling.forStatus(503)

    @Test
    fun a_run_that_failed_before_any_job_states_its_own_row() {
        assertEquals(serverError, detailsFailure(job = null, landedRun = serverError))
    }

    @Test
    fun a_failed_run_no_submission_explains_states_that_it_ended_before_submission() {
        val landed = landedFailure(UseSmileIDSampleFlowStatus.Failed, row = null)
        assertEquals("endedBeforeSubmission", landed?.id)
        assertEquals(UseSmileIDSampleBannerTone.Warning, landed?.bannerTone)
    }

    @Test
    fun a_run_that_did_not_fail_lands_with_no_failure() {
        listOf(UseSmileIDSampleFlowStatus.Captured, UseSmileIDSampleFlowStatus.Succeeded, UseSmileIDSampleFlowStatus.Cancelled).forEach {
            assertNull(it.name, landedFailure(it, row = serverError))
        }
        assertEquals(serverError, landedFailure(UseSmileIDSampleFlowStatus.Failed, row = serverError))
    }

    @Test
    fun a_missing_job_with_no_failed_run_states_nothing() {
        assertNull(detailsFailure(job = null, landedRun = null))
    }

    @Test
    fun a_job_that_ended_in_error_or_block_states_the_fallback_until_the_status_carries_a_reason() {
        listOf(UseSmileIDSampleStatus.Error, UseSmileIDSampleStatus.Blocked).forEach { status ->
            assertEquals(status.name, "notVerified", detailsFailure(job(status), landedRun = serverError)?.id)
        }
    }

    @Test
    fun a_job_with_any_other_status_states_nothing_even_after_a_failed_run() {
        listOf(UseSmileIDSampleStatus.Clear, UseSmileIDSampleStatus.Attention, UseSmileIDSampleStatus.Processing).forEach { status ->
            assertNull(status.name, detailsFailure(job(status), landedRun = serverError))
        }
    }

    @Test
    fun a_failure_trying_again_later_can_get_past_is_a_warning_and_a_final_one_an_error() {
        assertEquals(UseSmileIDSampleBannerTone.Warning, serverError.bannerTone)
        assertEquals(UseSmileIDSampleBannerTone.Error, UseSmileIDSampleErrorHandling.forReason(null).bannerTone)
    }

    private fun job(status: UseSmileIDSampleStatus) = UseSmileIDSampleJob(
        id = "job_1",
        userId = "user_1",
        product = UseSmileIDSampleProduct.BiometricKyc,
        status = status,
        createdAtMillis = 0L,
        message = "Rejected",
        httpStatus = 200,
    )
}
