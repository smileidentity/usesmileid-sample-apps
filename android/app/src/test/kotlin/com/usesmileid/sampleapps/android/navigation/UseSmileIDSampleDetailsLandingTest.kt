package com.usesmileid.sampleapps.android.navigation

import com.usesmileid.sampleapps.android.flow.UNSUBMITTED_JOB_ID
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleFlowResult
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** Only the unsubmitted page states the last run's failure, so a missing job never borrows another run's. */
class UseSmileIDSampleDetailsLandingTest {
    private val failedRun = UseSmileIDSampleFlowResult().apply {
        recordBlocked("the flow did not validate", UseSmileIDSampleEnvironment.Sandbox, UseSmileIDSampleProduct.BiometricKyc)
    }

    @Test
    fun the_unsubmitted_page_states_the_last_runs_failure_and_product() {
        val landing = detailsLanding(UNSUBMITTED_JOB_ID, failedRun)
        assertEquals("endedEarly", landing.failure?.id)
        assertEquals(UseSmileIDSampleProduct.BiometricKyc, landing.product)
    }

    @Test
    fun any_other_missing_job_states_no_failure() {
        val landing = detailsLanding("job-missing", failedRun)
        assertNull(landing.failure)
        assertNull(landing.product)
    }
}
