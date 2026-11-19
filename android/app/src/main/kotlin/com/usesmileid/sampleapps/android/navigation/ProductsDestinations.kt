package com.usesmileid.sampleapps.android.navigation

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import com.smileid.designsystem.SmileDimens
import com.usesmileid.njia.NjiaEntry
import com.usesmileid.njia.navigator
import com.usesmileid.sampleapps.android.LocalUseSmileIDSampleAppState
import com.usesmileid.sampleapps.android.UseSmileIDSampleAppState
import com.usesmileid.sampleapps.ui.state.catalogueFamily
import com.usesmileid.sampleapps.android.flow.entryFor
import com.usesmileid.sampleapps.ui.components.avatarColorForProfile
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
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
            app.startProductRun(engine, scope.entry, product)
        },
        onProfileClick = { scope.navigator.go(UseSmileIDSampleStep.ProfileSwitch) },
        onScanClick = { scope.navigator.go(UseSmileIDSampleStep.ScanToken) },
    )
}

/** A product tap's run from [from], in place of [replace] if given: fresh forms, the run's partner, and the scanner first with no live session. */
internal fun UseSmileIDSampleAppState.startProductRun(
    engine: UseSmileIDSampleEngine,
    from: NjiaEntry,
    product: UseSmileIDSampleProduct,
    replace: Long? = null,
) {
    // Fresh from the profile, so one run's ID details never carry into another, least of all another partner's.
    forms.startRun(profiles.active)
    val entry = entryFor(engine.graph, product)
    interruptedRun.runPartnerId = session?.partnerId.takeIf { entry != null }
    // Fetched ahead: the user-details form sits between, so the lists are usually there before the ID form.
    if (entry != null && product.catalogueFamily != null) {
        catalogue.begin(environment, catalogueLocale)
        ensureCatalogue(product)
    }
    if (entry == null) {
        engine.navigator(from).go(UseSmileIDSampleStep.ScanToken.wireName, replace = replace)
    } else {
        engine.startRun(from, product, entry, replace)
    }
}
