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
import com.ramcosta.composedestinations.generated.destinations.ScanTokenScreenDestination
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
import kotlinx.coroutines.launch
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleFlowResult

/**
 * The single route hosting the SDK flow, in both presentations (R3). The SDK owns everything inside
 * it (R2): no host BackHandler, no host chrome. [productId] looks unused because KSP reads this
 * parameter list to generate the route's arguments, which the ViewModel then reads back.
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
        // A prior enrollment's id when the card holds one, so authentication has something enrolled.
        ?: buildSnapshot(viewModel.args, app, viewModel.runUserId(app.flowResult.userId))
            ?.also { viewModel.snapshot = it }
    if (snapshot == null) {
        LaunchedEffect(Unit) { navigator.popBackStack(FlowNavGraph, inclusive = true) }
        return
    }

    when (val preflight = remember(snapshot) { preflight(snapshot) }) {
        is FlowPreflight.NeedsDetails -> {
            LaunchedEffect(Unit) {
                navigator.navigate(ConsentDetailsFormScreenDestination(productId = snapshot.product.id)) {
                    // The graph, not the screen: a deep link synthesizes a form beneath the flow (§8.1).
                    popUpTo(FlowNavGraph) { inclusive = true }
                }
            }
            return
        }
        // Back to the scanner, not to a form: the run needs a token, and no form holds one.
        FlowPreflight.NeedsSession -> {
            LaunchedEffect(Unit) {
                navigator.navigate(ScanTokenScreenDestination) {
                    popUpTo(FlowNavGraph) { inclusive = true }
                }
            }
            return
        }
        // No form fixes this, so it takes the same exit as a mistyped product id — but it says why
        // on the result card first. A silent return to the product list is indistinguishable from a
        // dead tap, which is exactly how this looked on device.
        is FlowPreflight.Misconfigured -> {
            val issues = preflight.issues
            LaunchedEffect(Unit) {
                app.flowResult.recordBlocked(
                    issues.joinToString("; ") { it.message ?: it::class.simpleName.orEmpty() }
                        .ifBlank { "The flow did not validate" },
                )
                navigator.popBackStack(FlowNavGraph, inclusive = true)
            }
            return
        }
        FlowPreflight.Ready -> Unit
    }

    // Effects run after the SDK's first composition, which is early enough to deliver a Failure.
    LaunchedEffect(Unit) {
        if (viewModel.markRunStarted() && !viewModel.resultDelivered) app.flowResult.startFlow()
    }

    // A teardown-delivered cancel arrives after the route is gone, where navigating again would act
    // on whatever replaced it.
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
                            app.storeScope.launch {
                                app.jobStore.add(
                                    processingJob(snapshot, result.value),
                                    snapshot.liveSession?.bindings,
                                )
                            }
                            navigator.navigate(VerificationDetailsScreenDestination(jobId = result.value.jobId)) {
                                popUpTo(FlowNavGraph) { inclusive = true }
                                // A repeated delivery must not stack a second landing screen.
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

private fun processingJob(snapshot: FlowLaunchSnapshot, response: JobSubmissionResponse) = UseSmileIDSampleJob(
    id = response.jobId,
    userId = response.userId,
    product = snapshot.product,
    status = UseSmileIDSampleStatus.Processing,
    createdAtMillis = System.currentTimeMillis(),
    message = response.message,
    httpStatus = HTTP_ACCEPTED,
    // Taken from the snapshot, not re-read: the row records the run that produced it, and by the
    // time a result lands the active profile or the toggle may already have moved on.
    profileId = snapshot.partnerId,
    profileOrganisation = snapshot.partnerName,
    sandbox = snapshot.sandbox,
    sessionId = snapshot.liveSession?.id,
)

/** A failed run has no server-issued job id, so the landing route carries a stable non-id. */
private const val UNSUBMITTED_JOB_ID = "unsubmitted"
private const val HTTP_ACCEPTED = "202 Accepted"
