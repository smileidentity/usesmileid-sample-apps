package com.usesmileid.sampleapps.ui.components

import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The platform switch styled from semantic tokens — deliberately not hand-drawn, since the design system has no switch contract (spec/components.json → Switch). */
@Composable
fun UseSmileIDSampleSwitch(
    checked: Boolean,
    onCheckedChange: ((Boolean) -> Unit)?,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    testId: String? = null,
) {
    val colors = UseSmileIDSampleTheme.colors
    Switch(
        checked = checked,
        onCheckedChange = onCheckedChange,
        enabled = enabled,
        modifier = modifier.tagged(testId),
        colors = SwitchDefaults.colors(
            checkedThumbColor = colors.surface,
            checkedTrackColor = colors.primary,
            checkedBorderColor = colors.primary,
            uncheckedThumbColor = colors.surface,
            uncheckedTrackColor = colors.border,
            uncheckedBorderColor = colors.border,
            disabledCheckedThumbColor = colors.surface,
            disabledCheckedTrackColor = colors.textMuted,
            disabledCheckedBorderColor = colors.textMuted,
            disabledUncheckedThumbColor = colors.surfaceMuted,
            disabledUncheckedTrackColor = colors.border,
            disabledUncheckedBorderColor = colors.border,
        ),
    )
}
