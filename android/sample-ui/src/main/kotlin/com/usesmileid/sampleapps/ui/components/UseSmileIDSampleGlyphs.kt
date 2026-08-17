package com.usesmileid.sampleapps.ui.components

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.R

/**
 * The icons the design set does not supply, taken from Material Symbols Outlined 400 rather than
 * drawn by hand: a `Canvas` approximation drifts from the real glyph and cannot be reviewed.
 *
 * The design's own exports live in [UseSmileIDSampleIcons] and are not interchangeable with these —
 * they are stroke-based, so mixing the two families in one row reads as a mistake.
 */
@Composable
fun ChevronRightGlyph(tint: Color, size: Dp = SmileDimens.sizeIconMd) =
    UseSmileIDSampleIcon(id = R.drawable.sample_ic_chevron_right, tint = tint, size = size)

@Composable
fun CheckGlyph(tint: Color, size: Dp = SmileDimens.sizeIconMd) =
    UseSmileIDSampleIcon(id = R.drawable.sample_ic_check, tint = tint, size = size)

@Composable
fun TrashGlyph(tint: Color, size: Dp = SmileDimens.sizeIconMd) =
    UseSmileIDSampleIcon(id = R.drawable.sample_ic_trash, tint = tint, size = size)

@Composable
fun TorchGlyph(tint: Color, size: Dp = SmileDimens.sizeIconMd) =
    UseSmileIDSampleIcon(id = R.drawable.sample_ic_torch, tint = tint, size = size)

@Composable
fun CopyGlyph(tint: Color, size: Dp = SmileDimens.sizeIconSm) =
    UseSmileIDSampleIcon(id = R.drawable.sample_ic_copy, tint = tint, size = size)

@Composable
fun PlusGlyph(tint: Color, size: Dp = SmileDimens.sizeIconMd) =
    UseSmileIDSampleIcon(id = R.drawable.sample_ic_plus, tint = tint, size = size)

/** Stand-in: Enhanced KYC has no icon of its own yet. */
@Composable
fun ProductMarkGlyph(tint: Color, size: Dp = SmileDimens.sizeIconMd) =
    UseSmileIDSampleIcon(id = R.drawable.sample_ic_product_mark, tint = tint, size = size)
