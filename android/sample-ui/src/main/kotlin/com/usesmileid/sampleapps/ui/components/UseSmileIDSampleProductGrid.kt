package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.smileid.designsystem.SmileDimens

/**
 * Two columns of product cards, with an empty slot where a section has an odd count.
 *
 * Built from rows rather than a lazy grid because a section is at most three cards and the screen
 * that hosts it already scrolls — nesting a lazy grid in a scroll is the shape that breaks.
 * Each row takes its tallest card's height so a two-line title next to a one-line title still
 * produces two cards of equal height.
 */
@Composable
fun UseSmileIDSampleProductGrid(
    itemCount: Int,
    modifier: Modifier = Modifier,
    item: @Composable (Int) -> Unit,
) {
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
    ) {
        for (rowStart in 0 until itemCount step COLUMNS) {
            Row(
                modifier = Modifier.fillMaxWidth().height(IntrinsicSize.Min),
                horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
            ) {
                for (column in 0 until COLUMNS) {
                    val index = rowStart + column
                    Column(modifier = Modifier.weight(1f)) {
                        if (index < itemCount) item(index) else UseSmileIDSampleProductSlot()
                    }
                }
            }
        }
    }
}

private const val COLUMNS = 2
