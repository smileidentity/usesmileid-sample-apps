package com.usesmileid.sampleapps.ui.state

import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleBannerTone
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleErrorAction
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleErrorResolution
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowStatus
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleStatus

/** What verification details states: a stored [job]'s `error` or `block`, or with no job the failed run that landed here. */
fun detailsFailure(job: UseSmileIDSampleJob?, landedRun: UseSmileIDSampleErrorResolution?): UseSmileIDSampleErrorResolution? = when {
    job == null -> landedRun
    // The status endpoint returns no reason yet, so every such job resolves as the fallback.
    job.status == UseSmileIDSampleStatus.Error || job.status == UseSmileIDSampleStatus.Blocked -> UseSmileIDSampleErrorHandling.forReason(null)
    else -> null
}

/** What a run that landed with no job states: its row, or the submission fallback when no submission explained the failure. */
fun landedFailure(status: UseSmileIDSampleFlowStatus, row: UseSmileIDSampleErrorResolution?): UseSmileIDSampleErrorResolution? =
    if (status == UseSmileIDSampleFlowStatus.Failed) row ?: UseSmileIDSampleErrorHandling.submissionFallback else null

/** Warning while the user can act on the failure, error once Close is all it offers. */
val UseSmileIDSampleErrorResolution.bannerTone: UseSmileIDSampleBannerTone
    get() = if (action == UseSmileIDSampleErrorAction.Exit) UseSmileIDSampleBannerTone.Error else UseSmileIDSampleBannerTone.Warning

/** Whether the banner shows its button: on a stored job the app bar's back already closes the screen. */
fun UseSmileIDSampleErrorResolution.offersAction(onStoredJob: Boolean): Boolean =
    !(onStoredJob && action == UseSmileIDSampleErrorAction.Exit)
