package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextAlign
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The three destinations the nav bar switches between. The token affordance is not one of them. */
enum class UseSmileIDSampleNavItem(val testId: String, val label: String) {
    Products(UseSmileIDSampleTestIds.NAV_PRODUCTS, "Products"),
    Verifications(UseSmileIDSampleTestIds.NAV_VERIFICATIONS, "Verifications"),
    Settings(UseSmileIDSampleTestIds.NAV_SETTINGS, "Settings"),
}

/**
 * A floating pill of three tabs, plus a detached token button that navigates rather than switching tab.
 *
 * [sessionProgress] drives its ring, 1f fresh to 0f expired, from the session's deadline rather than an animation.
 */
@Composable
fun UseSmileIDSampleNavBar(
    selected: UseSmileIDSampleNavItem,
    onSelect: (UseSmileIDSampleNavItem) -> Unit,
    onTokenClick: () -> Unit,
    modifier: Modifier = Modifier,
    sessionProgress: Float? = null,
) {
    Row(
        // The app draws edge to edge, so the bar owns its bottom inset. Without it the bar sits
        // under the system navigation bar and reports zero bounds to UI automation.
        modifier = modifier
            .windowInsetsPadding(WindowInsets.navigationBars)
            .padding(SmileDimens.spacingSm),
        horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Surface(
            // The pill yields width to the token affordance rather than pushing it off the row.
            modifier = Modifier.weight(1f, fill = false),
            shape = RoundedCornerShape(SmileDimens.radiusPill),
            color = UseSmileIDSampleTheme.colors.surface,
            border = BorderStroke(SmileDimens.borderWidthHairline, UseSmileIDSampleTheme.colors.border),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                UseSmileIDSampleNavItem.entries.forEach { item ->
                    NavBarTab(item = item, selected = item == selected, onClick = { onSelect(item) })
                }
            }
        }
        TokenAffordance(progress = sessionProgress, onClick = onTokenClick)
    }
}

/** The ring is painted outside the button's bounds, not laid out around it: at 64dp in the layout it pushed this off a 393dp screen. */
@Composable
private fun TokenAffordance(progress: Float?, onClick: () -> Unit) {
    val colors = UseSmileIDSampleTheme.colors
    val track = colors.border
    val fill = colors.successFill
    Box(
        modifier = Modifier
            .size(SmileDimens.sizeControlMd)
            .drawBehind {
                if (progress != null) {
                    drawTokenRing(progress = progress, track = track, fill = fill, inflate = RING_BLEED.toPx())
                }
            },
        contentAlignment = Alignment.Center,
    ) {
        Surface(
            modifier = Modifier.size(SmileDimens.sizeControlMd),
            shape = CircleShape,
            color = colors.primary,
            contentColor = colors.onPrimary,
        ) {
            Box(
                modifier = Modifier
                    .testTag(UseSmileIDSampleTestIds.NAV_TOKEN)
                    .clickable(onClick = onClick),
                contentAlignment = Alignment.Center,
            ) {
                ScanMarkGlyph(tint = colors.onPrimary)
            }
        }
    }
}

/** The countdown ring: green rather than primary, and driven by remaining time rather than a fixed duration. */
@Composable
fun UseSmileIDSampleTokenRing(
    progress: Float,
    modifier: Modifier = Modifier,
) {
    val track = UseSmileIDSampleTheme.colors.border
    val fill = UseSmileIDSampleTheme.colors.successFill
    Canvas(modifier = modifier) { drawTokenRing(progress = progress, track = track, fill = fill, inflate = 0f) }
}

/** [inflate] pushes the ring outside the bounds it is drawn in, so it can circle a smaller button. */
private fun DrawScope.drawTokenRing(progress: Float, track: Color, fill: Color, inflate: Float) {
    val stroke = Stroke(width = SmileDimens.borderWidthThick.toPx(), cap = StrokeCap.Round)
    val topLeft = stroke.width / 2f - inflate
    val diameter = size.minDimension - stroke.width + inflate * 2f
    drawArc(
        color = track,
        startAngle = 0f,
        sweepAngle = FULL_TURN,
        useCenter = false,
        topLeft = Offset(topLeft, topLeft),
        size = Size(diameter, diameter),
        style = stroke,
    )
    drawArc(
        color = fill,
        startAngle = QUARTER_TURN_UP,
        sweepAngle = FULL_TURN * progress.coerceIn(0f, 1f),
        useCenter = false,
        topLeft = Offset(topLeft, topLeft),
        size = Size(diameter, diameter),
        style = stroke,
    )
}

@Composable
private fun NavBarTab(item: UseSmileIDSampleNavItem, selected: Boolean, onClick: () -> Unit) {
    Text(
        text = item.label,
        // tabFont, not labelLarge: that slot is the 16px bold button style, which overflows a 393dp screen.
        style = UseSmileIDSampleTheme.type.tabFont,
        color = if (selected) UseSmileIDSampleTheme.colors.primary else UseSmileIDSampleTheme.colors.textMuted,
        textAlign = TextAlign.Center,
        modifier = Modifier
            .testTag(item.testId)
            .selectable(selected = selected, role = Role.Tab, onClick = onClick)
            .padding(horizontal = SmileDimens.spacingSm, vertical = SmileDimens.spacingSm),
    )
}

/** The ring is 68 around a 44 button, so it bleeds spacing.sm past the button on every side. */
private val RING_BLEED = SmileDimens.spacingSm
private const val FULL_TURN = 360f
private const val QUARTER_TURN_UP = -90f
