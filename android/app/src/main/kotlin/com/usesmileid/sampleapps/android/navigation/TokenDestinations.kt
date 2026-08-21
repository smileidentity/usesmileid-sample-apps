package com.usesmileid.sampleapps.android.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalClipboardManager
import com.ramcosta.composedestinations.annotation.Destination
import com.ramcosta.composedestinations.annotation.RootGraph
import com.ramcosta.composedestinations.annotation.parameters.DeepLink
import com.ramcosta.composedestinations.navigation.DestinationsNavigator
import com.usesmileid.sampleapps.android.LocalUseSmileIDSampleAppState
import com.usesmileid.sampleapps.android.flow.UseSmileIDSampleFlowTokens
import com.usesmileid.sampleapps.android.scan.UseSmileIDSampleQrScanner
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
    // One path for both entry routes — typed, pasted or simulated, a session is linked the same way.
    val link: (UseSmileIDSampleTokenSession) -> Unit = { session ->
        // On the app-level scope, so leaving this screen cannot cancel the write half-done.
        app.storeScope.launch { app.store.linkTokenSession(session) }
        navigator.navigateUp()
    }
    ScanTokenContent(
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
