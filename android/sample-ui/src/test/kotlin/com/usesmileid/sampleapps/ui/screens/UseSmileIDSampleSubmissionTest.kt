package com.usesmileid.sampleapps.ui.screens

import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsOff
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollToNode
import androidx.compose.ui.test.v2.runComposeUiTest
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.golden.ROBOLECTRIC_SDK
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleSetting
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleSettings
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** The Skip API submission switch: config.skipApiSubmission, off as the SDK defaults it. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [ROBOLECTRIC_SDK], qualifiers = "w411dp-h891dp-xhdpi")
@OptIn(ExperimentalTestApi::class)
class UseSmileIDSampleSubmissionTest {

    @Test
    fun `the switch starts off and reports a toggle`() = runComposeUiTest {
        val toggles = mutableListOf<Pair<UseSmileIDSampleSetting, Boolean>>()
        setContent {
            UseSmileIDSampleTheme {
                SettingsScreen(
                    state = UseSmileIDSampleSettingsState(
                        settings = UseSmileIDSampleSettings(),
                        organisation = "Organisation",
                        initials = "OR",
                        versionLabel = "Smile ID · 1.0.0",
                        deviceDark = false,
                    ),
                    onSettingChange = { setting, enabled -> toggles += setting to enabled },
                    onProfileClick = {},
                    onNavRowClick = {},
                    onCaptureModeClick = {},
                    onAppearanceClick = {},
                    onLanguageClick = {},
                    onOpenScenarioDrawer = null,
                    onSignOut = {},
                )
            }
        }
        onNodeWithTag(UseSmileIDSampleTestIds.SETTINGS_SCREEN)
            .performScrollToNode(hasTestTag(UseSmileIDSampleTestIds.SETTING_SKIP_API_SUBMISSION))
        val row = onNodeWithTag(UseSmileIDSampleTestIds.SETTING_SKIP_API_SUBMISSION)
        row.assertIsOff()
        onNodeWithText("Skip API submission").assertExists()

        row.performClick()
        assertEquals(listOf(UseSmileIDSampleSetting.SkipApiSubmission to true), toggles)
    }

    @Test
    fun `the SDK submits by default, and the switch moves no other row`() {
        val defaults = UseSmileIDSampleSettings()
        assertFalse(defaults.skipApiSubmission)
        val skipped = defaults.withSetting(UseSmileIDSampleSetting.SkipApiSubmission, true)
        assertEquals(defaults.copy(skipApiSubmission = true), skipped)
    }
}
