package com.usesmileid.sampleapps.ui.components

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The all-caps group heading above a section. Callers pass the text already cased, so no locale upper-casing. */
@Composable
fun UseSmileIDSampleSectionLabel(
    text: String,
    modifier: Modifier = Modifier,
    testId: String? = null,
) {
    Text(
        text = text,
        style = UseSmileIDSampleTheme.type.textStyleOverline,
        color = UseSmileIDSampleTheme.colors.textMuted,
        modifier = modifier.tagged(testId),
    )
}
