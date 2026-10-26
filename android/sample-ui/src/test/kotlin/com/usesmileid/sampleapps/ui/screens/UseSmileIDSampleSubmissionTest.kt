package com.usesmileid.sampleapps.ui.screens

import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertIsNotSelected
import androidx.compose.ui.test.assertIsSelected
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollToNode
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.v2.runComposeUiTest
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.golden.ROBOLECTRIC_SDK
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleSettings
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleSubmission
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** The API submission row and its sheet: config.skipApiSubmission, picked like the capture mode. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [ROBOLECTRIC_SDK], qualifiers = "w411dp-h891dp-xhdpi")
@OptIn(ExperimentalTestApi::class)
class UseSmileIDSampleSubmissionTest {

    @Test
    fun `the row names the choice and opens the sheet`() = runComposeUiTest {
        var opened = false
        setContent {
            UseSmileIDSampleTheme {
                SettingsScreen(
                    state = UseSmileIDSampleSettingsState(
                        settings = UseSmileIDSampleSettings(submission = UseSmileIDSampleSubmission.Skip),
                        organisation = "Organisation",
                        initials = "OR",
                        versionLabel = "Smile ID · 1.0.0",
                        deviceDark = false,
                    ),
                    onSettingChange = { _, _ -> },
                    onProfileClick = {},
                    onNavRowClick = {},
                    onCaptureModeClick = {},
                    onSubmissionClick = { opened = true },
                    onAppearanceClick = {},
                    onLanguageClick = {},
                    onOpenScenarioDrawer = null,
                    onSignOut = {},
                )
            }
        }
        onNodeWithTag(UseSmileIDSampleTestIds.SETTINGS_SCREEN)
            .performScrollToNode(hasTestTag(UseSmileIDSampleTestIds.SETTING_SUBMISSION))
        val row = onNodeWithTag(UseSmileIDSampleTestIds.SETTING_SUBMISSION)
        row.assert(hasText("Skip API submission"))

        row.performClick()
        assertTrue("the row opens the sheet", opened)
    }

    @Test
    fun `the sheet checks the choice and reports a pick`() = runComposeUiTest {
        val picked = mutableListOf<UseSmileIDSampleSubmission>()
        setContent {
            UseSmileIDSampleTheme {
                SubmissionSheet(
                    selected = UseSmileIDSampleSubmission.Submit,
                    onSelect = { picked += it },
                    onDismissRequest = {},
                )
            }
        }
        onNodeWithTag(UseSmileIDSampleTestIds.submissionOption("submit"))
            .assertIsSelected()
            .assert(hasText("Submit to Smile ID"))
        val skip = onNodeWithTag(UseSmileIDSampleTestIds.submissionOption("skip"))
        skip.assertIsNotSelected().assert(hasText("Skip API submission"))

        skip.performClick()
        assertEquals(listOf(UseSmileIDSampleSubmission.Skip), picked)
    }

    @Test
    fun `only skip turns on skipApiSubmission, and the SDK's default submits`() {
        assertEquals(UseSmileIDSampleSubmission.Submit, UseSmileIDSampleSettings().submission)
        assertFalse(UseSmileIDSampleSubmission.Submit.skipsApiSubmission)
        assertTrue(UseSmileIDSampleSubmission.Skip.skipsApiSubmission)
    }
}
