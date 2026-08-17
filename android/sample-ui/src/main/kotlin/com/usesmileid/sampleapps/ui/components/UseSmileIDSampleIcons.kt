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

/** Both document products share one mark by design; the card's hue is what tells them apart. */
@get:DrawableRes
val UseSmileIDSampleProduct.iconRes: Int?
    get() = when (this) {
        UseSmileIDSampleProduct.SmartSelfieEnrollment -> R.drawable.sample_ic_smart_selfie_enrollment
        UseSmileIDSampleProduct.SmartSelfieAuth -> R.drawable.sample_ic_smart_selfie_auth
        UseSmileIDSampleProduct.DocumentVerification -> R.drawable.sample_ic_document_verification
        UseSmileIDSampleProduct.EnhancedDocumentVerification -> R.drawable.sample_ic_document_verification
        UseSmileIDSampleProduct.BiometricKyc -> R.drawable.sample_ic_biometric_kyc
        UseSmileIDSampleProduct.EnhancedKyc -> null
    }
