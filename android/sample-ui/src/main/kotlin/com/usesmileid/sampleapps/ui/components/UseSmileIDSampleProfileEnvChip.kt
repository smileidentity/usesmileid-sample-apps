package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** A status dot and the environment name on a pale fill. Display-only, and not fixed-width, because Production is wider than Sandbox. */
@Composable
fun UseSmileIDSampleProfileEnvChip(
    environment: UseSmileIDSampleEnvironment,
    modifier: Modifier = Modifier,
) {
    val colors = UseSmileIDSampleTheme.colors
    val dot = when (environment) {
        UseSmileIDSampleEnvironment.Sandbox -> colors.warningFill
        UseSmileIDSampleEnvironment.Production -> colors.successFill
    }
    Row(
        modifier = modifier
            .testTag(UseSmileIDSampleTestIds.ENV_CHIP)
            .background(color = colors.surfaceAlt, shape = RoundedCornerShape(SmileDimens.radiusChip))
            .defaultMinSize(minHeight = SmileDimens.space32)
            .padding(horizontal = SmileDimens.spacingSm, vertical = SmileDimens.spacingXxs),
        horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(modifier = Modifier.size(SmileDimens.spacingXs).background(color = dot, shape = CircleShape))
        Text(
            text = environment.label,
            style = UseSmileIDSampleTheme.type.textStyleCaption,
            color = colors.textBody,
        )
    }
}
