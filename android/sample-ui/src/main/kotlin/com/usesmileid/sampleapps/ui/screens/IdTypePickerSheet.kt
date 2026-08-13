package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds

@Composable
fun IdTypePickerSheet(productId: String, modifier: Modifier = Modifier) {
    PlaceholderScreen(
        testId = UseSmileIDSampleTestIds.ID_TYPE_SHEET,
        title = "Select ID type",
        args = "productId = $productId",
        modifier = modifier,
    )
}
