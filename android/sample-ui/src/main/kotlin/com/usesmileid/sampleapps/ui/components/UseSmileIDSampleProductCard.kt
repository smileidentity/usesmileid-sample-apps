package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.semantics.Role
import kotlin.math.abs
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** A product tile: the whole card takes a decorative fill with inverse text. The product→hue list is outstanding, so the caller passes the hue. */
@Composable
fun UseSmileIDSampleProductCard(
    title: String,
    onClick: () -> Unit,
    containerColor: Color,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    testId: String? = null,
    icon: @Composable ((Color) -> Unit)? = null,
) {
    val colors = UseSmileIDSampleTheme.colors
    // Whichever text token contrasts better: `textInverse` flips dark in dark mode, the fills do not.
    val onFill = listOf(colors.textInverse, colors.textTitle).maxBy {
        abs(it.luminance() - containerColor.luminance())
    }
    val content = if (enabled) onFill else colors.textMuted
    Surface(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier
            .fillMaxWidth()
            .defaultMinSize(minHeight = CARD_MIN_HEIGHT)
            .tagged(testId),
        shape = RoundedCornerShape(SmileDimens.radiusSurface),
        color = if (enabled) containerColor else colors.surfaceMuted,
    ) {
        // The ghost glyph bleeds off the corner, so the card clips rather than grows.
        Box(modifier = Modifier.clipToBounds()) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(SmileDimens.spacingSm),
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingLg),
            ) {
                Surface(
                    modifier = Modifier.size(SmileDimens.space40),
                    shape = RoundedCornerShape(SmileDimens.radiusSm),
                    color = colors.surface,
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        if (icon != null) icon(containerColor) else ProductMarkGlyph(tint = containerColor)
                    }
                }
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                    verticalAlignment = Alignment.Bottom,
                ) {
                    // Subtitle, not body-strong: at 16px 'Authentication' broke mid-word on a 174-wide card.
                    Text(
                        text = title,
                        style = UseSmileIDSampleTheme.type.textStyleSubtitle,
                        color = content,
                        modifier = Modifier.weight(1f),
                    )
                    GoAffordance(tint = content)
                }
            }
        }
    }
}

@Composable
private fun GoAffordance(tint: Color) {
    Surface(
        modifier = Modifier.size(SmileDimens.sizeIconLg),
        shape = CircleShape,
        color = Color.Transparent,
        border = BorderStroke(SmileDimens.borderWidthHairline, tint),
    ) {
        Box(contentAlignment = Alignment.Center) {
            ChevronRightGlyph(tint = tint, size = SmileDimens.sizeIconSm)
        }
    }
}

/** 148 in the design; space64 twice over is the nearest the scale reaches. */
private val CARD_MIN_HEIGHT = SmileDimens.space64 * 2

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
