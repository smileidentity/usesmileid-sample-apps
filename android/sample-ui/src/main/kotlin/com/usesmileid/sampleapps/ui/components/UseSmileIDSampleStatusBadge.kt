package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.sp
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The four job statuses, Title case as the design sets them. */
enum class UseSmileIDSampleStatus(val label: String) {
    Clear("Clear"),
    Attention("Attention"),
    Blocked("Blocked"),
    Processing("Processing"),
}

/** A status pill. The design wants soft tinted fills; only the saturated `badge.<role>.*` pairs have landed, so the values are pending, not the treatment (spec/design-tokens.json → softBadgeFills). */
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
        style = UseSmileIDSampleTheme.type.textStyleOverline.copy(fontSize = BADGE_TEXT_SIZE),
        color = foreground,
        modifier = modifier
            .tagged(testId)
            .background(color = background, shape = RoundedCornerShape(SmileDimens.radiusControl))
            .padding(horizontal = SmileDimens.spacingXs, vertical = SmileDimens.space4),
    )
}

private val BADGE_TEXT_SIZE = 11.sp
