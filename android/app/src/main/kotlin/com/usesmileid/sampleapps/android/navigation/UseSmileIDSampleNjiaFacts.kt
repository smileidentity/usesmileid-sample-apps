package com.usesmileid.sampleapps.android.navigation

import com.usesmileid.njia.NjiaGraph
import com.usesmileid.njia.holdsFor
import com.usesmileid.njia.steps
import com.usesmileid.sampleapps.android.UseSmileIDSampleAppState
import com.usesmileid.sampleapps.android.flow.tokenBindsIdDetails
import com.usesmileid.sampleapps.android.flow.tokenBindsUserDetails
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct

/** The facts a run of [product] starts with, which the graph's `skipWhen` reads to skip a form. */
internal fun useSmileIDSampleFacts(
    product: UseSmileIDSampleProduct,
    bindsIdDetails: Boolean,
    route: UseSmileIDSampleFlowRoute,
): Set<UseSmileIDSampleFact> = buildSet {
    if (product == UseSmileIDSampleProduct.SmartSelfieAuth) add(UseSmileIDSampleFact.NeedsUserId)
    if (product.needsIdDetails && !bindsIdDetails) add(UseSmileIDSampleFact.NeedsIdDetails)
    if (route == UseSmileIDSampleFlowRoute.Fullscreen) add(UseSmileIDSampleFact.FullScreenRun)
}

/** [useSmileIDSampleFacts] for [product] under this launch and its live token. */
internal fun UseSmileIDSampleAppState.njiaFactsFor(product: UseSmileIDSampleProduct): Set<UseSmileIDSampleFact> =
    useSmileIDSampleFacts(product, tokenBindsIdDetails(product), launchArgs.route)

/** The wizard's steps in the order `next` walks them: the consent form, the two optional forms and the run's two forms. */
private val WIZARD = listOf(
    UseSmileIDSampleStep.ConsentDetailsForm,
    UseSmileIDSampleStep.AuthUserId,
    UseSmileIDSampleStep.IdDetailsForm,
    UseSmileIDSampleStep.SdkFlow,
    UseSmileIDSampleStep.SdkFlowFullScreen,
)

/** Where a product tap goes: the consent form unless the token binds user details, else the first wizard step [facts] don't skip. */
internal fun NjiaGraph<UseSmileIDSampleStep, UseSmileIDSampleFact>.firstStepFor(
    facts: Set<UseSmileIDSampleFact>,
    bindsUserDetails: Boolean,
): String = WIZARD
    .drop(if (bindsUserDetails) 1 else 0)
    .map { kind -> steps.first { it.kind == kind } }
    .first { it.skipWhen?.holdsFor(facts) != true }
    .id

/** [firstStepFor] under this launch and its live token. */
internal fun UseSmileIDSampleAppState.njiaFirstStepFor(
    graph: NjiaGraph<UseSmileIDSampleStep, UseSmileIDSampleFact>,
    product: UseSmileIDSampleProduct,
): String = graph.firstStepFor(njiaFactsFor(product), tokenBindsUserDetails)
