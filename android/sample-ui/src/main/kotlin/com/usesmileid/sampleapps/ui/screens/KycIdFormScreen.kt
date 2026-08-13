package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.SampleTestIds

@Composable
fun KycIdFormScreen(productId: String, modifier: Modifier = Modifier) {
    PlaceholderScreen(
        testId = SampleTestIds.KYC_FORM_SCREEN,
        title = "ID details",
        args = "productId = $productId",
        modifier = modifier,
    )
}
