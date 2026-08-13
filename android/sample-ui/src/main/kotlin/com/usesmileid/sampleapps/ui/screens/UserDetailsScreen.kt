package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.SampleTestIds

/**
 * The Consent Details Form — sample-owned, shown before the SDK flow starts for every product.
 * Not to be confused with the SDK's own consent step, which stays inside the flow.
 */
@Composable
fun UserDetailsScreen(productId: String, modifier: Modifier = Modifier) {
    PlaceholderScreen(
        testId = SampleTestIds.USER_DETAILS_SCREEN,
        title = "Consent details",
        args = "productId = $productId",
        modifier = modifier,
    )
}
