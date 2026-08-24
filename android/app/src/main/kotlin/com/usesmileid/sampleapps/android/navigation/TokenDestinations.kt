package com.usesmileid.sampleapps.android.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalClipboardManager
import com.ramcosta.composedestinations.annotation.Destination
import com.ramcosta.composedestinations.annotation.RootGraph
import com.ramcosta.composedestinations.annotation.parameters.DeepLink
import com.ramcosta.composedestinations.generated.destinations.ScanTokenScreenDestination
import com.ramcosta.composedestinations.generated.destinations.SdkFlowScreenDestination
import com.ramcosta.composedestinations.navigation.DestinationsNavigator
import com.usesmileid.sampleapps.android.LocalUseSmileIDSampleAppState
import com.usesmileid.sampleapps.android.flow.UseSmileIDSampleFlowTokens
import com.usesmileid.sampleapps.android.scan.UseSmileIDSampleQrScanner
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleScanReason
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleRunIntent
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenDecoder
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import kotlinx.coroutines.launch
import com.usesmileid.sampleapps.ui.screens.ScanTokenScreen as ScanTokenContent

/** The token-scanning route. Function names are load-bearing: KSP names each generated `…Destination` after the function. */

@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.SCAN_TOKEN)])
@Composable
fun ScanTokenScreen(navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    val clipboard = LocalClipboardManager.current
    var torchOn by rememberSaveable { mutableStateOf(false) }
    // Read here but cleared in the effect below: a composition that is abandoned mid-flight must not
    // swallow the run, and claiming it in a `remember` calculation would do exactly that.
    val claimed = rememberSaveable { app.interruptedRun.pending?.saved() ?: emptyList() }
    val resuming = remember(claimed) { UseSmileIDSampleRunIntent.of(claimed) }
    // Owned by this visit once it has really composed, so leaving by any route drops it with the
    // screen and a later unrelated scan cannot resurrect a run the partner has forgotten about.
    LaunchedEffect(Unit) { app.interruptedRun.clear() }

    // Which session was already on disk when this screen opened. The resume waits for a *different*
    // one, which is what separates "the expired token that sent me here" from "the one I just linked".
    val arrivedWith = rememberSaveable { app.session?.id.orEmpty() }
    var resumeHandled by rememberSaveable { mutableStateOf(false) }

    // One path for both entry routes — typed, pasted or simulated, a session is linked the same way.
    val link: (UseSmileIDSampleTokenSession) -> Unit = { session ->
        // On the app-level scope, so leaving this screen cannot cancel the write half-done.
        app.storeScope.launch { app.store.linkTokenSession(session) }
        // A resumed run leaves on the effect below instead, once the linked session reaches app state.
        if (resuming == null) navigator.navigateUp()
    }

    // Waits for the store's write to reach the session state rather than navigating on the link:
    // re-entering the flow against the expired session would fail the gate and bounce straight back.
    // Keyed on the session rather than on `sessionActive`, whose clock read would recompose this
    // screen — and rebind its camera — once a second for as long as a session is live.
    val current = app.session
    LaunchedEffect(resuming, current, resumeHandled) {
        if (resuming == null || resumeHandled) return@LaunchedEffect
        val linked = current?.takeIf { it.id != arrivedWith } ?: return@LaunchedEffect
        resumeHandled = true
        if (linked.hasExpired(System.currentTimeMillis())) {
            // Relinking a span that is already expired cannot start the run, and the pill has no retry
            // of its own — so leave rather than freeze on a screen saying "linked" that goes nowhere.
            // The product list explains the state through the ended banner it already has.
            navigator.navigateUp()
        } else {
            navigator.navigate(SdkFlowScreenDestination(productId = resuming.productId, route = resuming.route)) {
                popUpTo(ScanTokenScreenDestination) { inclusive = true }
                // Two quick Simulate taps mint two different tokens, so two writes land; without this
                // the second navigate stacks a duplicate run behind the first.
                launchSingleTop = true
            }
        }
    }
    ScanTokenContent(
        // Why this screen opened, per R10: the redirect's message belongs to the screen it arrives at.
        reason = UseSmileIDSampleScanReason.SessionEnded.takeIf { resuming != null },
        onBack = { navigator.navigateUp() },
        onLink = link,
        onPaste = { clipboard.getText()?.text },
        onSimulate = { span, bindings ->
            val minted = UseSmileIDSampleFlowTokens.session(
                span = span,
                bindings = bindings,
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
    )
}
