package com.usesmileid.sampleapps.ui.state

import androidx.compose.runtime.saveable.SaverScope
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowStatus
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class UseSmileIDSampleFlowResultTest {

    @Test
    fun a_fresh_run_has_counted_nothing() {
        val result = UseSmileIDSampleFlowResult().snapshot
        assertEquals(0, result.resultCallbackCount)
        assertEquals(0, result.refreshCallbackCount)
        assertEquals(UseSmileIDSampleFlowStatus.Idle, result.jobStatus)
    }

    @Test
    fun each_callback_counts_once() {
        val flow = UseSmileIDSampleFlowResult()
        flow.recordRefreshCallback()
        flow.recordRefreshCallback()
        flow.recordResultCallback(UseSmileIDSampleFlowStatus.Succeeded, jobId = "job_1", userId = "user_1")

        assertEquals(1, flow.resultCallbackCount)
        assertEquals(2, flow.refreshCallbackCount)
        assertEquals("job_1", flow.jobId)
        assertEquals("user_1", flow.userId)
    }

    @Test
    fun a_second_result_callback_is_visible_rather_than_swallowed() {
        val flow = UseSmileIDSampleFlowResult()
        flow.recordResultCallback(UseSmileIDSampleFlowStatus.Succeeded, jobId = "job_1")
        flow.recordResultCallback(UseSmileIDSampleFlowStatus.Succeeded, jobId = "job_1")
        assertEquals(2, flow.resultCallbackCount)
    }

    @Test
    fun starting_a_run_clears_the_previous_outcome_and_both_counts() {
        val flow = UseSmileIDSampleFlowResult()
        flow.recordRefreshCallback()
        flow.recordResultCallback(UseSmileIDSampleFlowStatus.Failed, error = "2213: authentication failed")

        flow.startFlow(UseSmileIDSampleEnvironment.Production)

        assertEquals(UseSmileIDSampleFlowStatus.Running, flow.status)
        assertEquals("the run's own environment, from its snapshot", UseSmileIDSampleEnvironment.Production, flow.environment)
        assertEquals(0, flow.resultCallbackCount)
        assertEquals(0, flow.refreshCallbackCount)
        assertNull(flow.lastError)
        assertNull(flow.jobId)
    }

    @Test
    fun recreation_preserves_the_counts_and_the_outcome() {
        val flow = UseSmileIDSampleFlowResult(scenario = UseSmileIDSampleScenario.BadRefresh)
        flow.enterRoute(UseSmileIDSampleFlowRoute.Shell)
        flow.recordRefreshCallback()
        flow.recordResultCallback(UseSmileIDSampleFlowStatus.Failed, error = "2213: authentication failed")

        assertEquals(flow.snapshot, flow.recreate().snapshot)
    }

    @Test
    fun a_scenario_this_build_no_longer_has_restores_as_the_default() {
        val restored = UseSmileIDSampleFlowResult.Saver.restore(
            listOf("retiredScenario", "brandDefault", "fullscreen", "sandbox", "idle", "", "", "", "0", "0"),
        )
        assertEquals(UseSmileIDSampleScenario.Normal, restored?.scenario)
    }

    @Test
    fun an_unreadable_environment_restores_as_sandbox_rather_than_taking_the_app_down() {
        val restored = UseSmileIDSampleFlowResult.Saver.restore(
            listOf("normal", "brandDefault", "fullscreen", "somewhere-else", "idle", "", "", "", "0", "0"),
        )
        assertEquals(UseSmileIDSampleEnvironment.Sandbox, restored?.environment)
    }

    @Test
    fun a_count_that_did_not_round_trip_restores_as_zero() {
        val restored = UseSmileIDSampleFlowResult.Saver.restore(
            listOf("normal", "brandDefault", "fullscreen", "production", "idle", "", "", "", "", "not-a-number"),
        )
        assertEquals(0, restored?.resultCallbackCount)
        assertEquals(0, restored?.refreshCallbackCount)
    }

    private fun UseSmileIDSampleFlowResult.recreate(): UseSmileIDSampleFlowResult {
        val saved = with(UseSmileIDSampleFlowResult.Saver) { SaverScope { true }.save(this@recreate) }
        assertNotNull("the saver produced nothing to restore from", saved)
        return requireNotNull(UseSmileIDSampleFlowResult.Saver.restore(saved!!))
    }
}
