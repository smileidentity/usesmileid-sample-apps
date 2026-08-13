package com.usesmileid.sampleapps.ui.components

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * The all-caps group heading above a section — AUTHENTICATION, DETAILS, YOUR DETAILS.
 *
 * The caller passes the text already cased. Upper-casing here would go through the device locale,
 * and Turkish would turn a dotted i into a dotless one in a heading nobody reviewed.
 */
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
