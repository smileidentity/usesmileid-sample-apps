package com.usesmileid.sampleapps.ui.components

import androidx.annotation.DrawableRes
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.Dp
import com.smileid.designsystem.SmileDimens
import com.smileid.designsystem.SmileProductHue
import com.smileid.designsystem.smileProductHues
import com.usesmileid.sampleapps.ui.R
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct

/** The design set's icons, named after the ids in `spec/`. */
@Composable
fun UseSmileIDSampleIcon(
    @DrawableRes id: Int,
    tint: Color,
    modifier: Modifier = Modifier,
    size: Dp = SmileDimens.sizeIconMd,
) = Image(
    painter = painterResource(id),
    // Decorative: every caller pairs it with its own label.
    contentDescription = null,
    modifier = modifier.size(size),
    colorFilter = ColorFilter.tint(tint),
)

@Composable
fun ScanMarkGlyph(tint: Color, size: Dp = SmileDimens.sizeIconMd) =
    UseSmileIDSampleIcon(id = R.drawable.sample_ic_token_scan, tint = tint, size = size)

/** The design's own arrows, which are shorter than the hand-drawn glyphs they replace. */
@Composable
fun ArrowForwardGlyph(tint: Color, size: Dp = SmileDimens.sizeIconSm) =
    UseSmileIDSampleIcon(id = R.drawable.sample_ic_arrow_forward, tint = tint, size = size)

@Composable
fun ArrowBackGlyph(tint: Color, size: Dp = SmileDimens.sizeIconMd) =
    UseSmileIDSampleIcon(id = R.drawable.sample_ic_arrow_back, tint = tint, size = size)

/** The select trigger's chevron, which points DOWN — the list one points right. */
@Composable
fun ChevronDownGlyph(tint: Color, size: Dp = SmileDimens.sizeIconSm) =
    UseSmileIDSampleIcon(id = R.drawable.sample_ic_chevron_down, tint = tint, size = size)

internal val UseSmileIDSampleProduct.hue: SmileProductHue
    get() = requireNotNull(smileProductHues[id]) { "no hue for product '$id'; see spec/design-tokens.json → productHues" }

/** Every product has its own mark: the 2026-08-26 re-export split the two document products apart. */
@get:DrawableRes
val UseSmileIDSampleProduct.iconRes: Int?
    get() = when (this) {
        UseSmileIDSampleProduct.SmartSelfieEnrollment -> R.drawable.sample_ic_smart_selfie_enrollment
        UseSmileIDSampleProduct.SmartSelfieAuth -> R.drawable.sample_ic_smart_selfie_auth
        UseSmileIDSampleProduct.DocumentVerification -> R.drawable.sample_ic_document_verification
        // One mark for both document products, told apart by the card's hue — design/icons/README.md.
        UseSmileIDSampleProduct.EnhancedDocumentVerification -> R.drawable.sample_ic_document_verification
        UseSmileIDSampleProduct.BiometricKyc -> R.drawable.sample_ic_biometric_kyc
        UseSmileIDSampleProduct.EnhancedKyc -> R.drawable.sample_ic_enhanced_kyc
    }
