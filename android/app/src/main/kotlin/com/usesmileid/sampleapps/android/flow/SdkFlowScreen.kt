package com.usesmileid.sampleapps.android.flow

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
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
import com.usesmileid.sampleapps.android.LocalUseSmileIDSampleAppState
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleDeepLinks
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleFlowTransitions
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The single route hosting the SDK flow; a placeholder that runs the pre-flight but sets no running status, because nothing is handed to the SDK yet. */
@Destination<RootGraph>(style = UseSmileIDSampleFlowTransitions::class, deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.SDK_FLOW)])
@Composable
fun SdkFlowScreen(
    productId: String,
    route: UseSmileIDSampleFlowRoute = UseSmileIDSampleFlowRoute.Fullscreen,
) {
    val app = LocalUseSmileIDSampleAppState.current
    val validation = remember { UseSmileIDFlowBuilder().validate() }
    LaunchedEffect(route) { app.flowResult.enterRoute(route) }
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
            color = UseSmileIDSampleTheme.colors.textTitle,
            textAlign = TextAlign.Center,
        )
        Text(
            text = "productId = $productId · route = ${route.id}",
            style = MaterialTheme.typography.bodySmall,
            color = UseSmileIDSampleTheme.colors.textMuted,
            textAlign = TextAlign.Center,
        )
        Text(
            text = validation.describe(),
            style = MaterialTheme.typography.bodySmall,
            color = UseSmileIDSampleTheme.colors.textMuted,
            textAlign = TextAlign.Center,
        )
    }
}

private fun ValidationState.describe(): String = when (this) {
    is ValidationState.Valid -> "pre-flight: valid"
    is ValidationState.Invalid -> "pre-flight: ${issues.size} issue(s) — ${primaryIssue.message}"
}
