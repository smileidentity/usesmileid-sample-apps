package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds

/** The Consent Details Form — app-owned, shown before the SDK flow's own consent step. */
@Composable
fun UserDetailsScreen(productId: String, modifier: Modifier = Modifier) {
    PlaceholderScreen(
        testId = UseSmileIDSampleTestIds.USER_DETAILS_SCREEN,
        title = "Consent details",
        args = "productId = $productId",
        modifier = modifier,
    )
}
