package com.usesmileid.sampleapps.android.flow

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleErrorAction
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleResumePoint

/** Where a failure's one action takes the user. */
internal sealed interface UseSmileIDSampleErrorMove {
    /** The product's flow again, past the forms, as a new job. */
    data class RunAgain(val product: UseSmileIDSampleProduct) : UseSmileIDSampleErrorMove

    /** The product's first step under the live session, whose partner may not take the details the run had. */
    data class RunFromStart(val product: UseSmileIDSampleProduct) : UseSmileIDSampleErrorMove

    /** The ID form, whose Continue starts the flow. */
    data class EditIdDetails(val product: UseSmileIDSampleProduct) : UseSmileIDSampleErrorMove

    /** The scanner for a new token, then the run from [resumeAt]. */
    data class NewToken(val product: UseSmileIDSampleProduct, val resumeAt: UseSmileIDSampleResumePoint) : UseSmileIDSampleErrorMove

    /** Out of the run, to the products tab. */
    data object Leave : UseSmileIDSampleErrorMove
}

/** The move [action] makes for the run of [product], gated as a product tap is: a live session, on the run's own partner. */
internal fun errorMove(
    action: UseSmileIDSampleErrorAction,
    product: UseSmileIDSampleProduct?,
    sessionLive: Boolean,
    livePartnerId: String?,
    runPartnerId: String?,
): UseSmileIDSampleErrorMove {
    if (product == null) return UseSmileIDSampleErrorMove.Leave
    return when (action) {
        UseSmileIDSampleErrorAction.Retry,
        UseSmileIDSampleErrorAction.RetryLater,
        UseSmileIDSampleErrorAction.Recapture,
        -> when {
            !sessionLive -> UseSmileIDSampleErrorMove.NewToken(product, UseSmileIDSampleResumePoint.Flow)
            runPartnerId != null && runPartnerId == livePartnerId -> UseSmileIDSampleErrorMove.RunAgain(product)
            else -> UseSmileIDSampleErrorMove.RunFromStart(product)
        }
        UseSmileIDSampleErrorAction.FixInput ->
            if (sessionLive) {
                UseSmileIDSampleErrorMove.EditIdDetails(product)
            } else {
                UseSmileIDSampleErrorMove.NewToken(product, UseSmileIDSampleResumePoint.FirstStep)
            }
        UseSmileIDSampleErrorAction.NewSession -> UseSmileIDSampleErrorMove.NewToken(product, UseSmileIDSampleResumePoint.Flow)
        UseSmileIDSampleErrorAction.Exit -> UseSmileIDSampleErrorMove.Leave
    }
}
