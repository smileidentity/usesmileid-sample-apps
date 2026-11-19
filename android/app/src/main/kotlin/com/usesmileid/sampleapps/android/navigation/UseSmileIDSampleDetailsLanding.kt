package com.usesmileid.sampleapps.android.navigation

import com.usesmileid.sampleapps.android.flow.UNSUBMITTED_JOB_ID
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleErrorResolution
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleFlowResult
import com.usesmileid.sampleapps.ui.state.landedFailure

/** What the details page for one id says of the last run: its failure and its product. */
internal data class UseSmileIDSampleDetailsLanding(
    val failure: UseSmileIDSampleErrorResolution?,
    val product: UseSmileIDSampleProduct?,
)

/** Only the unsubmitted page states the last run, so a missing job never borrows another run's failure. */
internal fun detailsLanding(jobId: String, run: UseSmileIDSampleFlowResult): UseSmileIDSampleDetailsLanding =
    if (jobId == UNSUBMITTED_JOB_ID) {
        UseSmileIDSampleDetailsLanding(landedFailure(run.status, run.errorResolution), run.product)
    } else {
        UseSmileIDSampleDetailsLanding(failure = null, product = null)
    }
