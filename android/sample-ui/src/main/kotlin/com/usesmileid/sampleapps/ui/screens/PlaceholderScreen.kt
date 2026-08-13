package com.usesmileid.sampleapps.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.style.TextAlign
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * The walking skeleton's screen body: root id, title, and the arguments the route was given, so a
 * deep link's parsing is assertable on screen rather than in a log. Replaced screen by screen.
 */
@Composable
internal fun PlaceholderScreen(
    testId: String,
    title: String,
    modifier: Modifier = Modifier,
    args: String? = null,
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .testTag(testId)
            .padding(SmileDimens.spacingMd),
        verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.headlineSmall,
            color = UseSmileIDSampleTheme.colors.textTitle,
            textAlign = TextAlign.Center,
        )
        if (args != null) {
            Text(
                text = args,
                style = MaterialTheme.typography.bodySmall,
                color = UseSmileIDSampleTheme.colors.textMuted,
                textAlign = TextAlign.Center,
            )
        }
    }
}
