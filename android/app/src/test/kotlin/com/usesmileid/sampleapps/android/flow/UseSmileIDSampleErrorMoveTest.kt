package com.usesmileid.sampleapps.android.flow

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleErrorAction
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleResumePoint
import org.junit.Assert.assertEquals
import org.junit.Test

/** Where each failure action takes the user, per the `does` lines of spec/error-handling.json, under the gate a product tap passes. */
class UseSmileIDSampleErrorMoveTest {

    private val product = UseSmileIDSampleProduct.BiometricKyc
    private val reruns = listOf(UseSmileIDSampleErrorAction.Retry, UseSmileIDSampleErrorAction.RetryLater, UseSmileIDSampleErrorAction.Recapture)

    @Test
    fun a_retry_a_later_retry_and_a_recapture_run_the_verification_again_on_the_runs_own_partner() {
        reruns.forEach {
            assertEquals(it.id, UseSmileIDSampleErrorMove.RunAgain(product), move(it, livePartnerId = "partner_1", runPartnerId = "partner_1"))
        }
    }

    @Test
    fun a_rerun_on_another_or_an_unknown_partner_starts_from_the_first_step() {
        reruns.forEach {
            assertEquals(it.id, UseSmileIDSampleErrorMove.RunFromStart(product), move(it, livePartnerId = "partner_2", runPartnerId = "partner_1"))
            assertEquals(it.id, UseSmileIDSampleErrorMove.RunFromStart(product), move(it, livePartnerId = "partner_2", runPartnerId = null))
        }
    }

    @Test
    fun a_rerun_with_no_live_session_scans_first_and_resumes_in_the_flow() {
        reruns.forEach {
            assertEquals(it.id, UseSmileIDSampleErrorMove.NewToken(product, UseSmileIDSampleResumePoint.Flow), move(it, sessionLive = false))
        }
    }

    @Test
    fun fixing_the_input_returns_to_the_id_form_or_scans_first_with_no_live_session() {
        assertEquals(UseSmileIDSampleErrorMove.EditIdDetails(product), move(UseSmileIDSampleErrorAction.FixInput))
        assertEquals(
            UseSmileIDSampleErrorMove.NewToken(product, UseSmileIDSampleResumePoint.FirstStep),
            move(UseSmileIDSampleErrorAction.FixInput, sessionLive = false),
        )
    }

    @Test
    fun fixing_the_input_on_another_partner_starts_from_the_first_step_with_fresh_forms() {
        assertEquals(
            UseSmileIDSampleErrorMove.RunFromStart(product),
            move(UseSmileIDSampleErrorAction.FixInput, livePartnerId = "partner_2"),
        )
    }

    @Test
    fun starting_again_takes_a_new_token_first() {
        assertEquals(UseSmileIDSampleErrorMove.NewToken(product, UseSmileIDSampleResumePoint.Flow), move(UseSmileIDSampleErrorAction.NewSession))
    }

    @Test
    fun close_leaves_the_run() {
        assertEquals(UseSmileIDSampleErrorMove.Leave, move(UseSmileIDSampleErrorAction.Exit))
    }

    @Test
    fun a_run_whose_product_was_not_kept_can_only_leave() {
        UseSmileIDSampleErrorAction.entries.forEach {
            assertEquals(it.id, UseSmileIDSampleErrorMove.Leave, errorMove(it, product = null, sessionLive = true, livePartnerId = "p", runPartnerId = "p"))
        }
    }

    private fun move(
        action: UseSmileIDSampleErrorAction,
        sessionLive: Boolean = true,
        livePartnerId: String? = "partner_1",
        runPartnerId: String? = "partner_1",
    ) = errorMove(action, product, sessionLive, livePartnerId, runPartnerId)
}
