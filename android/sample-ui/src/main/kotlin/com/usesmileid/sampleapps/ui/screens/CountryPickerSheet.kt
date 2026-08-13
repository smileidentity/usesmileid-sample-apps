package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.SampleTestIds

@Composable
fun CountryPickerSheet(productId: String, modifier: Modifier = Modifier) {
    PlaceholderScreen(
        testId = SampleTestIds.COUNTRY_SHEET,
        title = "Select country",
        args = "productId = $productId",
        modifier = modifier,
    )
}
