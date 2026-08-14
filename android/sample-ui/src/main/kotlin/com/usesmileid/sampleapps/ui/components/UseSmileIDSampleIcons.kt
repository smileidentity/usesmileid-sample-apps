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
import com.usesmileid.sampleapps.ui.R
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct

/**
 * The design set's own icons, imported from its SVG export as vector drawables.
 *
 * They keep the same `(tint, size)` shape as the hand-drawn glyphs in `UseSmileIDSampleGlyphs.kt`,
 * so a call site swaps one for the other without changing. The drawables carry an opaque base colour
 * because the format demands one; no screen ever sees it, because every path here tints.
 *
 * Names are derived from the ids `spec/` already uses — a product's drawable is its
 * [UseSmileIDSampleProduct.id] in resource casing — so the mapping is mechanical rather than a
 * lookup table someone has to maintain.
 */
@Composable
fun UseSmileIDSampleIcon(
    @DrawableRes id: Int,
    tint: Color,
    modifier: Modifier = Modifier,
    size: Dp = SmileDimens.sizeIconMd,
) = Image(
    painter = painterResource(id),
    // Decorative: every caller pairs it with its own label or content description.
    contentDescription = null,
    modifier = modifier.size(size),
    colorFilter = ColorFilter.tint(tint),
)

/** The scan mark, on the nav token button, the floating token button and the scan sheet. */
@Composable
fun ScanMarkGlyph(tint: Color, size: Dp = SmileDimens.sizeIconMd) =
    UseSmileIDSampleIcon(id = R.drawable.sample_ic_token_scan, tint = tint, size = size)

/**
 * The icon the design set supplies for a product, or null where it still owes one.
 *
 * Enhanced Doc Verification and Enhanced KYC are the two gaps; a null here is what makes the card
 * fall back to the shared product mark rather than borrowing a neighbour's icon, which would read as
 * a deliberate pairing.
 */
@get:DrawableRes
val UseSmileIDSampleProduct.iconRes: Int?
    get() = when (this) {
        UseSmileIDSampleProduct.SmartSelfieEnrollment -> R.drawable.sample_ic_smart_selfie_enrollment
        UseSmileIDSampleProduct.SmartSelfieAuth -> R.drawable.sample_ic_smart_selfie_auth
        UseSmileIDSampleProduct.DocumentVerification -> R.drawable.sample_ic_document_verification
        UseSmileIDSampleProduct.BiometricKyc -> R.drawable.sample_ic_biometric_kyc
        UseSmileIDSampleProduct.EnhancedDocumentVerification -> null
        UseSmileIDSampleProduct.EnhancedKyc -> null
    }
