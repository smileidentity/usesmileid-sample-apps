package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * Wraps a row in the platform swipe gesture, revealing Remove behind it.
 *
 * The design only fixes the revealed treatment, so the gesture itself is Material's: velocity,
 * threshold and the settle animation stay the ones the platform ships, which is what keeps this
 * feeling native rather than reproducing Android's swipe on iOS or the reverse.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun UseSmileIDSampleSwipeAction(
    onRemove: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    val state = rememberSwipeToDismissBoxState()

    // Reads the settled value rather than firing from a composition, so a recomposition mid-gesture
    // cannot remove the row twice.
    LaunchedEffect(state) {
        snapshotFlow { state.currentValue }
            .collect { if (it == SwipeToDismissBoxValue.EndToStart) onRemove() }
    }

    SwipeToDismissBox(
        state = state,
        modifier = modifier.fillMaxWidth(),
        enableDismissFromStartToEnd = false,
        backgroundContent = { RemoveBackdrop() },
        content = { content() },
    )
}

@Composable
private fun RemoveBackdrop() {
    val colors = UseSmileIDSampleTheme.colors
    Box(
        modifier = Modifier.fillMaxWidth().fillMaxHeight(),
        contentAlignment = Alignment.CenterEnd,
    ) {
        Column(
            modifier = Modifier
                .width(REVEAL_WIDTH)
                .padding(horizontal = SmileDimens.spacingXs),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs),
        ) {
            Box(modifier = Modifier.size(SmileDimens.sizeIconMd), contentAlignment = Alignment.Center) {
                TrashGlyph(tint = colors.errorFill)
            }
            Text(
                text = "Remove",
                style = UseSmileIDSampleTheme.type.textStyleCaption,
                color = colors.errorFill,
            )
        }
    }
}

/** 80 in the design; space64 plus a gap is the nearest the scale reaches. */
private val REVEAL_WIDTH = SmileDimens.space64 + SmileDimens.spacingMd
