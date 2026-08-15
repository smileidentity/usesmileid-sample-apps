package com.usesmileid.sampleapps.ui.components

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
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.smileid.designsystem.SmileColorLight
import com.smileid.designsystem.SmileDimens
import com.smileid.designsystem.SmileProductHue
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * A product tile: a gradient in the product's hue, that hue again as the shadow, and its icon as a watermark.
 *
 * Content is white on every card; `scrim` is what varies, because Document Verification's amber is too light.
 */
@Composable
fun UseSmileIDSampleProductCard(
    title: String,
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
            // Coloured shadows need API 28; below that this degrades to the platform's grey.
            .shadow(
                elevation = CARD_ELEVATION,
                shape = RoundedCornerShape(CARD_RADIUS),
                ambientColor = hue.from,
                spotColor = hue.from,
            )
            .tagged(testId),
        shape = RoundedCornerShape(CARD_RADIUS),
        color = Color.Transparent,
    ) {
        Box(
            modifier = Modifier
                .background(if (enabled) hue.brush() else Brush.linearGradient(flat(colors.surfaceMuted)))
                // The watermark bleeds past the corner, so the card clips rather than grows.
                .clipToBounds(),
        ) {
            if (ghost != null) {
                Box(
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .offset(x = SmileDimens.spacingMd, y = -SmileDimens.spacingXs),
                ) {
                    ghost(hue.scrim.copy(alpha = SCRIM_ALPHA))
                }
            }
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(SmileDimens.spacingSm),
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingLg),
            ) {
                Surface(
                    modifier = Modifier.size(SmileDimens.space40),
                    shape = RoundedCornerShape(SmileDimens.radiusMd),
                    color = tile,
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        if (icon != null) icon(hue.icon) else ProductMarkGlyph(tint = hue.icon)
                    }
                }
                // No gap: without those pixels "Authentication" breaks mid-word on a 174-wide card.
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.Bottom,
                ) {
                    // The design's 14px/600 is in neither token; size decides whether the label fits, so it wins.
                    Text(
                        text = title,
                        style = UseSmileIDSampleTheme.type.textStyleSubtitle,
                        color = content,
                        modifier = Modifier.weight(1f),
                    )
                    GoAffordance(tint = content, scrim = hue.scrim)
                }
            }
        }
    }
}

/** The stops sit inboard of the corners, which is what keeps the fill from banding. */
private fun SmileProductHue.brush() = Brush.linearGradient(
    colorStops = arrayOf(GRADIENT_START to from, GRADIENT_END to to),
    start = Offset.Zero,
    end = Offset.Infinite,
)

private fun flat(color: Color) = listOf(color, color)

@Composable
private fun GoAffordance(tint: Color, scrim: Color) {
    Surface(
        modifier = Modifier.size(SmileDimens.sizeIconLg),
        shape = CircleShape,
        color = scrim.copy(alpha = SCRIM_ALPHA),
    ) {
        Box(contentAlignment = Alignment.Center) {
            ChevronRightGlyph(tint = tint, size = SmileDimens.sizeIconSm)
        }
    }
}

/** 148 in the design; the scale reaches it as space64 twice plus space20. */
private val CARD_MIN_HEIGHT = SmileDimens.space64 * 2 + SmileDimens.space20

/** 22 in the design; radius.xl is the nearest the scale carries. */
private val CARD_RADIUS = SmileDimens.radiusXl

/** The design layers two shadows; Compose draws one, so this is the larger of the pair. */
private val CARD_ELEVATION = 10.dp

private const val SCRIM_ALPHA = 0.16f
private const val GRADIENT_START = 0.134f
private const val GRADIENT_END = 0.866f

/** The empty slot an odd count leaves: a layout affordance, not a placeholder card. */
@Composable
fun UseSmileIDSampleProductSlot(modifier: Modifier = Modifier) = Box(modifier = modifier.fillMaxWidth())

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
        color = UseSmileIDSampleTheme.colors.textTitle,
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = SmileDimens.spacingXs)
            .tagged(testId),
    )
}
