package com.usesmileid.sampleapps.ui.golden

import androidx.compose.runtime.Composable
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleLicenseRef
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleLicenses
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleNotice
import com.usesmileid.sampleapps.ui.screens.LicensesScreen
import com.usesmileid.sampleapps.ui.screens.ProductsScreen
import com.usesmileid.sampleapps.ui.screens.ScanTokenScreen
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleScanReason
import com.usesmileid.sampleapps.ui.screens.SettingsScreen
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleProductsState
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleSettingsState
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleSettings
import org.junit.Test

/** The screens U3 builds first, in the states `spec/screens.json` names for each. */
class ScreenGoldenTest : GoldenTest() {

    /** The partner's screen: no DEBUG section, which is also the only state the design draws. */
    @Test
    fun settings() = goldens("screen_settings") { Settings() }

    @Test
    fun settings_max_font_scale() = assertSurvivesMaxFontScale { Settings() }

    @Test
    fun settings_debug_build() = goldens("screen_settings_debug") { Settings(debug = true) }

    @Test
    fun settings_debug_build_max_font_scale() = assertSurvivesMaxFontScale { Settings(debug = true) }

    /** Agent mode on, so the mutex's two overridden supporting lines are recorded rather than described. */
    @Test
    fun settings_agent_mode() = goldens("screen_settings_agent_mode") {
        Settings(settings = UseSmileIDSampleSettings(enhancedSmartSelfie = false, agentMode = true))
    }

    @Test
    fun settings_consent_bound_by_token() = goldens("screen_settings_consent_bound") {
        Settings(consentBoundByToken = true)
    }

    @Test
    fun products() = goldens("screen_products") { Products(DEFAULT) }

    @Test
    fun products_max_font_scale() = assertSurvivesMaxFontScale { Products(DEFAULT) }

    @Test
    fun products_token_linked() = goldens("screen_products_token_linked") { Products(TOKEN_LINKED) }

    // A long handle next to an 8h countdown is where this card's row ran out of width.
    @Test
    fun products_token_linked_max_font_scale() = assertSurvivesMaxFontScale { Products(TOKEN_LINKED) }

    @Test
    fun products_token_expired() = goldens("screen_products_token_expired") { Products(TOKEN_EXPIRED) }

    @Test
    fun products_flow_in_flight() = goldens("screen_products_in_flight") { Products(IN_FLIGHT) }

    @Test
    fun licenses() = goldens("screen_licenses") { Licenses(LICENCE_FIXTURE) }

    @Test
    fun licenses_max_font_scale() = assertSurvivesMaxFontScale { Licenses(LICENCE_FIXTURE) }

    /** Generated at build time, so an absent asset is a packaging failure the screen must name. */
    @Test
    fun licenses_missing_asset() = goldens("screen_licenses_empty") { Licenses(UseSmileIDSampleLicenses()) }

    @Test
    fun scan_token() = goldens("screen_scan_token") { ScanToken() }

    @Test
    fun scan_token_max_font_scale() = assertSurvivesMaxFontScale { ScanToken() }

    @Test
    fun scan_token_redirected() = goldens("screen_scan_token_redirected") { ScanToken(SESSION_ENDED) }

    @Test
    fun scan_token_redirected_max_font_scale() = assertSurvivesMaxFontScale { ScanToken(SESSION_ENDED) }

    private companion object {
        val LICENCE_FIXTURE = UseSmileIDSampleLicenses(
            openSource = listOf(
                UseSmileIDSampleNotice(
                    artifact = "androidx.core:core-ktx",
                    version = "1.18.0",
                    licenses = listOf(
                        UseSmileIDSampleLicenseRef(
                            id = "Apache-2.0",
                            name = "The Apache Software License, Version 2.0",
                            url = "https://www.apache.org/licenses/LICENSE-2.0.txt",
                        ),
                    ),
                ),
                UseSmileIDSampleNotice(
                    artifact = "androidx.camera:camera-core",
                    version = "1.6.1",
                    licenses = listOf(
                        UseSmileIDSampleLicenseRef(
                            id = "Apache-2.0",
                            name = "The Apache Software License, Version 2.0",
                            url = "https://www.apache.org/licenses/LICENSE-2.0.txt",
                        ),
                        UseSmileIDSampleLicenseRef(
                            id = "BSD-3-Clause",
                            name = "BSD-3-Clause",
                            url = "https://opensource.org/license/bsd-3-clause",
                        ),
                    ),
                ),
                UseSmileIDSampleNotice(
                    artifact = "org.bouncycastle:bcprov-jdk18on",
                    version = "1.83",
                    licenses = listOf(
                        UseSmileIDSampleLicenseRef(
                            id = "Bouncy Castle Licence",
                            name = "Bouncy Castle Licence",
                            url = "https://www.bouncycastle.org/licence.html",
                        ),
                    ),
                ),
            ),
            googleServices = listOf(
                UseSmileIDSampleNotice(
                    artifact = "com.google.mlkit:barcode-scanning",
                    version = "17.3.0",
                    licenses = listOf(
                        UseSmileIDSampleLicenseRef(
                            id = null,
                            name = "ML Kit Terms of Service",
                            url = "https://developers.google.com/ml-kit/terms",
                        ),
                    ),
                ),
            ),
            texts = mapOf("Apache-2.0" to "Apache License\nVersion 2.0, January 2004\n\nTERMS AND CONDITIONS"),
        )

        val DEFAULT = UseSmileIDSampleProductsState(initials = "KA")
        val TOKEN_LINKED = DEFAULT.copy(sessionId = "9f3a2c71", sessionRemaining = "7:59:12")
        val TOKEN_EXPIRED = DEFAULT.copy(sessionEnded = true)

        val SESSION_ENDED = UseSmileIDSampleScanReason.SessionEnded
        val IN_FLIGHT = DEFAULT.copy(result = ResultFixtures.Running)
    }
}

@Composable
private fun Settings(
    settings: UseSmileIDSampleSettings = UseSmileIDSampleSettings(),
    consentBoundByToken: Boolean = false,
    debug: Boolean = false,
) = SettingsScreen(
    state = UseSmileIDSampleSettingsState(
        settings = settings,
        organisation = "UpTech Finance",
        initials = "KA",
        versionLabel = "Smile ID Sample App · 1.0.0",
        consentBoundByToken = consentBoundByToken,
    ),
    onSettingChange = { _, _ -> },
    onProfileClick = {},
    onNavRowClick = {},
    onOpenScenarioDrawer = if (debug) ({ }) else null,
    onSignOut = {},
)

/**
 * A fixture rather than the shipped asset: two hundred rows is not a golden, and the states worth
 * recording are one of each kind — a bundled text, a linked one, and a terms page. Expanding a row
 * is an interaction, so the device flow covers it rather than a screenshot.
 */
@Composable
private fun Licenses(licenses: UseSmileIDSampleLicenses) =
    LicensesScreen(licenses = licenses, onBack = {}, onOpenUrl = {})

@Composable
private fun Products(state: UseSmileIDSampleProductsState) = ProductsScreen(
    state = state,
    onProductClick = {},
    onProfileClick = {},
    onScanClick = {},
)

@Composable
private fun ScanToken(reason: UseSmileIDSampleScanReason? = null) = ScanTokenScreen(
    onBack = {},
    onLink = {},
    onSimulate = { _, _, _ -> },
    onPaste = { null },
    reason = reason,
)
