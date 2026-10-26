package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertIsNotSelected
import androidx.compose.ui.test.assertIsSelected
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.v2.runComposeUiTest
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.golden.ROBOLECTRIC_SDK
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleAppearance
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleSettings
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** The Theme row and its sheet, driven by the device's theme rather than the app's. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [ROBOLECTRIC_SDK], qualifiers = "w411dp-h891dp-xhdpi")
@OptIn(ExperimentalTestApi::class)
class UseSmileIDSampleAppearanceTest {

    @Test
    fun `the row follows the device under System and opens the sheet`() = runComposeUiTest {
        var deviceDark by mutableStateOf(true)
        var opened = false
        setContent {
            UseSmileIDSampleTheme {
                SettingsScreen(
                    state = UseSmileIDSampleSettingsState(
                        settings = UseSmileIDSampleSettings(),
                        organisation = "Organisation",
                        initials = "OR",
                        versionLabel = "Smile ID · 1.0.0",
                        deviceDark = deviceDark,
                    ),
                    onSettingChange = { _, _ -> },
                    onProfileClick = {},
                    onNavRowClick = {},
                    onCaptureModeClick = {},
                    onAppearanceClick = { opened = true },
                    onLanguageClick = {},
                    onOpenScenarioDrawer = null,
                    onSignOut = {},
                )
            }
        }
        val row = onNodeWithTag(UseSmileIDSampleTestIds.SETTING_APPEARANCE)
        row.assert(hasText("System (Dark)"))

        deviceDark = false
        waitForIdle()
        row.assert(hasText("System (Light)"))

        row.performClick()
        assertTrue("the row opens the sheet", opened)
    }

    @Test
    fun `the sheet checks the choice, names the device on System, and reports a pick`() = runComposeUiTest {
        var deviceDark by mutableStateOf(true)
        val picked = mutableListOf<UseSmileIDSampleAppearance>()
        setContent {
            UseSmileIDSampleTheme {
                AppearanceSheet(
                    selected = UseSmileIDSampleAppearance.Light,
                    deviceDark = deviceDark,
                    onSelect = { picked += it },
                    onDismissRequest = {},
                )
            }
        }
        val system = onNodeWithTag(UseSmileIDSampleTestIds.appearanceOption("system"))
        system.assertIsNotSelected().assert(hasText("System (Dark)"))
        onNodeWithTag(UseSmileIDSampleTestIds.appearanceOption("light")).assertIsSelected()

        deviceDark = false
        waitForIdle()
        system.assert(hasText("System (Light)"))

        onNodeWithTag(UseSmileIDSampleTestIds.appearanceOption("dark")).performClick()
        assertEquals(listOf(UseSmileIDSampleAppearance.Dark), picked)
    }
}
