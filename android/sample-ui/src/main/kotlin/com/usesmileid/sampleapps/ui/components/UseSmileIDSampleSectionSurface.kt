package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.smileid.designsystem.SmileDimens
import com.smileid.designsystem.smileCardStrokeColor
import com.smileid.designsystem.smileCardStrokeWidth
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The labelled rounded-hairline section card every detail/settings screen draws its rows on. */
@Composable
fun UseSmileIDSampleSectionSurface(
    modifier: Modifier = Modifier,
    label: String? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
    ) {
        if (label != null) UseSmileIDSampleSectionLabel(text = label)
        Surface(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(SmileDimens.radiusSurface),
            color = UseSmileIDSampleTheme.colors.surface,
            border = BorderStroke(smileCardStrokeWidth, smileCardStrokeColor),
        ) {
            Column { content() }
        }
    }
}
