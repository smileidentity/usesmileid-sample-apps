package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.smileid.designsystem.SmileDimens
import com.smileid.designsystem.smileLabelTracking
import com.smileid.designsystem.smileLabelSize
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The date separator in the verifications list. Both halves arrive formatted, because both are locale-dependent. */
@Composable
fun UseSmileIDSampleDateGroupHeader(
    relative: String,
    absolute: String,
    modifier: Modifier = Modifier,
    testId: String? = null,
) {
    Text(
        // Two spaces either side of the dot, as the design sets it.
        text = "$relative  ·  $absolute",
        style = UseSmileIDSampleTheme.type.textStyleOverline.copy(
            fontSize = smileLabelSize,
            letterSpacing = smileLabelTracking,
        ),
        color = UseSmileIDSampleTheme.colors.textMuted,
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = SmileDimens.spacingXs)
            .tagged(testId),
    )
}
