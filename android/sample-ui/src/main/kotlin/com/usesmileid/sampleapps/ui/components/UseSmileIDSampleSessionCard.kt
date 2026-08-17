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
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.sp
import com.smileid.designsystem.smileTokenSessionGradient
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The active token session: a filled green card with a m:ss countdown. [remaining] arrives formatted, because the deadline is absolute and the ticking is the screen's. */
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
        // A horizontal gradient in the token session's own green — not the flat feedback-success fill.
        color = Color.Transparent,
    ) {
        Box(modifier = Modifier.background(Brush.horizontalGradient(smileTokenSessionGradient))) {
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
                    // 10/700 at 1.0 tracking in the design.
                    text = "ACTIVE TOKEN SESSION",
                    style = UseSmileIDSampleTheme.type.textStyleOverline.copy(letterSpacing = LABEL_TRACKING),
                    color = colors.surface,
                )
                Text(
                    text = "Linked to session $sessionId",
                    style = UseSmileIDSampleTheme.type.textStyleTitle.copy(fontSize = SESSION_TITLE_SIZE),
                    color = colors.surface,
                )
            }
            Text(
                text = remaining,
                // 24/700, the design's numeric style.
                style = UseSmileIDSampleTheme.type.textStyleHeadingCard.copy(fontSize = COUNTDOWN_SIZE),
                color = colors.surface,
                modifier = Modifier.testTag(UseSmileIDSampleTestIds.SESSION_COUNTDOWN),
            )
            }
        }
    }
}

/** Replaces [UseSmileIDSampleSessionCard] on expiry: a neutral card, not a warning-accented one. */
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
        // Surface-muted per this component's token list; the banner contract's fill is a warm sand.
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
                // Clickable before the sizing modifiers, so the tap target is the padded box.
                modifier = Modifier
                    .clickable(role = Role.Button, onClick = onScan)
                    .minimumInteractiveComponentSize()
                    .padding(horizontal = SmileDimens.spacingXs),
            )
        }
    }
}

/** 1.0 tracking, 15 and 24 in the design; no token carries them. */
private val LABEL_TRACKING = 1.sp
private val SESSION_TITLE_SIZE = 15.sp
private val COUNTDOWN_SIZE = 24.sp
