package com.usesmileid.sampleapps.android.navigation

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.android.LocalUseSmileIDSampleAppState
import com.usesmileid.sampleapps.ui.state.catalogueFamily
import com.usesmileid.sampleapps.android.flow.entryFor
import com.usesmileid.sampleapps.ui.components.avatarColorForProfile
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleProductsState
import com.usesmileid.sampleapps.ui.state.toCountdown
import com.usesmileid.sampleapps.ui.screens.ProductsScreen as ProductsContent

/** The products tab's root. */
@Composable
internal fun ProductsScreen(scope: UseSmileIDSampleStepScope) {
    val app = LocalUseSmileIDSampleAppState.current
    val engine = LocalUseSmileIDSampleEngine.current
    val chrome = LocalUseSmileIDSampleChrome.current
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
        onProductClick = { product ->
            if (!app.sessionLoaded) return@ProductsContent
            app.forms.startRun(app.profiles.active)
            val entry = app.entryFor(engine.graph, product)
            val toScanner = entry == null
            app.interruptedRun.runPartnerId = app.session?.partnerId.takeIf { !toScanner }
            // Fetched ahead: the user-details form sits between, so the lists are usually there before the ID form.
            if (!toScanner && product.catalogueFamily != null) {
                app.catalogue.begin(app.environment, app.catalogueLocale)
                app.ensureCatalogue(product)
            }
            if (entry == null) {
                scope.navigator.go(UseSmileIDSampleStep.ScanToken)
            } else {
                engine.startRun(scope.entry, product, entry)
            }
        },
        onProfileClick = { scope.navigator.go(UseSmileIDSampleStep.ProfileSwitch) },
        onScanClick = { scope.navigator.go(UseSmileIDSampleStep.ScanToken) },
    )
}
