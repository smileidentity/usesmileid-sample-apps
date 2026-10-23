package com.usesmileid.sampleapps.android.flow

import com.usesmileid.njia.NjiaGraph
import com.usesmileid.sampleapps.android.UseSmileIDSampleAppState
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleFact
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleStep
import com.usesmileid.sampleapps.android.navigation.njiaFactsFor
import com.usesmileid.sampleapps.android.navigation.njiaFirstStepFor
import com.usesmileid.sampleapps.android.navigation.useSmileIDSampleFacts
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleResumePoint
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleRunIntent

/** Where a run starts: the facts it runs under and the step a product tap goes to. */
internal data class UseSmileIDSampleRunEntry(val facts: Set<UseSmileIDSampleFact>, val step: String)

/** A product tap's run, or null when no live session backs it and the scanner comes first, since every run submits under a token. */
internal fun UseSmileIDSampleAppState.entryFor(
    graph: NjiaGraph<UseSmileIDSampleStep, UseSmileIDSampleFact>,
    product: UseSmileIDSampleProduct,
): UseSmileIDSampleRunEntry? {
    if (session?.hasExpired(System.currentTimeMillis()) != false) {
        interruptedRun.send(UseSmileIDSampleRunIntent(product.id, launchArgs.route, UseSmileIDSampleResumePoint.FirstStep))
        return null
    }
    return runEntryFor(graph, product)
}

/** Where [product] starts under this launch and its token: a form is skipped only when the token already carries all of it. */
internal fun UseSmileIDSampleAppState.runEntryFor(
    graph: NjiaGraph<UseSmileIDSampleStep, UseSmileIDSampleFact>,
    product: UseSmileIDSampleProduct,
): UseSmileIDSampleRunEntry = UseSmileIDSampleRunEntry(njiaFactsFor(product), njiaFirstStepFor(graph, product))

/** Straight into the run on [route], past every form, as an autostart or a resumed run goes. */
internal fun UseSmileIDSampleAppState.runOnly(product: UseSmileIDSampleProduct, route: UseSmileIDSampleFlowRoute): UseSmileIDSampleRunEntry =
    UseSmileIDSampleRunEntry(
        useSmileIDSampleFacts(product, tokenBindsIdDetails(product), route),
        (if (route == UseSmileIDSampleFlowRoute.Fullscreen) UseSmileIDSampleStep.SdkFlowFullScreen else UseSmileIDSampleStep.SdkFlow).wireName,
    )
