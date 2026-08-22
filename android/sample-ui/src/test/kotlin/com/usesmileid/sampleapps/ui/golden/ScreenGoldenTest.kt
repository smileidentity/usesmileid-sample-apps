package com.usesmileid.sampleapps.ui.golden

import androidx.compose.runtime.Composable
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.screens.ProductsScreen
import com.usesmileid.sampleapps.ui.screens.ScanTokenScreen
import com.usesmileid.sampleapps.ui.screens.SettingsScreen
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleProductsState
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleSettingsState
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleSettings
import org.junit.Test

/** The screens U3 builds first, in the states `spec/screens.json` names for each. */
class ScreenGoldenTest : GoldenTest() {

    @Test
    fun settings() = goldens("screen_settings") { Settings() }

    @Test
    fun settings_max_font_scale() = assertSurvivesMaxFontScale { Settings() }

    @Test
    fun products() = goldens("screen_products") { Products(SANDBOX) }

    @Test
    fun products_max_font_scale() = assertSurvivesMaxFontScale { Products(SANDBOX) }

    @Test
    fun products_token_linked() = goldens("screen_products_token_linked") { Products(TOKEN_LINKED) }

    // A long handle next to an 8h countdown is where this card's row ran out of width.
    @Test
    fun products_token_linked_max_font_scale() = assertSurvivesMaxFontScale { Products(TOKEN_LINKED) }

    @Test
    fun products_token_expired() = goldens("screen_products_token_expired") { Products(TOKEN_EXPIRED) }

    @Test
    fun products_production() = goldens("screen_products_production") { Products(PRODUCTION) }

    @Test
    fun products_flow_in_flight() = goldens("screen_products_in_flight") { Products(IN_FLIGHT) }

    @Test
    fun scan_token() = goldens("screen_scan_token") { ScanToken() }

    @Test
    fun scan_token_max_font_scale() = assertSurvivesMaxFontScale { ScanToken() }

    private companion object {
        val SANDBOX = UseSmileIDSampleProductsState(
            environment = UseSmileIDSampleEnvironment.Sandbox,
            initials = "KA",
        )
        val TOKEN_LINKED = SANDBOX.copy(sessionId = "9f3a2c71", sessionRemaining = "7:59:12")
        val TOKEN_EXPIRED = SANDBOX.copy(sessionEnded = true)
        val PRODUCTION = SANDBOX.copy(environment = UseSmileIDSampleEnvironment.Production)
        val IN_FLIGHT = SANDBOX.copy(result = ResultFixtures.Running)
    }
}

@Composable
private fun Settings() = SettingsScreen(
    state = UseSmileIDSampleSettingsState(
        settings = UseSmileIDSampleSettings(),
        environment = UseSmileIDSampleEnvironment.Sandbox,
        environmentPinned = false,
        organisation = "UpTech Finance",
        initials = "KA",
        versionLabel = "UseSmileID Sample · 1.0.0",
    ),
    onSettingChange = { _, _ -> },
    onProfileClick = {},
    onNavRowClick = {},
    onOpenScenarioDrawer = {},
    onSignOut = {},
)

@Composable
private fun Products(state: UseSmileIDSampleProductsState) = ProductsScreen(
    state = state,
    onProductClick = {},
    onProfileClick = {},
    onScanClick = {},
)

@Composable
private fun ScanToken() = ScanTokenScreen(
    onBack = {},
    onLink = {},
    onSimulate = { _, _ -> },
    onPaste = { null },
)
