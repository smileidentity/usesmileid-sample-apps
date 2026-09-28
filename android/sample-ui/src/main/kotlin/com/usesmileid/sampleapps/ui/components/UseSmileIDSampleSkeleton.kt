package com.usesmileid.sampleapps.ui.components

import android.os.SystemClock
import android.provider.Settings
import androidx.compose.animation.animateColor
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.smileid.designsystem.SmileDimens
import com.smileid.designsystem.SmileMotion
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/** Skeleton rows show only after [DELAY_MILLIS], so a fast answer never flashes, then for at least [MIN_SHOWN_MILLIS]. */
class UseSmileIDSampleSkeletonGate(private val scope: CoroutineScope, private val now: () -> Long) {
    var visible by mutableStateOf(false)
        private set

    private var shownAt = 0L
    private var pending: Job? = null

    fun loading(isLoading: Boolean) {
        pending?.cancel()
        pending = scope.launch {
            if (isLoading) {
                if (visible) return@launch
                delay(DELAY_MILLIS)
                shownAt = now()
                visible = true
            } else if (visible) {
                delay((MIN_SHOWN_MILLIS - (now() - shownAt)).coerceAtLeast(0))
                visible = false
            }
        }
    }

    companion object {
        const val DELAY_MILLIS = 300L
        const val MIN_SHOWN_MILLIS = 400L
    }
}

/** The gate for one list; true while its skeleton rows should draw in place of the list. */
@Composable
fun rememberUseSmileIDSampleSkeletonVisible(loading: Boolean): Boolean {
    val scope = rememberCoroutineScope()
    val gate = remember { UseSmileIDSampleSkeletonGate(scope, SystemClock::uptimeMillis) }
    LaunchedEffect(loading) { gate.loading(loading) }
    return gate.visible
}

/** Six OptionRow-shaped placeholders; one element to accessibility, announcing [announcement]. */
@Composable
fun UseSmileIDSampleSkeletonRows(
    announcement: String,
    modifier: Modifier = Modifier,
    leadingCircle: Boolean = false,
    testId: String? = null,
) {
    val colors = UseSmileIDSampleTheme.colors
    val fill = if (reducedMotion()) {
        colors.skeleton
    } else {
        val pulse = rememberInfiniteTransition(label = "skeleton")
        val color by pulse.animateColor(
            initialValue = colors.skeleton,
            targetValue = colors.skeletonHighlight,
            animationSpec = infiniteRepeatable(
                animation = tween(SmileMotion.skeletonDuration.inWholeMilliseconds.toInt()),
                repeatMode = RepeatMode.Reverse,
            ),
            label = "skeletonFill",
        )
        color
    }
    Column(
        modifier = modifier
            .fillMaxWidth()
            .tagged(testId)
            .clearAndSetSemantics { contentDescription = announcement },
        verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs),
    ) {
        SKELETON_WIDTHS.forEach { width -> SkeletonRow(width = width, fill = fill, leadingCircle = leadingCircle) }
    }
}

@Composable
private fun SkeletonRow(width: Float, fill: Color, leadingCircle: Boolean) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(SmileDimens.sizeControlMd)
            .padding(horizontal = SmileDimens.spacingSm),
        horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (leadingCircle) Box(Modifier.size(FLAG_CIRCLE).background(fill, CircleShape))
        Box(
            Modifier
                .fillMaxWidth(width)
                .height(LABEL_BAR)
                .background(fill, RoundedCornerShape(SmileDimens.radiusField)),
        )
    }
}

/** The system's "remove animations" switch, which is Android's reduced-motion signal. */
@Composable
private fun reducedMotion(): Boolean {
    val resolver = LocalContext.current.contentResolver
    return remember(resolver) {
        Settings.Global.getFloat(resolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f
    }
}

/** Six widths so the rows do not read as a table. */
private val SKELETON_WIDTHS = listOf(0.72f, 0.48f, 0.64f, 0.56f, 0.80f, 0.40f)
private val FLAG_CIRCLE = 19.dp
private val LABEL_BAR = 12.dp
