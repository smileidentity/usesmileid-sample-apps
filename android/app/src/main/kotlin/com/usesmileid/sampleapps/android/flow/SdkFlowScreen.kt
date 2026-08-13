package com.usesmileid.sampleapps.android.flow

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import com.ramcosta.composedestinations.annotation.Destination
import com.ramcosta.composedestinations.annotation.RootGraph
import com.ramcosta.composedestinations.annotation.parameters.DeepLink
import com.smileid.designsystem.SmileDimens
import com.usesmileid.presentation.flow.dsl.UseSmileIDFlowBuilder
import com.usesmileid.presentation.flow.validation.ValidationState
import com.usesmileid.sampleapps.android.navigation.SampleDeepLinks
import com.usesmileid.sampleapps.ui.theme.SampleTheme

/** Which container hosts the SDK flow. One route, two presentations. */
enum class FlowPresentation { Fullscreen, Shell }

/**
 * The single route that hosts the SDK flow. The SDK owns everything inside it — consent,
 * instructions, capture, preview and processing are never routes of this app's own.
 *
 * **This route is deliberately still a placeholder.** What it does today is the half of the
 * contract that does not depend on a configured flow: it parses its arguments, and it runs the
 * SDK's public, non-throwing pre-flight check so an invalid configuration is reported here rather
 * than reaching the flow. Letting an invalid configuration through would surface as a
 * `Failure`, which a test cannot tell apart from a real submission failure.
 *
 * Still to come, and the riskiest part of the app: hosting `UseSmileIDBuilder`, giving the inner
 * `NavController` the back gesture first, replacing rather than stacking on a result, and
 * surviving recreation with a saveable destination key.
 */
@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = SampleDeepLinks.SDK_FLOW)])
@Composable
fun SdkFlowScreen(productId: String, route: FlowPresentation = FlowPresentation.Fullscreen) {
    val validation = remember { UseSmileIDFlowBuilder().validate() }
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(SmileDimens.spacingMd),
        verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = "SDK flow",
            style = MaterialTheme.typography.headlineSmall,
            color = SampleTheme.colors.textTitle,
            textAlign = TextAlign.Center,
        )
        Text(
            text = "productId = $productId · route = ${route.name.lowercase()}",
            style = MaterialTheme.typography.bodySmall,
            color = SampleTheme.colors.textMuted,
            textAlign = TextAlign.Center,
        )
        Text(
            text = validation.describe(),
            style = MaterialTheme.typography.bodySmall,
            color = SampleTheme.colors.textMuted,
            textAlign = TextAlign.Center,
        )
    }
}

private fun ValidationState.describe(): String = when (this) {
    is ValidationState.Valid -> "pre-flight: valid"
    is ValidationState.Invalid -> "pre-flight: ${issues.size} issue(s) — ${primaryIssue.message}"
}
