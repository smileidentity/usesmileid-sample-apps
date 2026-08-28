package com.usesmileid.sampleapps.ui.storeart

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
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

/** Raw Play frames at the android-phone preset, in their own directory so they cannot repaint a golden. */
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
            showProbes = false,
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

    private fun panel(name: String, content: @Composable () -> Unit) = runComposeUiTest {
        setContent {
            UseSmileIDSampleTheme(darkTheme = false) {
                Box(
                    modifier = Modifier
                        .testTag(PANEL)
                        .fillMaxSize()
                        .background(UseSmileIDSampleTheme.colors.background)
                        .padding(top = STATUS_BAR_INSET),
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

        const val FIXED_NOW = 1_784_202_612_000L
        val JOBS = UseSmileIDSampleJobStore.fixtures(FIXED_NOW)
        val PRODUCTS = UseSmileIDSampleProductsState(initials = "KA")

        /** The device frame's punch-hole ends 32dp down and its corners eat 20dp; content clears both. */
        val STATUS_BAR_INSET = 40.dp
    }
}

internal const val STORE_PHONE_QUALIFIERS = "w360dp-h640dp-xxhdpi"
