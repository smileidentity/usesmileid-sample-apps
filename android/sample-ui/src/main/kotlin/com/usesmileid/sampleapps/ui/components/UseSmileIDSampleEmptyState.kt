package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * What a list says when it has nothing to show. The design draws no empty frame for any of them, so
 * this is the app's own convention — defined once so four surfaces cannot each invent their own,
 * which is what they were doing.
 *
 * Muted, centred, and quiet: an empty list is a normal state, not a failure, and a loud frame in the
 * middle of a working screen reads as one. [supportingText] is for the surfaces where the reader can
 * do something about it; a search that matched nothing needs no advice.
 */
@Composable
fun UseSmileIDSampleEmptyState(
    text: String,
    modifier: Modifier = Modifier,
    supportingText: String? = null,
    testId: String? = null,
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .tagged(testId)
            .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.space32),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs),
    ) {
        Text(
            text = text,
            style = UseSmileIDSampleTheme.type.textStyleBodyStrong,
            color = UseSmileIDSampleTheme.colors.textBody,
            textAlign = TextAlign.Center,
        )
        if (supportingText != null) {
            Text(
                text = supportingText,
                style = UseSmileIDSampleTheme.type.textStyleCaption,
                color = UseSmileIDSampleTheme.colors.textMuted,
                textAlign = TextAlign.Center,
            )
        }
    }
}
