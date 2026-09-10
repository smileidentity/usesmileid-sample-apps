package com.usesmileid.sampleapps.ui.golden

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.components.avatarColorForProfile
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleLicenseRef
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleLicenses
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleNotice
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario
import com.usesmileid.sampleapps.ui.screens.LicensesScreen
import com.usesmileid.sampleapps.ui.screens.ProductsScreen
import com.usesmileid.sampleapps.ui.screens.ProfileSwitchSheet
import com.usesmileid.sampleapps.ui.screens.ScanTokenScreen
import com.usesmileid.sampleapps.ui.screens.ScenarioDrawerSheet
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleScanReason
import com.usesmileid.sampleapps.ui.screens.SettingsScreen
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleProductsState
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleSettingsState
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleSettings
import org.junit.Test

/** The screens U3 builds first; `ScreenStateGoldenTest` is what holds these to `spec/screens.json`. */
class ScreenGoldenTest : GoldenTest() {

    /** The partner's screen: no DEBUG section, which is the only state the design draws. */
    @Test
    fun settings() = goldens("screen_settings") { Settings() }

    @Test
    fun settings_max_font_scale() = assertSurvivesMaxFontScale { Settings() }

    @Test
    fun settings_debug_build() = goldens("screen_settings_debug") { Settings(debug = true) }

    @Test
    fun settings_debug_build_max_font_scale() = assertSurvivesMaxFontScale { Settings(debug = true) }

    /** Agent mode on, so the mutex's two supporting lines are recorded rather than described. */
    @Test
    fun settings_agent_mode() = goldens("screen_settings_agent_mode") {
        Settings(settings = UseSmileIDSampleSettings(enhancedSmartSelfie = false, agentMode = true))
    }

    @Test
    fun settings_consent_bound_by_token() = goldens("screen_settings_consent_bound") {
        Settings(consentBoundByToken = true)
    }

    /** A different profile active: the row's organisation, initials and hue all move together. */
    @Test
    fun settings_alt_profile() = goldens("screen_settings_alt_profile") { Settings(profileIndex = 1) }

    /** The fourth hue, which is where the profile palette runs out and starts again. */
    @Test
    fun settings_newly_created_profile() = goldens("screen_settings_new_profile") { Settings(profileIndex = 3) }

    /** One sheet holds both sections, so the two spec states differ by which section's selection has moved. */
    @Test
    fun scenario_drawer_flow() = goldens("sheet_scenario_drawer_flow", fullWindow = true) {
        ScenarioDrawer(scenario = UseSmileIDSampleScenario.ExpiredToken)
    }

    @Test
    fun scenario_drawer_theme() = goldens("sheet_scenario_drawer_theme", fullWindow = true) {
        ScenarioDrawer(theme = UseSmileIDSampleThemeScenario.PartnerOverride)
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

    /** The design's second session state is the same card counting down towards its expiry. */
    @Test
    fun products_token_linked_late() =
        goldens("screen_products_token_linked_late") { Products(TOKEN_LINKED_LATE) }

    @Test
    fun products_token_expired() = goldens("screen_products_token_expired") { Products(TOKEN_EXPIRED) }

    @Test
    fun products_flow_in_flight() = goldens("screen_products_in_flight") { Products(IN_FLIGHT) }

    /** Products presents it, not Profiles: the sheet's own link resolves to the products route. */
    @Test
    fun profile_switch_sheet() = goldens("sheet_profile_switch", fullWindow = true) {
        Box(modifier = Modifier.fillMaxSize()) {
            Products(TOKEN_LINKED)
            ProfileSwitchSheet(
                profiles = ProfileFixtures.Seeded.all,
                activeId = ProfileFixtures.Seeded.activeId,
                onSelect = {},
                onDismissRequest = {},
            )
        }
    }

    @Test
    fun licenses() = goldens("screen_licenses") { Licenses(LICENCE_FIXTURE) }

    @Test
    fun licenses_max_font_scale() = assertSurvivesMaxFontScale { Licenses(LICENCE_FIXTURE) }

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

        /** The design's late countdown, at 1:40. */
        val TOKEN_LINKED_LATE = TOKEN_LINKED.copy(sessionRemaining = "1:40")
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
    profileIndex: Int = 0,
) = SettingsScreen(
    state = UseSmileIDSampleSettingsState(
        settings = settings,
        organisation = ProfileFixtures.WithCreated.all[profileIndex].organisation,
        initials = ProfileFixtures.WithCreated.all[profileIndex].initials,
        versionLabel = "Smile ID Sample App · 1.0.0",
        consentBoundByToken = consentBoundByToken,
        avatarColor = avatarColorForProfile(profileIndex),
    ),
    onSettingChange = { _, _ -> },
    onProfileClick = {},
    onNavRowClick = {},
    onOpenScenarioDrawer = if (debug) ({ }) else null,
    onSignOut = {},
)

@Composable
private fun ScenarioDrawer(
    scenario: UseSmileIDSampleScenario = UseSmileIDSampleScenario.Normal,
    theme: UseSmileIDSampleThemeScenario = UseSmileIDSampleThemeScenario.BrandDefault,
) = Box(modifier = Modifier.fillMaxSize()) {
    Settings(debug = true)
    ScenarioDrawerSheet(
        activeScenario = scenario,
        activeTheme = theme,
        onScenarioSelect = {},
        onThemeSelect = {},
        onDismissRequest = {},
    )
}

/** A fixture, not the shipped asset: one row of each kind. Expanding one is the device flow's job. */
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
