package com.usesmileid.sampleapps.android.flow

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import com.ramcosta.composedestinations.annotation.Destination
import com.ramcosta.composedestinations.annotation.parameters.DeepLink
import com.ramcosta.composedestinations.generated.destinations.ConsentDetailsFormScreenDestination
import com.ramcosta.composedestinations.generated.destinations.VerificationDetailsScreenDestination
import com.ramcosta.composedestinations.generated.navgraphs.FlowNavGraph
import com.ramcosta.composedestinations.navigation.DestinationsNavigator
import com.usesmileid.core.models.UseSmileIDResult
import com.usesmileid.data.model.JobSubmissionResponse
import com.usesmileid.presentation.flow.dsl.UseSmileIDBuilder
import com.usesmileid.presentation.flow.validation.ValidationState
import com.usesmileid.sampleapps.android.LocalUseSmileIDSampleAppState
import com.usesmileid.sampleapps.android.navigation.FlowGraph
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleDeepLinks
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleFlowTransitions
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowStatus
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleFlowResult

/**
 * The single route hosting the SDK flow, in both presentations (R3). The SDK owns everything
 * inside it (R2): no host BackHandler, no host chrome, results delivered through [applying]'s
 * callbacks exactly once (§7.2).
 *
 * Both parameters are load-bearing even though the body reads [productId] only through the
 * ViewModel: KSP generates the route's arguments and the deep link's placeholders from this
 * parameter list, and the ViewModel reads the same values back out of the `SavedStateHandle`, so
 * every arrival path resolves to one host (R6).
 */
@Destination<FlowGraph>(style = UseSmileIDSampleFlowTransitions::class, deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.SDK_FLOW)])
@Composable
fun SdkFlowScreen(
    productId: String,
    route: UseSmileIDSampleFlowRoute = UseSmileIDSampleFlowRoute.Fullscreen,
    navigator: DestinationsNavigator,
    viewModel: SdkFlowViewModel = viewModel(),
) {
    val app = LocalUseSmileIDSampleAppState.current
    LaunchedEffect(route) { app.flowResult.enterRoute(route) }

    val snapshot = viewModel.snapshot
        // A prior enrollment's server-returned id when the card holds one, so Smart Selfie
        // Authentication authenticates against something that was actually enrolled.
        ?: buildSnapshot(viewModel.args, app, viewModel.runUserId(app.flowResult.userId))
            ?.also { viewModel.snapshot = it }
    if (snapshot == null) {
        LaunchedEffect(Unit) { navigator.popBackStack(FlowNavGraph, inclusive = true) }
        return
    }

    when (remember(snapshot) { preflight(snapshot) }) {
        is FlowPreflight.NeedsDetails -> {
            LaunchedEffect(Unit) {
                navigator.navigate(ConsentDetailsFormScreenDestination(productId = snapshot.product.id)) {
                    // The graph, not the screen: a deep link synthesizes a consent form beneath the
                    // flow, and popping only the flow would stack the redirect's form on top of it (§8.1).
                    popUpTo(FlowNavGraph) { inclusive = true }
                }
            }
            return
        }
        // Nothing the user can type fixes this, so it leaves the wizard entirely — the same exit a
        // mistyped product id takes, and still never the SDK.
        is FlowPreflight.Misconfigured -> {
            LaunchedEffect(Unit) { navigator.popBackStack(FlowNavGraph, inclusive = true) }
            return
        }
        FlowPreflight.Ready -> Unit
    }

    // Effects run *after* the SDK's first composition, and an invalid configuration delivers its
    // Failure during that composition — so the entry reset must not clobber a result that beat it.
    // Once per host besides, so a recreation keeps the counters the run has already earned.
    LaunchedEffect(Unit) {
        if (viewModel.markRunStarted() && !viewModel.resultDelivered) app.flowResult.startFlow()
    }

    // Distinguishes the SDK's in-flow cancel (navigate back to the tab) from the teardown-delivered
    // one after the user already popped the route, where navigating again would act on the wrong stack.
    val composed = remember { mutableStateOf(true) }
    DisposableEffect(Unit) { onDispose { composed.value = false } }

    val hostScheme = if (snapshot.theme == UseSmileIDSampleThemeScenario.ClashingHost) {
        if (app.settings.darkMode) darkColorScheme() else lightColorScheme()
    } else {
        MaterialTheme.colorScheme
    }
    MaterialTheme(colorScheme = hostScheme) {
        UseSmileIDBuilder(modifier = Modifier.fillMaxSize()) {
            applying(snapshot, onTokenRefreshed = app.flowResult::recordRefreshCallback)
            if (snapshot.scenario != UseSmileIDSampleScenario.NoCallback) {
                onResult = { result ->
                    viewModel.markResultDelivered()
                    recordResult(app.flowResult, result)
                    if (snapshot.scenario == UseSmileIDSampleScenario.ThrowingCallback) {
                        throw IllegalStateException("throwingCallback scenario: the host result callback throws")
                    }
                    when (result) {
                        is UseSmileIDResult.Success -> {
                            app.jobs.add(processingJob(snapshot.product, result.value))
                            navigator.navigate(VerificationDetailsScreenDestination(jobId = result.value.jobId)) {
                                popUpTo(FlowNavGraph) { inclusive = true }
                                // A repeated delivery must not stack a second landing screen. The
                                // counters still count every one — observing the SDK is their job.
                                launchSingleTop = true
                            }
                        }
                        is UseSmileIDResult.Failure ->
                            navigator.navigate(VerificationDetailsScreenDestination(jobId = UNSUBMITTED_JOB_ID)) {
                                popUpTo(FlowNavGraph) { inclusive = true }
                                launchSingleTop = true
                            }
                        UseSmileIDResult.Cancelled ->
                            if (composed.value) navigator.popBackStack(FlowNavGraph, inclusive = true)
                    }
                }
            }
        }
    }
}

private fun recordResult(flowResult: UseSmileIDSampleFlowResult, result: UseSmileIDResult<JobSubmissionResponse>) {
    when (result) {
        is UseSmileIDResult.Success -> flowResult.recordResultCallback(
            status = UseSmileIDSampleFlowStatus.Succeeded,
            jobId = result.value.jobId,
            userId = result.value.userId,
        )
        is UseSmileIDResult.Failure -> flowResult.recordResultCallback(
            status = UseSmileIDSampleFlowStatus.Failed,
            error = result.error.message ?: result.error::class.java.simpleName,
        )
        UseSmileIDResult.Cancelled -> flowResult.recordResultCallback(status = UseSmileIDSampleFlowStatus.Cancelled)
    }
}

private fun processingJob(product: UseSmileIDSampleProduct, response: JobSubmissionResponse) = UseSmileIDSampleJob(
    id = response.jobId,
    userId = response.userId,
    product = product,
    status = UseSmileIDSampleStatus.Processing,
    createdAtMillis = System.currentTimeMillis(),
    message = response.message,
    httpStatus = HTTP_ACCEPTED,
)

/** A failed run has no server-issued job id, so the landing route carries a stable non-id (§7.2's failure case). */
private const val UNSUBMITTED_JOB_ID = "unsubmitted"
private const val HTTP_ACCEPTED = "202 Accepted"
