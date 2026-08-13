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
 * A floating pill holding the three tabs, plus a visually detached circular token button. The
 * token affordance is modelled separately because it navigates rather than switching tab, and it
 * carries the session countdown ring.
 *
 * [sessionProgress] drives that ring: 1f is a fresh session and 0f an expired one, derived from the
 * remaining time against an absolute deadline rather than from an animation duration, so it is
 * correct after the process is killed and restored.
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

/**
 * The detached token button, with the countdown ring drawn around it.
 *
 * The ring is painted outside the button's bounds rather than laid out around it: a 64dp ring in the
 * layout made the row wider than a 393dp screen, which pushed this whole affordance off the edge and
 * wrapped a tab label. It bleeds into the bar's own padding instead, which is what the design does.
 */
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

/**
 * The countdown ring around the token button.
 *
 * Green rather than primary blue, and drawn from the session's remaining time — a fixed animation
 * duration would drift from the deadline the session actually holds.
 */
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
        // tabFont, not Material's labelLarge: that slot carries the 16px bold button style here, and
        // three tabs at button size do not fit a 393dp screen alongside the token affordance.
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
