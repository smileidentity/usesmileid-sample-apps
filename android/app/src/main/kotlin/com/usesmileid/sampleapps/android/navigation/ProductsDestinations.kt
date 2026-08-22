package com.usesmileid.sampleapps.android.navigation

import androidx.compose.runtime.Composable
import com.ramcosta.composedestinations.annotation.Destination
import com.ramcosta.composedestinations.annotation.parameters.DeepLink
import com.ramcosta.composedestinations.generated.destinations.ProfileSwitchSheetDestination
import com.ramcosta.composedestinations.generated.destinations.ScanTokenScreenDestination
import com.ramcosta.composedestinations.navigation.DestinationsNavigator
import com.usesmileid.sampleapps.android.LocalUseSmileIDSampleAppState
import com.usesmileid.sampleapps.android.flow.firstStepFor
import com.usesmileid.sampleapps.ui.components.avatarColorForProfile
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleProductsState
import com.usesmileid.sampleapps.ui.state.toCountdown
import com.usesmileid.sampleapps.ui.screens.ProductsScreen as ProductsContent

/** The products tab's route. Function names are load-bearing: KSP names each generated `…Destination` after the function. */

@Destination<ProductsGraph>(start = true, deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.PRODUCTS)])
@Composable
fun ProductsScreen(navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    ProductsContent(
        state = UseSmileIDSampleProductsState(
            environment = app.environment,
            initials = app.profiles.active.initials,
            avatarColor = avatarColorForProfile(app.profiles.activeIndex),
            sessionId = app.session?.id?.takeIf { app.sessionActive },
            sessionRemaining = app.session
                ?.takeIf { app.sessionActive }
                ?.remaining(app.nowMillis)
                ?.toCountdown(),
            sessionEnded = app.sessionExpired,
            result = app.flowResult.snapshot,
        ),
        onProductClick = { navigator.navigate(app.firstStepFor(it)) },
        onProfileClick = { navigator.navigate(ProfileSwitchSheetDestination) },
        onScanClick = { navigator.navigate(ScanTokenScreenDestination) },
    )
}
