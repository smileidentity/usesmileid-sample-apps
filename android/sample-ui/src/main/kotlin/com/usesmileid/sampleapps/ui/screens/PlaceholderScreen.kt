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
import com.usesmileid.sampleapps.ui.theme.SampleTheme

/**
 * The walking skeleton's screen body: the screen's root `sample_*` id, its title, and — for a
 * screen with navigation arguments — the arguments it was actually given.
 *
 * Every screen in `spec/screens.json` gets one so its route, deep link and id are reachable and
 * assertable before any fidelity work exists, and so a deep link's argument parsing is visible on
 * screen rather than only in a log. U1–U3 replace the bodies one screen at a time; the ids stay.
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
            color = SampleTheme.colors.textTitle,
            textAlign = TextAlign.Center,
        )
        if (args != null) {
            Text(
                text = args,
                style = MaterialTheme.typography.bodySmall,
                color = SampleTheme.colors.textMuted,
                textAlign = TextAlign.Center,
            )
        }
    }
}
