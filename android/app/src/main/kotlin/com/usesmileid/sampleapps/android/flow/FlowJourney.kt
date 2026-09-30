package com.usesmileid.sampleapps.android.flow

import com.ramcosta.composedestinations.generated.destinations.ConsentDetailsFormScreenDestination
import com.ramcosta.composedestinations.generated.destinations.IdDetailsFormScreenDestination
import com.ramcosta.composedestinations.generated.destinations.ScanTokenScreenDestination
import com.ramcosta.composedestinations.generated.destinations.SdkFlowScreenDestination
import com.ramcosta.composedestinations.spec.Direction
import com.usesmileid.sampleapps.android.UseSmileIDSampleAppState
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleResumePoint
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleRunIntent

/** A product tap: the scanner first when no live session backs the run, since every run submits under a token. */
internal fun UseSmileIDSampleAppState.entryFor(product: UseSmileIDSampleProduct): Direction {
    if (session?.hasExpired(System.currentTimeMillis()) != false) {
        interruptedRun.send(UseSmileIDSampleRunIntent(product.id, launchArgs.route, UseSmileIDSampleResumePoint.FirstStep))
        return ScanTokenScreenDestination
    }
    return firstStepFor(product)
}

/** Where a product starts: a form is skipped only when the token already carries all of it. */
internal fun UseSmileIDSampleAppState.firstStepFor(product: UseSmileIDSampleProduct): Direction =
    if (!tokenBindsUserDetails) {
        ConsentDetailsFormScreenDestination(productId = product.id)
    } else {
        stepAfterUserDetails(product)
    }

/** What follows user details, shared with that form's own Continue so the two routes cannot drift. */
internal fun UseSmileIDSampleAppState.stepAfterUserDetails(product: UseSmileIDSampleProduct): Direction =
    if (product.needsIdDetails && !tokenBindsIdDetails(product)) {
        IdDetailsFormScreenDestination(productId = product.id)
    } else {
        sdkFlow(product.id)
    }

/**
 * The wizard's last hop, carrying the launched presentation (R3). Without it the in-shell route is
 * unreachable with a payload: its other carriers are cold starts, where the forms are always empty.
 */
internal fun UseSmileIDSampleAppState.sdkFlow(productId: String) =
    SdkFlowScreenDestination(productId = productId, route = launchArgs.route)
