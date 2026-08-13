package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds

@Composable
fun VerificationDetailsScreen(jobId: String, modifier: Modifier = Modifier) {
    PlaceholderScreen(
        testId = UseSmileIDSampleTestIds.VERIFICATION_DETAILS_SCREEN,
        title = "Verification details",
        args = "jobId = $jobId",
        modifier = modifier,
    )
}
