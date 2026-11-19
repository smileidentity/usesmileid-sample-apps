package com.usesmileid.sampleapps.android.flow

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleErrorAction
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct

/** Where a failure's one action takes the user. */
internal sealed interface UseSmileIDSampleErrorMove {
    /** The product's flow again, past the forms, as a new job. */
    data class RunAgain(val product: UseSmileIDSampleProduct) : UseSmileIDSampleErrorMove

    /** The ID form, whose Continue starts the flow. */
    data class EditIdDetails(val product: UseSmileIDSampleProduct) : UseSmileIDSampleErrorMove

    /** The scanner for a new token, then the flow. */
    data class NewToken(val product: UseSmileIDSampleProduct) : UseSmileIDSampleErrorMove

    /** Out of the run, to the products tab. */
    data object Leave : UseSmileIDSampleErrorMove
}

/** The move [action] makes for the run of [product]; without a product there is nothing to run again. */
internal fun errorMove(action: UseSmileIDSampleErrorAction, product: UseSmileIDSampleProduct?): UseSmileIDSampleErrorMove {
    if (product == null) return UseSmileIDSampleErrorMove.Leave
    return when (action) {
        UseSmileIDSampleErrorAction.Retry,
        UseSmileIDSampleErrorAction.RetryLater,
        UseSmileIDSampleErrorAction.Recapture,
        -> UseSmileIDSampleErrorMove.RunAgain(product)
        UseSmileIDSampleErrorAction.FixInput -> UseSmileIDSampleErrorMove.EditIdDetails(product)
        UseSmileIDSampleErrorAction.NewSession -> UseSmileIDSampleErrorMove.NewToken(product)
        UseSmileIDSampleErrorAction.Exit -> UseSmileIDSampleErrorMove.Leave
    }
}
