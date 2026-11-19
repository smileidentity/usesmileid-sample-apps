package com.usesmileid.sampleapps.ui.screens

import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.golden.ResultFixtures
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleErrorAction
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleErrorResolution
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleErrorHandling
import org.junit.Assert.assertEquals
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** A details link opens before the store reports, so "not loaded yet" must not read as "no such verification". */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class VerificationDetailsScreenTest {
    @get:Rule val compose = createComposeRule()

    @Test
    fun a_job_still_loading_is_not_drawn_as_missing() {
        details(pending = true)
        compose.onNodeWithTag(UseSmileIDSampleTestIds.DETAILS_EMPTY).assertDoesNotExist()
        compose.onNodeWithTag(UseSmileIDSampleTestIds.DETAILS_DELETE).assertDoesNotExist()
    }

    @Test
    fun a_job_the_store_does_not_have_is_drawn_as_missing() {
        details(pending = false)
        compose.onNodeWithTag(UseSmileIDSampleTestIds.DETAILS_EMPTY).assertExists()
    }

    @Test
    fun a_failed_run_states_its_message_in_place_of_missing_and_its_button_runs_the_action() {
        val pressed = mutableListOf<UseSmileIDSampleErrorAction>()
        details(pending = false, landedFailure = UseSmileIDSampleErrorHandling.forStatus(503), onErrorAction = { pressed += it })
        compose.onNodeWithTag(UseSmileIDSampleTestIds.DETAILS_EMPTY).assertDoesNotExist()
        compose.onNodeWithTag(UseSmileIDSampleTestIds.ERROR_BANNER).assertExists()
        compose.onNodeWithTag(UseSmileIDSampleTestIds.ERROR_ACTION).performClick()
        assertEquals(listOf(UseSmileIDSampleErrorAction.Retry), pressed)
    }

    @Test
    fun a_stored_job_that_ended_in_error_states_why_and_leaves_closing_to_the_back_button() {
        details(pending = false, job = job(UseSmileIDSampleStatus.Error))
        compose.onNodeWithTag(UseSmileIDSampleTestIds.ERROR_BANNER).assertExists()
        compose.onNodeWithTag(UseSmileIDSampleTestIds.ERROR_ACTION).assertDoesNotExist()
    }

    @Test
    fun a_stored_job_that_passed_states_no_failure_even_after_a_failed_run() {
        details(pending = false, job = job(UseSmileIDSampleStatus.Clear), landedFailure = UseSmileIDSampleErrorHandling.forStatus(503))
        compose.onNodeWithTag(UseSmileIDSampleTestIds.ERROR_BANNER).assertDoesNotExist()
    }

    private fun job(status: UseSmileIDSampleStatus) = UseSmileIDSampleJob(
        id = "job_missing",
        userId = "user_1",
        product = UseSmileIDSampleProduct.BiometricKyc,
        status = status,
        createdAtMillis = 0L,
        message = "Rejected",
        httpStatus = 200,
    )

    private fun details(
        pending: Boolean,
        job: UseSmileIDSampleJob? = null,
        landedFailure: UseSmileIDSampleErrorResolution? = null,
        onErrorAction: (UseSmileIDSampleErrorAction) -> Unit = {},
    ) = compose.setContent {
        UseSmileIDSampleTheme {
            VerificationDetailsScreen(
                jobId = "job_missing",
                job = job,
                result = ResultFixtures.Failed,
                onBack = {},
                onDelete = {},
                onCopy = { _, _ -> },
                pending = pending,
                landedFailure = landedFailure,
                onErrorAction = onErrorAction,
            )
        }
    }
}
