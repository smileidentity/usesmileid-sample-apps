package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.TextAutoSize
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
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.ParagraphStyle
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import com.smileid.designsystem.SMILE_CARD_FAMILY_WEIGHT
import com.smileid.designsystem.SmileColorLight
import com.smileid.designsystem.SmileDimens
import com.smileid.designsystem.SmileProductHue
import com.smileid.designsystem.SMILE_SECTION_HEADER_WEIGHT
import com.smileid.designsystem.smileCardStrokeWidth
import com.smileid.designsystem.smileSectionHeaderLineHeight
import com.smileid.designsystem.smileSectionHeaderSize
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
    val tile = if (enabled) SmileColorLight.colorSurface else colors.surface
    // Every card's text and arrow are white, per the frame. Decided 2026-08-26: consistency
    // across the six beats per-card contrast, and the fix for the light fills belongs in the fill.
    val content = if (enabled) SmileColorLight.colorTextInverse else colors.textMuted
    // Six of these scroll; neither the fill nor the ink depends on anything that changes per frame.
    val fill = remember(hue, enabled, colors.surfaceMuted) {
        if (enabled) hue.brush() else Brush.linearGradient(flat(colors.surfaceMuted))
    }
    // The two marks the design draws at a fixed colour DO adapt, because one fixed value leaves the
    // go pill invisible on the darkest card and the ghost invisible on the lightest. Each takes the
    // ink for the end of the gradient it covers: the ghost the first stop, the go pill the last.
    val ghostInk = remember(hue) { hue.from.inkOn() }
    val goScrim = if (enabled) remember(hue) { hue.gradientEnd().inkOn() } else colors.textMuted
    Surface(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier
            .fillMaxWidth()
            .defaultMinSize(minHeight = CARD_MIN_HEIGHT)
            .tagged(testId),
        shape = UseSmileIDSampleTheme.shapes.card,
        color = Color.Transparent,
        // Fractional and anti-aliased rather than rounded away, so it reads as a hairline at any density.
        border = BorderStroke(smileCardStrokeWidth, UseSmileIDSampleTheme.colors.cardStroke),
    ) {
        Box(
            modifier = Modifier
                .background(fill)
                .clipToBounds(),
        ) {
            if (ghost != null) {
                Box(
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .offset(x = SmileDimens.spacingMd, y = -SmileDimens.spacingXs),
                ) {
                    ghost(ghostInk.copy(alpha = GHOST_ALPHA))
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
                    shape = UseSmileIDSampleTheme.shapes.tile,
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
                    CardLabel(title = title, family = family, color = content, modifier = Modifier.weight(1f))
                    GoAffordance(tint = content, scrim = goScrim)
                }
            }
        }
    }
}

/**
 * One text node with two runs, not two stacked [Text]s, which drift apart at large font scales.
 *
 * The frame is drawn at 393dp, where "Enhanced Doc." fits its column at 16sp; a 360dp phone would
 * wrap it, so the title steps down until both lines fit and the `em`-sized family follows. Only at
 * the default font scale — above it the label wraps instead, because a capped line count clips.
 */
@Composable
private fun CardLabel(title: String, family: String, color: Color, modifier: Modifier = Modifier) {
    val type = UseSmileIDSampleTheme.type
    val titleStyle = type.textStyleBodyStrong
    val familyStyle = type.textStyleCaption
    val familyEm = (familyStyle.fontSize.value / titleStyle.fontSize.value).em
    val fitsOneLine = LocalDensity.current.fontScale <= 1f
    val label = remember(title, family, familyEm, titleStyle, familyStyle) {
        buildAnnotatedString {
            // Two paragraphs, not a newline: one paragraph would apply a single line height to both.
            withStyle(ParagraphStyle(lineHeight = titleStyle.lineHeight)) { append(title) }
            withStyle(ParagraphStyle(lineHeight = familyStyle.lineHeight)) {
                withStyle(SpanStyle(fontSize = familyEm, fontWeight = FontWeight(SMILE_CARD_FAMILY_WEIGHT))) {
                    append(family)
                }
            }
        }
    }
    BasicText(
        text = label,
        modifier = modifier,
        style = titleStyle.copy(color = color, letterSpacing = smileCardTitleTracking),
        maxLines = if (fitsOneLine) 2 else Int.MAX_VALUE,
        autoSize = if (fitsOneLine) {
            TextAutoSize.StepBased(minFontSize = CARD_LABEL_MIN, maxFontSize = titleStyle.fontSize)
        } else {
            null
        },
    )
}

/**
 * The design runs the outer stop past the card's edge, and Compose stops must land inside 0..1 — so the
 * last stop is the colour the gradient has actually reached by the edge, not the one it never gets to.
 */
private fun SmileProductHue.brush() = Brush.linearGradient(
    colorStops = arrayOf(stopStart to from.copy(alpha = fromAlpha), minOf(stopEnd, 1f) to gradientEnd()),
    start = Offset.Zero,
    end = Offset.Infinite,
)

private fun SmileProductHue.gradientEnd(): Color {
    val start = from.copy(alpha = fromAlpha)
    val end = to.copy(alpha = toAlpha)
    return if (stopEnd > 1f) lerp(start, end, (1f - stopStart) / (stopEnd - stopStart)) else end
}

/** The ink that contrasts with this fill: one scrim across six cards this different leaves marks invisible at both ends. */
private fun Color.inkOn() =
    if (luminance() > INK_CROSSOVER) smileOffBlackLight else SmileColorLight.colorTextInverse

private fun flat(color: Color) = listOf(color, color)

@Composable
private fun GoAffordance(tint: Color, scrim: Color) {
    Surface(
        modifier = Modifier.size(SmileDimens.sizeIconLg),
        shape = CircleShape,
        color = scrim.copy(alpha = SCRIM_ALPHA),
    ) {
        Box(contentAlignment = Alignment.Center) {
            ArrowForwardGlyph(tint = tint)
        }
    }
}

private val CARD_MIN_HEIGHT = SmileDimens.space64 * 2 + SmileDimens.space20

private const val SCRIM_ALPHA = 0.16f
private const val GHOST_ALPHA = 0.10f

/** The standard white-or-dark crossover: above it a fill carries dark ink, below it light. */
private const val INK_CROSSOVER = 0.179f

/** The floor the card title steps down to before it is allowed to wrap. */
private val CARD_LABEL_MIN = 13.sp

/** Sentence-case headings, distinct from the all-caps [UseSmileIDSampleSectionLabel]. */
@Composable
fun UseSmileIDSampleSectionHeader(
    text: String,
    modifier: Modifier = Modifier,
    testId: String? = null,
) {
    Text(
        text = text,
        style = UseSmileIDSampleTheme.type.textStyleHeadingSection.copy(
            fontSize = smileSectionHeaderSize,
            lineHeight = smileSectionHeaderLineHeight,
            fontWeight = FontWeight(SMILE_SECTION_HEADER_WEIGHT),
        ),
        color = UseSmileIDSampleTheme.colors.foreground,
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = SmileDimens.spacingXs)
            .tagged(testId),
    )
}
