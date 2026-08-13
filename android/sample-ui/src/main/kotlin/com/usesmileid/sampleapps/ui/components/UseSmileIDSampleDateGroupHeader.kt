package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * The date separator in the verifications list — "TODAY · THU, 16 JUL 2026".
 *
 * Both halves are supplied already formatted: the relative word and the absolute date are
 * locale-dependent, so the caller formats them and this never holds a date string of its own.
 */
@Composable
fun UseSmileIDSampleDateGroupHeader(
    relative: String,
    absolute: String,
    modifier: Modifier = Modifier,
    testId: String? = null,
) {
    Text(
        text = "$relative · $absolute",
        style = UseSmileIDSampleTheme.type.textStyleOverline,
        color = UseSmileIDSampleTheme.colors.textMuted,
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = SmileDimens.spacingXs)
            .tagged(testId),
    )
}
