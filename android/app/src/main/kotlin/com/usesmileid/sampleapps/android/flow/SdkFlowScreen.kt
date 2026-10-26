package com.usesmileid.sampleapps.android.flow

import com.usesmileid.sampleapps.android.navigation.LocalUseSmileIDSampleEngine
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleStep
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleStepScope
import com.usesmileid.sampleapps.android.navigation.leaveRun
import com.usesmileid.sampleapps.android.navigation.leaveToProducts
import com.usesmileid.sampleapps.android.navigation.runProductId

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import android.content.res.Configuration
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import com.usesmileid.core.models.UseSmileIDResult
import com.usesmileid.data.model.CapturedJob
import com.usesmileid.data.model.JobSubmissionResponse
import com.usesmileid.presentation.flow.dsl.UseSmileIDBuilder
import com.usesmileid.presentation.flow.validation.ValidationState
import com.usesmileid.sampleapps.android.LocalUseSmileIDSampleAppState
import com.usesmileid.sampleapps.android.extension.useSmileIDSampleShellExtension
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowStatus
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import kotlinx.coroutines.launch
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario
import com.usesmileid.sampleapps.android.scan.UseSmileIDSampleCameraHold
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleFlowResult
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleRunIntent
import java.io.File

/** The step hosting the SDK flow, in both presentations (R3); the SDK owns everything inside it (R2): no host BackHandler, no host chrome. */
@Composable
internal fun SdkFlowScreen(scope: UseSmileIDSampleStepScope, viewModel: SdkFlowViewModel = viewModel()) {
    val app = LocalUseSmileIDSampleAppState.current
    val engine = LocalUseSmileIDSampleEngine.current
    val route = if (scope.step.kind == UseSmileIDSampleStep.SdkFlowFullScreen) UseSmileIDSampleFlowRoute.Fullscreen else UseSmileIDSampleFlowRoute.Shell
    LaunchedEffect(route) { app.flowResult.enterRoute(route) }
    if (!app.profiles.loaded || !app.sessionLoaded) return

    // Once per entry: the ViewModel and its args are scoped to this back-stack entry, so no key can change.
    val snapshot = remember {
        viewModel.snapshot
            ?: buildSnapshot(engine.runProductId(scope.entry), route, app)
                ?.also { viewModel.snapshot = it }
    }
    if (snapshot == null) {
        LaunchedEffect(Unit) { engine.leaveToProducts() }
        return
    }

    when (val preflight = remember(snapshot) { preflight(snapshot) }) {
        is FlowPreflight.NeedsDetails -> {
            LaunchedEffect(Unit) {
                // In the run's place, not over it: a deep link synthesizes a form beneath the flow (§8.1).
                engine.leaveRun(scope.entry, UseSmileIDSampleStep.ConsentDetailsForm.wireName, arg = snapshot.product.id)
            }
            return
        }
        FlowPreflight.NeedsUserId -> {
            LaunchedEffect(Unit) {
                engine.leaveRun(scope.entry, UseSmileIDSampleStep.AuthUserId.wireName, arg = snapshot.product.id)
            }
            return
        }
        // Back to the scanner, not to a form: the run needs a token, and no form holds one.
        FlowPreflight.NeedsSession -> {
            LaunchedEffect(Unit) {
                app.interruptedRun.send(
                    UseSmileIDSampleRunIntent(productId = snapshot.product.id, route = snapshot.route),
                )
                engine.leaveRun(scope.entry, UseSmileIDSampleStep.ScanToken.wireName)
            }
            return
        }
        // No form fixes this. It lands where the SDK's own Failure does, on the unsubmitted job's
        // details, so the reason is on screen: the builder's validate() returns build()'s verdict,
        // so a flow the SDK would refuse stops here, and a silent return to the product list would
        // read as a dead tap.
        is FlowPreflight.Misconfigured -> {
            val issues = preflight.issues
            LaunchedEffect(Unit) {
                app.flowResult.recordBlocked(
                    issues.joinToString("; ") { it.message ?: it::class.simpleName.orEmpty() }
                        .ifBlank { "The flow did not validate" },
                    snapshot.environment,
                )
                engine.leaveRun(scope.entry, UseSmileIDSampleStep.VerificationDetails.wireName, arg = UNSUBMITTED_JOB_ID)
            }
            return
        }
        FlowPreflight.Ready -> Unit
    }

    // Mounted with the run: the hold has to overlap this composition to contend with it.
    UseSmileIDSampleCameraHold(app.launchArgs.holdCamera, snapshot.product)

    // Effects run after the SDK's first composition, which is early enough to deliver a Failure.
    LaunchedEffect(Unit) {
        if (viewModel.markRunStarted() && !viewModel.resultDelivered) app.flowResult.startFlow(snapshot.environment)
    }

    // A teardown-delivered cancel arrives after the route is gone, where navigating again would act
    // on whatever replaced it.
    val composed = remember { mutableStateOf(true) }
    DisposableEffect(Unit) { onDispose { composed.value = false } }

    val hostScheme = if (snapshot.theme == UseSmileIDSampleThemeScenario.ClashingHost) {
        if (app.resolvedDark) darkColorScheme() else lightColorScheme()
    } else {
        MaterialTheme.colorScheme
    }
    // UseSmileIDBuilder takes no theme input, so the subtree's uiMode carries the app's appearance; see docs/theming.md.
    val configuration = LocalConfiguration.current
    val context = LocalContext.current
    // Probed once: a binder call whose answer cannot change while the process lives.
    val mlBackend = remember(context) { mlBackendFor(context) }
    val flowConfiguration = remember(configuration, app.resolvedDark) {
        Configuration(configuration).apply {
            uiMode = (uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or
                if (app.resolvedDark) Configuration.UI_MODE_NIGHT_YES else Configuration.UI_MODE_NIGHT_NO
        }
    }
    CompositionLocalProvider(LocalConfiguration provides flowConfiguration) {
        MaterialTheme(colorScheme = hostScheme) {
            UseSmileIDBuilder(modifier = Modifier.fillMaxSize()) {
                applying(snapshot, mlBackend = mlBackend, onTokenRefreshed = app.flowResult::recordRefreshCallback)
                useSmileIDSampleShellExtension?.customiseFlow(this, snapshot.product)
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
                                // A repeated delivery is stale once the run's entry has gone, so it stacks no second landing screen.
                                engine.leaveRun(scope.entry, UseSmileIDSampleStep.VerificationDetails.wireName, arg = result.value.jobId)
                            }
                            is UseSmileIDResult.Captured -> {
                                app.storeScope.launch { result.job.deleteFiles() }
                                engine.leaveRun(scope.entry, UseSmileIDSampleStep.VerificationDetails.wireName, arg = UNSUBMITTED_JOB_ID)
                            }
                            is UseSmileIDResult.Failure ->
                                engine.leaveRun(scope.entry, UseSmileIDSampleStep.VerificationDetails.wireName, arg = UNSUBMITTED_JOB_ID)
                            UseSmileIDResult.Cancelled ->
                                if (composed.value) engine.leaveToProducts()
                        }
                    }
                }
            }
        }
    }
}

