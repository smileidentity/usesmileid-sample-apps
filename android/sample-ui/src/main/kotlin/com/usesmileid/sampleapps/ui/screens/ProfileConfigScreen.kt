package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.SampleTestIds

@Composable
fun ProfileConfigScreen(profileId: String, modifier: Modifier = Modifier) {
    PlaceholderScreen(
        testId = SampleTestIds.PROFILE_CONFIG_SCREEN,
        title = "Profile configuration",
        args = "profileId = $profileId",
        modifier = modifier,
    )
}
