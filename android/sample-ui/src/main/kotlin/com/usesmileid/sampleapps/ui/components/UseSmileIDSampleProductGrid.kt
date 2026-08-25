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
 * Two columns of product cards, an odd count leaving its last cell empty. Rows rather than a lazy
 * grid, because the host screen already scrolls; each row takes its tallest card's height.
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
                        if (index < itemCount) item(index)
                    }
                }
            }
        }
    }
}

private const val COLUMNS = 2
