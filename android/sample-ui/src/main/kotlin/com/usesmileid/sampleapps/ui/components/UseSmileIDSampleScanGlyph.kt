package com.usesmileid.sampleapps.ui.components

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.usesmileid.sampleapps.ui.R
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The scan target: one exported asset rather than a drawn reticle, so its proportions cannot drift. */
@Composable
fun UseSmileIDSampleScanGlyph(
    modifier: Modifier = Modifier,
    size: Dp = SCAN_GLYPH_SIZE,
) = UseSmileIDSampleIcon(
    id = R.drawable.sample_ic_scan_glyph,
    tint = UseSmileIDSampleTheme.colors.textTitle,
    modifier = modifier,
    size = size,
)

private val SCAN_GLYPH_SIZE = 279.dp
