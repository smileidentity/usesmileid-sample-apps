package com.usesmileid.sampleapps.ui.components

import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertHasClickAction
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.v2.runComposeUiTest
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.golden.ROBOLECTRIC_SDK
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * The Play listing declares that all functionality is available without special access, which is only
 * true while a reviewer can mint a fixture token from the scan sheet without credentials. That makes
 * Simulate a compliance surface, not a convenience: gating it behind debug or probes would misdeclare
 * the listing. A checklist would rot, so the claim is asserted here instead.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [ROBOLECTRIC_SDK], qualifiers = "w411dp-h891dp-xhdpi")
@OptIn(ExperimentalTestApi::class)
class UseSmileIDSampleSimulateAffordanceTest {

    @Test
    fun `the scan sheet offers Simulate with no flag able to withhold it`() = runComposeUiTest {
        setContent {
            UseSmileIDSampleTheme {
                UseSmileIDSampleScanSheet(
                    state = UseSmileIDSampleScanSheetState(),
                    onTokenChange = {},
                    onPaste = {},
                    onLink = {},
                    onExpandToggle = {},
                    onSpanSelect = {},
                    onEnvironmentSelect = {},
                    onBindingsChange = {},
                    onSimulate = {},
                )
            }
        }

        onNodeWithTag(UseSmileIDSampleTestIds.TOKEN_SIMULATE)
            .assertIsDisplayed()
            .assertHasClickAction()
    }
}
