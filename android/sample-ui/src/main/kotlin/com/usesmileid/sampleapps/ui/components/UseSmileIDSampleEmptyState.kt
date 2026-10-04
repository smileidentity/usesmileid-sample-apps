package com.usesmileid.sampleapps.ui.components

import com.usesmileid.sampleapps.ui.UseSmileIDSampleStrings
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** What a list says when it has nothing to show. Not in the design; [supportingText] only where the reader can act. */
@Composable
fun UseSmileIDSampleEmptyState(
    text: String,
    modifier: Modifier = Modifier,
    supportingText: String? = null,
    testId: String? = null,
    /** Only for a list that failed to load: retrying can change that answer, and nothing else here can. */
    onRetry: (() -> Unit)? = null,
    retryTestId: String? = null,
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
        if (onRetry != null) {
            TextButton(onClick = onRetry, modifier = Modifier.tagged(retryTestId)) {
                Text(
                    text = UseSmileIDSampleStrings.commonRetry,
                    style = UseSmileIDSampleTheme.type.textStyleBodyStrong,
                    color = UseSmileIDSampleTheme.colors.textLink,
                )
            }
        }
    }
}
