package com.usesmileid.sampleapps.ui.components

import androidx.annotation.DrawableRes
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.defaultMinSize
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.smileid.designsystem.SMILE_TOKEN_RING_TRACK_OPACITY
import com.smileid.designsystem.smileTokenRing
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.R
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The three destinations the nav bar switches between. The token affordance is not one of them. */
enum class UseSmileIDSampleNavItem(
    val testId: String,
    val label: String,
    @DrawableRes val icon: Int,
) {
    Products(UseSmileIDSampleTestIds.NAV_PRODUCTS, "Products", R.drawable.sample_ic_products),
    Verifications(UseSmileIDSampleTestIds.NAV_VERIFICATIONS, "Verifications", R.drawable.sample_ic_verifications),
    Settings(UseSmileIDSampleTestIds.NAV_SETTINGS, "Settings", R.drawable.sample_ic_settings),
}

/**
 * A floating pill of three tabs, plus a detached token button that navigates rather than switching tab.
 *
 * [sessionProgress] drives its ring, 1f fresh to 0f expired, from the session's deadline rather than an animation.
 *
 * The pill keeps `surface` against the page's `background`. Node 5487:1351 binds those two variables the
 * other way round — page `Card BG`, pill `Main BG` — the same one-step separation inverted, and the
 * products frame cannot settle it for the two tabs it does not draw. See the plan's §3.4.
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
        // Edge to edge, so without its own inset the bar sits under the system navigation bar.
        modifier = modifier
            .fillMaxWidth()
            .windowInsetsPadding(WindowInsets.navigationBars)
            .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingSm),
        horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Surface(
            modifier = Modifier.weight(1f),
            shape = RoundedCornerShape(SmileDimens.radiusPill),
            color = UseSmileIDSampleTheme.colors.surface,
            shadowElevation = BAR_ELEVATION,
        ) {
            Row(
                modifier = Modifier.padding(horizontal = SmileDimens.spacingXs, vertical = SmileDimens.spacingXxs),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                UseSmileIDSampleNavItem.entries.forEach { item ->
                    NavBarTab(
                        item = item,
                        selected = item == selected,
                        onClick = { onSelect(item) },
                        modifier = Modifier.weight(1f),
                    )
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
    val track = smileTokenRing.copy(alpha = SMILE_TOKEN_RING_TRACK_OPACITY)
    val fill = smileTokenRing
    Box(
        // Wraps the button rather than fixing a size, so enlarged type grows it instead of clipping the label.
        modifier = Modifier.drawBehind {
            if (progress != null) {
                drawTokenRing(progress = progress, track = track, fill = fill, inflate = RING_BLEED.toPx())
            }
        },
        contentAlignment = Alignment.Center,
    ) {
        Surface(
            modifier = Modifier.defaultMinSize(minWidth = TOKEN_SIZE, minHeight = TOKEN_SIZE),
            shape = CircleShape,
            color = colors.surface,
            shadowElevation = BAR_ELEVATION,
        ) {
            Column(
                modifier = Modifier
                    .testTag(UseSmileIDSampleTestIds.NAV_TOKEN)
                    .clickable(onClick = onClick),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                UseSmileIDSampleIcon(id = R.drawable.sample_ic_token_scan, tint = colors.foreground, size = SmileDimens.sizeIconSm)
                Text(
                    text = "Token",
                    style = UseSmileIDSampleTheme.type.textStyleOverline.copy(fontSize = TOKEN_LABEL_SIZE),
                    color = colors.foreground,
                )
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
    val track = smileTokenRing.copy(alpha = SMILE_TOKEN_RING_TRACK_OPACITY)
    val fill = smileTokenRing
    Canvas(modifier = modifier) { drawTokenRing(progress = progress, track = track, fill = fill, inflate = 0f) }
}

/** [inflate] pushes the ring outside the bounds it is drawn in, so it can circle a smaller button. */
private fun DrawScope.drawTokenRing(progress: Float, track: Color, fill: Color, inflate: Float) {
    val stroke = Stroke(width = RING_THICKNESS.toPx(), cap = StrokeCap.Round)
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
private fun NavBarTab(
    item: UseSmileIDSampleNavItem,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val tint = if (selected) UseSmileIDSampleTheme.colors.primary else UseSmileIDSampleTheme.colors.foreground
    Column(
        modifier = modifier
            .testTag(item.testId)
            .selectable(selected = selected, role = Role.Tab, onClick = onClick)
            .padding(horizontal = SmileDimens.spacingXs, vertical = SmileDimens.spacingXs),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs),
    ) {
        UseSmileIDSampleIcon(id = item.icon, tint = tint, size = TAB_ICON_SIZE)
        Text(
            text = item.label,
            style = UseSmileIDSampleTheme.type.textStyleOverline,
            color = tint,
            textAlign = TextAlign.Center,
        )
    }
}

private val BAR_ELEVATION = SmileDimens.space8

private val RING_BLEED = 5.dp
private val RING_THICKNESS = 4.dp

private val TAB_ICON_SIZE = 21.dp
private val TOKEN_SIZE = 58.dp
private val TOKEN_LABEL_SIZE = 8.5.sp
private const val FULL_TURN = 360f
private const val QUARTER_TURN_UP = -90f
