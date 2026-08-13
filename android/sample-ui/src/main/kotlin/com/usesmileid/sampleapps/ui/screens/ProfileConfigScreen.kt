package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds

@Composable
fun ProfileConfigScreen(profileId: String, modifier: Modifier = Modifier) {
    PlaceholderScreen(
        testId = UseSmileIDSampleTestIds.PROFILE_CONFIG_SCREEN,
        title = "Profile configuration",
        args = "profileId = $profileId",
        modifier = modifier,
    )
}
