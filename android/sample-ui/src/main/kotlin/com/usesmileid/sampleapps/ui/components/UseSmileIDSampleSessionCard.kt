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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.smileid.designsystem.SMILE_CARD_FAMILY_WEIGHT
import com.smileid.designsystem.SmileColorLight
import com.smileid.designsystem.smileCardStroke
import com.smileid.designsystem.smileTokenSessionGradient
import com.smileid.designsystem.smileTokenSessionGradientAlpha
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * The active token session and its m:ss countdown. [remaining] arrives formatted, because the deadline
 * is absolute and the ticking is the screen's.
 *
 * Both gradient stops are translucent, so this card composites against the page and reads differently
 * in the two schemes by design — see the `tokenSessionGreens` delta.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun UseSmileIDSampleSessionCard(
    sessionId: String,
    remaining: String,
    modifier: Modifier = Modifier,
) {
    val colors = UseSmileIDSampleTheme.colors
    // The gradient is the same in both schemes, so its ink is too: colors.surface is #272A35 in dark,
    // which put near-black text on the card. Same reasoning as the product card's content colour.
    val ink = SmileColorLight.colorTextInverse
    Surface(
        modifier = modifier.fillMaxWidth().testTag(UseSmileIDSampleTestIds.SESSION_CARD),
        shape = RoundedCornerShape(SmileDimens.radiusSurface),
        color = Color.Transparent,
        border = BorderStroke(smileCardStroke, colors.foreground),
    ) {
        Box(modifier = Modifier.background(Brush.horizontalGradient(sessionGradient()))) {
        FlowRow(
            modifier = Modifier
                .defaultMinSize(minHeight = SmileDimens.space64)
                .padding(SmileDimens.spacingMd),
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
                    style = UseSmileIDSampleTheme.type.textStyleOverline.copy(letterSpacing = LABEL_TRACKING),
                    color = ink,
                )
                // The design's full wording fits again now the run is 12sp rather than 15sp; it had been
                // shortened to "Session x" for the width an 8h countdown needed beside it.
                Text(
                    text = "Linked to session $sessionId",
                    style = UseSmileIDSampleTheme.type.textStyleCaption
                        .copy(fontWeight = FontWeight(SMILE_CARD_FAMILY_WEIGHT)),
                    color = ink,
                )
            }
            // The one value on this card that must stay whole, so the handle beside it yields instead.
            Text(
                text = remaining,
                style = UseSmileIDSampleTheme.type.textStyleHeadingCard.copy(fontSize = COUNTDOWN_SIZE),
                color = ink,
                softWrap = false,
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
        // The session card's stroke, per §7.10: color.border carries one light value in BOTH schemes.
        border = BorderStroke(smileCardStroke, colors.foreground),
    ) {
        FlowRow(
            modifier = Modifier
                .defaultMinSize(minHeight = SmileDimens.space64)
                .padding(SmileDimens.spacingMd),
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

/** The stops are opaque tokens and their alphas are recorded beside them, never baked into the hex. */
private fun sessionGradient() = smileTokenSessionGradient
    .mapIndexed { index, color -> color.copy(alpha = smileTokenSessionGradientAlpha[index]) }

private val LABEL_TRACKING = 1.sp
private val COUNTDOWN_SIZE = 24.sp
