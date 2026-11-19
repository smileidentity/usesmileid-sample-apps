package com.usesmileid.sampleapps.android.flow

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleErrorAction
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import org.junit.Assert.assertEquals
import org.junit.Test

/** Where each failure action takes the user, per the `does` lines of spec/error-handling.json. */
class UseSmileIDSampleErrorMoveTest {

    private val product = UseSmileIDSampleProduct.BiometricKyc

    @Test
    fun a_retry_a_later_retry_and_a_recapture_run_the_verification_again() {
        listOf(UseSmileIDSampleErrorAction.Retry, UseSmileIDSampleErrorAction.RetryLater, UseSmileIDSampleErrorAction.Recapture)
            .forEach { assertEquals(it.id, UseSmileIDSampleErrorMove.RunAgain(product), errorMove(it, product)) }
    }

    @Test
    fun fixing_the_input_returns_to_the_id_form() {
        assertEquals(UseSmileIDSampleErrorMove.EditIdDetails(product), errorMove(UseSmileIDSampleErrorAction.FixInput, product))
    }

    @Test
    fun starting_again_takes_a_new_token_first() {
        assertEquals(UseSmileIDSampleErrorMove.NewToken(product), errorMove(UseSmileIDSampleErrorAction.NewSession, product))
    }

    @Test
    fun close_leaves_the_run() {
        assertEquals(UseSmileIDSampleErrorMove.Leave, errorMove(UseSmileIDSampleErrorAction.Exit, product))
    }

    @Test
    fun a_run_whose_product_was_not_kept_can_only_leave() {
        UseSmileIDSampleErrorAction.entries.forEach { assertEquals(it.id, UseSmileIDSampleErrorMove.Leave, errorMove(it, product = null)) }
    }
}
