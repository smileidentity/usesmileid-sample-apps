package com.usesmileid.sampleapps.ui.storeart

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.v2.runComposeUiTest
import com.github.takahirom.roborazzi.captureRoboImage
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleJobStore
import com.usesmileid.sampleapps.ui.golden.ROBOLECTRIC_SDK
import com.usesmileid.sampleapps.ui.golden.ResultFixtures
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJobFilter
import com.usesmileid.sampleapps.ui.model.startOfDayMillis
import com.usesmileid.sampleapps.ui.screens.ProductsScreen
import com.usesmileid.sampleapps.ui.screens.SettingsScreen
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleProductsState
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleSettingsState
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleVerificationsState
import com.usesmileid.sampleapps.ui.screens.VerificationDetailsScreen
import com.usesmileid.sampleapps.ui.screens.VerificationsScreen
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleSettings
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

/**
 * Raw frames for the Play listing, rendered at the `android-phone` preset's 1080x1920 and written to
 * `src/test/store-art` — a different directory and a different class from the goldens, which is what
 * makes it impossible for a store-art change to repaint an assertion. These are an output artefact,
 * never an oracle; the goldens remain the only screenshots anything asserts on.
 *
 * Five panels, not six: a live camera preview is not a pure function of state, so the SDK's capture
 * screen is the one frame that needs a device. `android/maestro/store-shots.yaml` captures it.
 *
 * Every fixture here is synthetic — no real name, ID number, partner id or token — because the output
 * is published.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [ROBOLECTRIC_SDK], qualifiers = STORE_PHONE_QUALIFIERS)
@OptIn(ExperimentalTestApi::class)
class StoreArtTest {

    @Test
    fun products() = panel("products") {
        ProductsScreen(state = PRODUCTS, onProductClick = {}, onProfileClick = {}, onScanClick = {})
    }

    @Test
    fun token_session() = panel("token_session") {
        ProductsScreen(
            state = PRODUCTS.copy(sessionId = "9f3a2c71", sessionRemaining = "7:59:12"),
            onProductClick = {},
            onProfileClick = {},
            onScanClick = {},
        )
    }

    @Test
    fun verifications() = panel("verifications") {
        VerificationsScreen(
            state = UseSmileIDSampleVerificationsState(
                jobs = JOBS,
                counts = UseSmileIDSampleJobFilter.entries.associateWith { filter -> JOBS.count(filter::matches) },
                filter = UseSmileIDSampleJobFilter.All,
                selectMode = false,
                selected = emptySet(),
                todayStartMillis = startOfDayMillis(FIXED_NOW),
            ),
            onFilterChange = {},
            onSelectModeChange = {},
            onSelectionChange = { _, _ -> },
            onJobClick = {},
            onRemove = {},
        )
    }

    @Test
    fun verification_details() = panel("verification_details") {
        VerificationDetailsScreen(
            jobId = JOBS.first().id,
            job = JOBS.first(),
            result = ResultFixtures.Succeeded,
            onBack = {},
            onDelete = {},
            onCopy = { _, _ -> },
            // The result card is a product feature, and it is what makes this panel worth publishing.
            showProbes = true,
        )
    }

    @Test
    fun settings() = panel("settings") {
        SettingsScreen(
            state = UseSmileIDSampleSettingsState(
                settings = UseSmileIDSampleSettings(),
                organisation = "UpTech Finance",
                initials = "KA",
                versionLabel = "Smile ID Sample App · 1.0.0",
                consentBoundByToken = false,
            ),
            onSettingChange = { _, _ -> },
            onProfileClick = {},
            onNavRowClick = {},
            onOpenScenarioDrawer = null,
            onSignOut = {},
        )
    }

    /** Full-bleed, unlike the goldens' padded component host: a store panel is a whole screen. */
    private fun panel(name: String, content: @Composable () -> Unit) = runComposeUiTest {
        setContent {
            UseSmileIDSampleTheme(darkTheme = false) {
                Box(
                    modifier = Modifier
                        .testTag(PANEL)
                        .fillMaxSize()
                        .background(UseSmileIDSampleTheme.colors.background),
                ) {
                    content()
                }
            }
        }
        waitForIdle()
        onNodeWithTag(PANEL).captureRoboImage("src/test/store-art/$name.png")
    }

    private companion object {
        const val PANEL = "store_panel"

        /** 2026-07-16T11:50:12Z: fixed, so a re-render produces the same date headers and countdown. */
        const val FIXED_NOW = 1_784_202_612_000L
        val JOBS = UseSmileIDSampleJobStore.fixtures(FIXED_NOW)
        val PRODUCTS = UseSmileIDSampleProductsState(initials = "KA")
    }
}

/** 360x640dp at xxhdpi is 1080x1920px, which is storeshots' `android-phone` preset exactly. */
internal const val STORE_PHONE_QUALIFIERS = "w360dp-h640dp-xxhdpi"
