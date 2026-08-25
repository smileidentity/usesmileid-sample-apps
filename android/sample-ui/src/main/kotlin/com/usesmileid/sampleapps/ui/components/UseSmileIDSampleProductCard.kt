package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.text.ParagraphStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import com.smileid.designsystem.SMILE_CARD_FAMILY_WEIGHT
import com.smileid.designsystem.SmileColorLight
import com.smileid.designsystem.SmileDimens
import com.smileid.designsystem.SmileProductHue
import com.smileid.designsystem.smileCardStroke
import com.smileid.designsystem.smileCardTitleTracking
import com.smileid.designsystem.smileOffBlackLight
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** A product tile: a gradient in the product's hue, a hairline stroke, its icon as a watermark. */
@Composable
fun UseSmileIDSampleProductCard(
    title: String,
    family: String,
    onClick: () -> Unit,
    hue: SmileProductHue,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    testId: String? = null,
    icon: @Composable ((Color) -> Unit)? = null,
    ghost: @Composable ((Color) -> Unit)? = null,
) {
    val colors = UseSmileIDSampleTheme.colors
    // A hue is the same in both schemes, so anything drawn on it resolves from the light one.
    val content = if (enabled) SmileColorLight.colorTextInverse else colors.textMuted
    val tile = if (enabled) SmileColorLight.colorSurface else colors.surface
    Surface(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier
            .fillMaxWidth()
            .defaultMinSize(minHeight = CARD_MIN_HEIGHT)
            .tagged(testId),
        shape = RoundedCornerShape(CARD_RADIUS),
        color = Color.Transparent,
        // Fractional and anti-aliased rather than rounded away, so it reads as a hairline at any density.
        border = BorderStroke(smileCardStroke, colors.foreground),
    ) {
        Box(
            modifier = Modifier
                .background(if (enabled) hue.brush() else Brush.linearGradient(flat(colors.surfaceMuted)))
                .clipToBounds(),
        ) {
            if (ghost != null) {
                Box(
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .offset(x = SmileDimens.spacingMd, y = -SmileDimens.spacingXs),
                ) {
                    // The label's own ink, faint — not the go pill's scrim, which is the other colour.
                    ghost(content.copy(alpha = GHOST_ALPHA))
                }
            }
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(SmileDimens.spacingMd),
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingLg),
            ) {
                Surface(
                    modifier = Modifier.size(SmileDimens.space40),
                    shape = RoundedCornerShape(TILE_RADIUS),
                    color = tile,
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        if (icon != null) icon(hue.cardIcon) else ProductMarkGlyph(tint = hue.cardIcon)
                    }
                }
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.Bottom,
                ) {
                    Text(
                        text = cardLabel(title, family),
                        color = content,
                        modifier = Modifier.weight(1f),
                    )
                    GoAffordance(tint = content)
                }
            }
        }
    }
}

/** One text node with two runs, not two stacked [Text]s, which drift apart at large font scales. */
@Composable
private fun cardLabel(title: String, family: String) = buildAnnotatedString {
    val type = UseSmileIDSampleTheme.type
    val titleStyle = type.textStyleBodyStrong
    val familyStyle = type.textStyleCaption.copy(fontWeight = FontWeight(SMILE_CARD_FAMILY_WEIGHT))
    // Two paragraphs, not a newline: one paragraph would apply a single line height to both runs.
    withStyle(ParagraphStyle(lineHeight = titleStyle.lineHeight)) {
        withStyle(titleStyle.toSpanStyle().copy(letterSpacing = smileCardTitleTracking)) { append(title) }
    }
    withStyle(ParagraphStyle(lineHeight = familyStyle.lineHeight)) {
        withStyle(familyStyle.toSpanStyle()) { append(family) }
    }
}

/**
 * The design runs the outer stop past the card's edge, and Compose stops must land inside 0..1 — so the
 * last stop is the colour the gradient has actually reached by the edge, not the one it never gets to.
 */
private fun SmileProductHue.brush(): Brush {
    val start = from.copy(alpha = fromAlpha)
    val end = to.copy(alpha = toAlpha)
    val reached = if (stopEnd > 1f) lerp(start, end, (1f - stopStart) / (stopEnd - stopStart)) else end
    return Brush.linearGradient(
        colorStops = arrayOf(stopStart to start, minOf(stopEnd, 1f) to reached),
        start = Offset.Zero,
        end = Offset.Infinite,
    )
}

private fun flat(color: Color) = listOf(color, color)

/** The design draws one scrim here on all six cards, so it is not the hue's to vary. */
@Composable
private fun GoAffordance(tint: Color) {
    Surface(
        modifier = Modifier.size(SmileDimens.sizeIconLg),
        shape = CircleShape,
        color = smileOffBlackLight.copy(alpha = SCRIM_ALPHA),
    ) {
        Box(contentAlignment = Alignment.Center) {
            ArrowForwardGlyph(tint = tint)
        }
    }
}

private val CARD_MIN_HEIGHT = SmileDimens.space64 * 2 + SmileDimens.space20

private val CARD_RADIUS = SmileDimens.radiusSurface

private val TILE_RADIUS = SmileDimens.radiusLg

private const val SCRIM_ALPHA = 0.16f
private const val GHOST_ALPHA = 0.10f

/** Sentence-case headings, distinct from the all-caps [UseSmileIDSampleSectionLabel]. */
@Composable
fun UseSmileIDSampleSectionHeader(
    text: String,
    modifier: Modifier = Modifier,
    testId: String? = null,
) {
    Text(
        text = text,
        style = UseSmileIDSampleTheme.type.textStyleHeadingSection,
        color = UseSmileIDSampleTheme.colors.foreground,
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = SmileDimens.spacingXs)
            .tagged(testId),
    )
}
