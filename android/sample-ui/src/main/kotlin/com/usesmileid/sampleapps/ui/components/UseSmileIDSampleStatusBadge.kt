package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The four job statuses, in the design's vocabulary. Each maps to one feedback role. */
enum class UseSmileIDSampleStatus(val label: String) {
    Clear("CLEAR"),
    Attention("ATTENTION"),
    Blocked("BLOCKED"),
    Processing("PROCESSING"),
}

/**
 * A status pill.
 *
 * The design calls for SOFT tinted fills for all four statuses, and soft variants are being added to
 * the design system for exactly that. Until they land the token source only ships the saturated
 * `badge.<role>.background` / `.text` pairs, so those are what resolve here — the values are pending,
 * not the treatment. When `badge.<role>.soft-*` arrives this is one substitution per role and no
 * call site changes. Hardcoding the Figma hexes instead would bypass the token source.
 */
@Composable
fun UseSmileIDSampleStatusBadge(
    status: UseSmileIDSampleStatus,
    modifier: Modifier = Modifier,
    testId: String? = null,
) {
    val badge = UseSmileIDSampleTheme.colors.badge
    val (background, foreground) = when (status) {
        UseSmileIDSampleStatus.Clear -> badge.successBackground to badge.successText
        UseSmileIDSampleStatus.Attention -> badge.warningBackground to badge.warningText
        UseSmileIDSampleStatus.Blocked -> badge.errorBackground to badge.errorText
        UseSmileIDSampleStatus.Processing -> badge.infoBackground to badge.infoText
    }
    StatusPill(label = status.label, background = background, foreground = foreground, modifier = modifier, testId = testId)
}

@Composable
private fun StatusPill(
    label: String,
    background: Color,
    foreground: Color,
    modifier: Modifier,
    testId: String?,
) {
    Text(
        text = label,
        style = UseSmileIDSampleTheme.type.badgeFont,
        color = foreground,
        modifier = modifier
            .tagged(testId)
            .background(color = background, shape = RoundedCornerShape(SmileDimens.radiusChip))
            .padding(horizontal = SmileDimens.spacingXs, vertical = SmileDimens.space4),
    )
}
