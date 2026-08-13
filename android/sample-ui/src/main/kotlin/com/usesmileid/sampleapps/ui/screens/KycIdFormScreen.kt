package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds

@Composable
fun KycIdFormScreen(productId: String, modifier: Modifier = Modifier) {
    PlaceholderScreen(
        testId = UseSmileIDSampleTestIds.KYC_FORM_SCREEN,
        title = "ID details",
        args = "productId = $productId",
        modifier = modifier,
    )
}
