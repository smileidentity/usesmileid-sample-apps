package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * The active token session: a filled green card with inverse text and a large m:ss countdown.
 *
 * [remaining] is passed in already formatted, because the session is stored as an absolute deadline
 * and the ticking belongs to the screen — a counting-down value restarts at the wrong number after
 * process death.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun UseSmileIDSampleSessionCard(
    sessionId: String,
    remaining: String,
    modifier: Modifier = Modifier,
) {
    val colors = UseSmileIDSampleTheme.colors
    Surface(
        modifier = modifier.fillMaxWidth().testTag(UseSmileIDSampleTestIds.SESSION_CARD),
        shape = RoundedCornerShape(SmileDimens.radiusSurface),
        color = colors.successFill,
    ) {
        FlowRow(
            modifier = Modifier
                .defaultMinSize(minHeight = SmileDimens.space64)
                .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingSm),
            horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
            verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
            itemVerticalAlignment = Alignment.CenterVertically,
        ) {
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs),
            ) {
                Text(
                    text = "ACTIVE TOKEN SESSION",
                    style = UseSmileIDSampleTheme.type.textStyleOverline,
                    color = colors.onSuccess,
                )
                Text(
                    text = "Linked to session $sessionId",
                    style = UseSmileIDSampleTheme.type.textStyleBodyStrong,
                    color = colors.onSuccess,
                )
            }
            Text(
                text = remaining,
                style = UseSmileIDSampleTheme.type.textStyleHeadingCard,
                color = colors.onSuccess,
                modifier = Modifier.testTag(UseSmileIDSampleTestIds.SESSION_COUNTDOWN),
            )
        }
    }
}

/**
 * Replaces [UseSmileIDSampleSessionCard] once the session expires: a neutral grey card, not a
 * warning-accented one, with a text action back to the scanner.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun UseSmileIDSampleSessionEndedBanner(
    onScan: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = UseSmileIDSampleTheme.colors
    Surface(
        modifier = modifier.fillMaxWidth().testTag(UseSmileIDSampleTestIds.SESSION_ENDED_BANNER),
        shape = RoundedCornerShape(SmileDimens.radiusSurface),
        // surface-muted, per this component's token list, rather than the banner contract: the
        // design corrected this to a neutral card and the banner fill is a warm sand.
        color = colors.surfaceMuted,
        border = BorderStroke(SmileDimens.borderWidthHairline, colors.border),
    ) {
        FlowRow(
            modifier = Modifier
                .defaultMinSize(minHeight = SmileDimens.space64)
                .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingSm),
            horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
            verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
            itemVerticalAlignment = Alignment.CenterVertically,
        ) {
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs),
            ) {
                Text(
                    text = "TOKEN SESSION ENDED",
                    style = UseSmileIDSampleTheme.type.textStyleOverline,
                    color = colors.banner.text,
                )
                Text(
                    text = "Scan a token to relink",
                    style = UseSmileIDSampleTheme.type.textStyleBodyStrong,
                    color = colors.banner.title,
                )
            }
            Text(
                text = "Scan",
                style = UseSmileIDSampleTheme.type.linkFont,
                color = colors.primary,
                softWrap = false,
                // clickable before the sizing modifiers, so the tap target is the padded box rather
                // than the line box the link text would otherwise occupy.
                modifier = Modifier
                    .clickable(role = Role.Button, onClick = onScan)
                    .minimumInteractiveComponentSize()
                    .padding(horizontal = SmileDimens.spacingXs),
            )
        }
    }
}
