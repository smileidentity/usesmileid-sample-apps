package com.usesmileid.sampleapps.android.navigation

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import com.ramcosta.composedestinations.annotation.Destination
import com.ramcosta.composedestinations.annotation.parameters.DeepLink
import com.ramcosta.composedestinations.generated.destinations.ScanTokenScreenDestination
import com.ramcosta.composedestinations.navigation.DestinationsNavigator
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.android.LocalUseSmileIDSampleAppState
import com.usesmileid.sampleapps.ui.state.catalogueFamily
import com.usesmileid.sampleapps.android.flow.entryFor
import com.usesmileid.sampleapps.ui.components.avatarColorForProfile
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleProductsState
import com.usesmileid.sampleapps.ui.state.toCountdown
import com.usesmileid.sampleapps.ui.screens.ProductsScreen as ProductsContent

/** The products tab's route. Function names are load-bearing: KSP names each generated `…Destination` after the function. */

@Destination<ProductsGraph>(start = true, deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.PRODUCTS)])
@Composable
fun ProductsScreen(navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    val chrome = LocalUseSmileIDSampleChrome.current
    var switchingProfile by rememberUseSmileIDSampleSheetState(UseSmileIDSampleSheet.ProfileSwitch)
    // Back on the grid means the run's form is gone, so a list still arriving for it is cancelled.
    LaunchedEffect(Unit) { app.catalogue.stop() }
    ProductsContent(
        contentPadding = PaddingValues(bottom = chrome.navBarHeight + SmileDimens.spacingMd),
        state = UseSmileIDSampleProductsState(
            initials = app.profiles.active?.initials.orEmpty(),
            avatarColor = avatarColorForProfile(app.profiles.activeIndex),
            sessionId = app.session?.id?.takeIf { app.sessionActive },
            sessionRemaining = app.session
                ?.takeIf { app.sessionActive }
                ?.remaining(app.nowMillis)
                ?.toCountdown(),
            sessionEnded = app.sessionExpired,
            result = app.flowResult.snapshot,
        ),
        onProductClick = {
            if (!app.sessionLoaded) return@ProductsContent
            app.forms.startRun(app.profiles.active)
            val entry = app.entryFor(it)
            // Fetched ahead: the user-details form sits between, so the lists are usually there before the ID form.
            if (entry != ScanTokenScreenDestination && it.catalogueFamily != null) {
                app.catalogue.begin(app.environment, app.catalogueLocale)
                app.ensureCatalogue(it)
            }
            navigator.navigate(entry) { launchSingleTop = true }
        },
        onProfileClick = { switchingProfile = true },
        onScanClick = { navigator.navigate(ScanTokenScreenDestination) },
    )
    if (switchingProfile) ProfileSwitchSheet(onDismissRequest = { switchingProfile = false })
}
