package com.usesmileid.sampleapps.android.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.compose.currentStateAsState
import com.usesmileid.sampleapps.android.LocalUseSmileIDSampleAppState
import com.usesmileid.sampleapps.android.flow.UseSmileIDSampleFlowTokens
import com.usesmileid.sampleapps.android.flow.runEntryFor
import com.usesmileid.sampleapps.android.flow.runOnly
import com.usesmileid.sampleapps.android.scan.UseSmileIDSampleQrScanner
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleScanReason
import com.usesmileid.sampleapps.ui.state.resumesInFlow
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleRunIntent
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenDecoder
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import kotlinx.coroutines.launch
import com.usesmileid.sampleapps.ui.screens.ScanTokenScreen as ScanTokenContent

/** The token scanner: links a session, then returns, or carries an interrupted run on in its own place. */
@Composable
internal fun ScanTokenScreen(scope: UseSmileIDSampleStepScope) {
    val app = LocalUseSmileIDSampleAppState.current
    val engine = LocalUseSmileIDSampleEngine.current
    val clipboard = LocalClipboardManager.current
    var torchOn by rememberSaveable { mutableStateOf(false) }
    // Read here, cleared in the effect below: an abandoned composition must not swallow the run.
    val claimed = rememberSaveable { app.interruptedRun.pending?.saved() ?: emptyList() }
    val resuming = remember(claimed) { UseSmileIDSampleRunIntent.of(claimed) }
    // Owned by this visit, so leaving by any route drops it and a later scan cannot resurrect it.
    LaunchedEffect(Unit) { app.interruptedRun.clear() }

    // The resume waits for a different session, separating the token that sent us here from the new one.
    val arrivedWith = rememberSaveable { app.session?.id.orEmpty() }
    val arrivedEnded = rememberSaveable { app.sessionExpired }
    // RESUMED only once the enter transition ends, so a second tap on the nav bar's Token button cannot land on Simulate.
    val settled by LocalLifecycleOwner.current.lifecycle.currentStateAsState()
    var resumeHandled by rememberSaveable { mutableStateOf(false) }

    // One path for both entry routes — typed, pasted or simulated, a session is linked the same way.
    val link: (UseSmileIDSampleTokenSession) -> Unit = { session ->
        // On the app-level scope, so leaving this screen cannot cancel the write half-done.
        app.storeScope.launch { app.store.linkTokenSession(session) }
        // A resumed run leaves on the effect below instead.
        if (resuming == null) {
            app.interruptedRun.runPartnerId = session.partnerId
            scope.navigator.back()
        }
    }

    // Waits for the write to reach app state: re-entering against the expired session would bounce
    // straight back. Keyed on the session, not `sessionActive`, whose clock read would rebind the camera.
    val current = app.session
    LaunchedEffect(resuming, current, resumeHandled) {
        if (resuming == null || resumeHandled) return@LaunchedEffect
        val linked = current?.takeIf { it.id != arrivedWith } ?: return@LaunchedEffect
        resumeHandled = true
        if (linked.hasExpired(System.currentTimeMillis())) {
            // An already-expired relink cannot start the run, and the pill offers no retry — so leave
            // rather than freeze on a screen saying "linked".
            scope.navigator.back()
        } else {
            val product = UseSmileIDSampleProduct.entries.firstOrNull { it.id == resuming.productId }
            val intoFlow = resuming.resumesInFlow(app.interruptedRun.runPartnerId, linked.partnerId)
            app.interruptedRun.runPartnerId = linked.partnerId
            if (product == null) {
                scope.navigator.back()
            } else {
                val run = if (intoFlow) app.runOnly(product, resuming.route) else app.runEntryFor(engine.graph, product)
                // In the scanner's place, so a second quick tap is stale against an entry that has gone.
                engine.startRun(scope.entry, product, run, replace = scope.entry.id)
            }
        }
    }
    ScanTokenContent(
        // Why this screen opened, per R10: the redirect's message belongs to the screen it arrives at.
        reason = when {
            resuming == null -> null
            arrivedEnded -> UseSmileIDSampleScanReason.SessionEnded
            else -> UseSmileIDSampleScanReason.SessionNeeded
        },
        onBack = scope.navigator::back,
        onLink = link,
        onPaste = { clipboard.getText()?.text },
        onSimulate = { span, bindings, environment ->
            val minted = UseSmileIDSampleFlowTokens.session(
                span = span,
                bindings = bindings,
                environment = environment,
                nowMillis = System.currentTimeMillis(),
            )
            // The minter and the decoder have to agree, and a fixture that no longer decodes is a defect
            // rather than something to paper over with a fabricated session.
            UseSmileIDSampleTokenDecoder.session(minted)?.let(link)
        },
        torchOn = torchOn,
        onTorchToggle = { torchOn = !torchOn },
        // The camera lives in the shell: `sample-ui` runs under eight identities, and only this one
        // owns a scanner. It unbinds on leaving composition, so the SDK gets the camera back (§7.1).
        viewfinder = { modifier, enabled, onCandidate ->
            UseSmileIDSampleQrScanner(
                onCode = onCandidate,
                torchOn = torchOn,
                enabled = enabled,
                modifier = modifier,
            )
        },
        acceptsTaps = settled.isAtLeast(Lifecycle.State.RESUMED),
    )
}
