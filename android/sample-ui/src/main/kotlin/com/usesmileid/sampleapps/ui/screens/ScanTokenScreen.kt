package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds

@Composable
fun ScanTokenScreen(modifier: Modifier = Modifier) {
    PlaceholderScreen(UseSmileIDSampleTestIds.SCAN_TOKEN_SCREEN, "Scan token", modifier = modifier)
}
