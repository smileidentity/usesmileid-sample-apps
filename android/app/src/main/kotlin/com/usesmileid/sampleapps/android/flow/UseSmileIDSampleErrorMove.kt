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

/** Where the run's ID details come from, which decides what fixing them means. */
internal enum class UseSmileIDSampleIdDetailsSource {
    /** The ID form, which the run asks for. */
    Form,

    /** The token, which only a new token can change. */
    Token,

    /** Nowhere: the product takes no ID details. */
    None,
}

/** The move [action] makes for the run of [product], gated as a product tap is; [formsHoldRun] is false once another tap has reset the forms. */
internal fun errorMove(
    action: UseSmileIDSampleErrorAction,
    product: UseSmileIDSampleProduct?,
    sessionLive: Boolean,
    livePartnerId: String?,
    runPartnerId: String?,
    idDetails: UseSmileIDSampleIdDetailsSource,
    formsHoldRun: Boolean,
): UseSmileIDSampleErrorMove {
    if (product == null) return UseSmileIDSampleErrorMove.Leave
    val ownRun = formsHoldRun && runPartnerId != null && runPartnerId == livePartnerId
    val resumeAt = if (formsHoldRun) UseSmileIDSampleResumePoint.Flow else UseSmileIDSampleResumePoint.FirstStep
    return when (action) {
        UseSmileIDSampleErrorAction.Retry,
        UseSmileIDSampleErrorAction.RetryLater,
        UseSmileIDSampleErrorAction.Recapture,
        -> when {
            !sessionLive -> UseSmileIDSampleErrorMove.NewToken(product, resumeAt)
            ownRun -> UseSmileIDSampleErrorMove.RunAgain(product)
            else -> UseSmileIDSampleErrorMove.RunFromStart(product)
        }
        UseSmileIDSampleErrorAction.FixInput -> when {
            !sessionLive || idDetails == UseSmileIDSampleIdDetailsSource.Token ->
                UseSmileIDSampleErrorMove.NewToken(product, UseSmileIDSampleResumePoint.FirstStep)
            ownRun && idDetails == UseSmileIDSampleIdDetailsSource.Form -> UseSmileIDSampleErrorMove.EditIdDetails(product)
            else -> UseSmileIDSampleErrorMove.RunFromStart(product)
        }
        UseSmileIDSampleErrorAction.NewSession -> UseSmileIDSampleErrorMove.NewToken(product, resumeAt)
        UseSmileIDSampleErrorAction.Exit -> UseSmileIDSampleErrorMove.Leave
    }
}
