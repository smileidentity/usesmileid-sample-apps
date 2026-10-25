package com.usesmileid.sampleapps.ui.screens

import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.golden.ResultFixtures
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** A details link opens before the store reports, so "not loaded yet" must not read as "no such verification". */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class VerificationDetailsScreenTest {
    @get:Rule val compose = createComposeRule()

    @Test
    fun a_job_still_loading_is_not_drawn_as_missing() {
        details(pending = true)
        compose.onNodeWithTag(UseSmileIDSampleTestIds.DETAILS_EMPTY).assertDoesNotExist()
        compose.onNodeWithTag(UseSmileIDSampleTestIds.DETAILS_DELETE).assertDoesNotExist()
    }

    @Test
    fun a_job_the_store_does_not_have_is_drawn_as_missing() {
        details(pending = false)
        compose.onNodeWithTag(UseSmileIDSampleTestIds.DETAILS_EMPTY).assertExists()
    }

    private fun details(pending: Boolean) = compose.setContent {
        UseSmileIDSampleTheme {
            VerificationDetailsScreen(
                jobId = "job_missing",
                job = null,
                result = ResultFixtures.Failed,
                onBack = {},
                onDelete = {},
                onCopy = { _, _ -> },
                pending = pending,
            )
        }
    }
}
