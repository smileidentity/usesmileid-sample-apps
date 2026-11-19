package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.intl.LocaleList
import androidx.compose.ui.text.toUpperCase
import com.smileid.designsystem.SmileDimens
import com.smileid.designsystem.smileCardStrokeWidth
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** Which failure a banner names: warning for one trying again later can get past, error for one it can't. */
enum class UseSmileIDSampleBannerTone { Warning, Error }

/** The app's neutral banner, as the session-ended card draws it: an all-caps caption over the message. */
@Composable
fun UseSmileIDSampleBanner(
    caption: String,
    message: String,
    modifier: Modifier = Modifier,
    testId: String? = null,
) {
    val colors = UseSmileIDSampleTheme.colors
    Surface(
        modifier = modifier.fillMaxWidth().tagged(testId),
        shape = UseSmileIDSampleTheme.shapes.card,
        color = colors.surfaceMuted,
        border = BorderStroke(smileCardStrokeWidth, colors.cardStroke),
    ) {
        Column(
            modifier = Modifier
                .defaultMinSize(minHeight = SmileDimens.space64)
                .padding(SmileDimens.spacingMd),
            verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs),
        ) {
            Text(
                text = caption.toUpperCase(LocaleList.current),
                style = UseSmileIDSampleTheme.type.textStyleOverline,
                color = colors.banner.text,
            )
            Text(
                text = message,
                style = UseSmileIDSampleTheme.type.textStyleBodyStrong,
                color = colors.banner.title,
            )
        }
    }
}