/** What the result card records for a terminal result. */
internal fun recordResult(flowResult: UseSmileIDSampleFlowResult, result: UseSmileIDResult<JobSubmissionResponse>) {
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
        is UseSmileIDResult.Captured -> flowResult.recordResultCallback(status = UseSmileIDSampleFlowStatus.Captured)
    }
}

/** Deletes every file the job lists, then its session directory: this sample forwards nothing, and the SDK never deletes them. */
internal fun CapturedJob.deleteFiles() {
    (listOfNotNull(selfieImage, frontDocument, backDocument, visaDocument) + livenessImages).forEach(File::delete)
    sessionDirectory.deleteRecursively()
}

private fun processingJob(snapshot: FlowLaunchSnapshot, response: JobSubmissionResponse) = UseSmileIDSampleJob(
    id = response.jobId,
    userId = response.userId,
    product = snapshot.product,
    status = UseSmileIDSampleStatus.Processing,
    createdAtMillis = System.currentTimeMillis(),
    message = response.message,
    httpStatus = 202,
    // From the snapshot, not re-read: by the time a result lands the toggle may have moved on.
    sandbox = snapshot.sandbox,
    sessionId = snapshot.liveSession?.id,
    partnerId = snapshot.liveSession?.partnerId,
)

/** A failed or captured run has no server-issued job id, so the landing route carries a stable non-id. */
private const val UNSUBMITTED_JOB_ID = "unsubmitted"
