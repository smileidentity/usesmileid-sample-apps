// Smile ID product hues — GENERATED. Do not edit by hand.
// Regenerate with: scripts/sync_design_tokens.py --all
//
// A stopgap: the source is spec/design-tokens.json → productHues, not the design system. Delete this
// file once the design system carries a decorative product role; a port generates from the same entry.

package com.smileid.designsystem

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** One product's colouring. `cardIcon` tints the card's glyph; `icon` and `tile` are the list row's pair, which the products frame does not govern. */
data class SmileProductHue(
    val from: Color,
    val to: Color,
    val cardIcon: Color,
    val icon: Color,
    val tile: Color,
    /** Stop positions as fractions. `stopEnd` may exceed 1: the design runs it past the card's edge. */
    val stopStart: Float,
    val stopEnd: Float,
    val fromAlpha: Float,
    val toAlpha: Float,
)

/** Keyed by the product id in spec/scenarios.json. A product absent here has no hue yet. */
val smileProductHues: Map<String, SmileProductHue> = mapOf(
    "smartSelfieEnrollment" to SmileProductHue(
        from = Color(0xFFFFB53D),
        to = Color(0xFFA78BFA),
        cardIcon = Color(0xFF05723A),
        icon = Color(0xFF05723A),
        tile = Color(0xFFE4F2EA),
        stopStart = 0.66627f,
        stopEnd = 1.2978f,
        fromAlpha = 1.0f,
        toAlpha = 0.79f,
    ),
    "smartSelfieAuth" to SmileProductHue(
        from = Color(0xFF3A49B4),
        to = Color(0xFF5361D6),
        cardIcon = Color(0xFF3A49B4),
        icon = Color(0xFF3A49B4),
        tile = Color(0xFFE9EBFA),
        stopStart = 0.06451f,
        stopEnd = 0.91913f,
        fromAlpha = 1.0f,
        toAlpha = 1.0f,
    ),
    "documentVerification" to SmileProductHue(
        from = Color(0xFF2CC05C),
        to = Color(0xFF00AA99),
        cardIcon = Color(0xFF06A850),
        icon = Color(0xFFC46F00),
        tile = Color(0xFFFBEEDA),
        stopStart = 0.66627f,
        stopEnd = 1.2978f,
        fromAlpha = 1.0f,
        toAlpha = 0.79f,
    ),
    "enhancedDocumentVerification" to SmileProductHue(
        from = Color(0xFF04713A),
        to = Color(0xFF00AA99),
        cardIcon = Color(0xFF04713A),
        icon = Color(0xFF2D2B2A),
        tile = Color(0xFFEDEBEA),
        stopStart = 0.66627f,
        stopEnd = 1.2978f,
        fromAlpha = 1.0f,
        toAlpha = 0.79f,
    ),
    "biometricKyc" to SmileProductHue(
        from = Color(0xFF151F72),
        to = Color(0xFF2B3A9E),
        cardIcon = Color(0xFF151F72),
        icon = Color(0xFF151F72),
        tile = Color(0xFFE5EDFF),
        stopStart = 0.56022f,
        stopEnd = 1.1051f,
        fromAlpha = 1.0f,
        toAlpha = 1.0f,
    ),
    "enhancedKyc" to SmileProductHue(
        from = Color(0xFF0EA5E9),
        to = Color(0xFF151F72),
        cardIcon = Color(0xFF0EA5E9),
        icon = Color(0xFF05726E),
        tile = Color(0xFFE4F1F0),
        stopStart = 0.66627f,
        stopEnd = 1.2978f,
        fromAlpha = 0.79f,
        toAlpha = 1.0f,
    ),
)

/** One status pill's soft fill: a pale background with text that clears contrast on it. */
data class SmileSoftBadgeFill(
    val background: Color,
    val text: Color,
)

/** Keyed by feedback role. The design system's own badge.* pairs are saturated, which is a different treatment. */
val smileSoftBadgeFills: Map<String, SmileSoftBadgeFill> = mapOf(
    "success" to SmileSoftBadgeFill(
        background = Color(0xFFDBF5E4),
        text = Color(0xFF04713A),
    ),
    "info" to SmileSoftBadgeFill(
        background = Color(0xFFE5EDFF),
        text = Color(0xFF151F72),
    ),
    "warning" to SmileSoftBadgeFill(
        background = Color(0xFFFFF0D9),
        text = Color(0xFF7A4A00),
    ),
    "error" to SmileSoftBadgeFill(
        background = Color(0xFFFDE4E1),
        text = Color(0xFFA11209),
    ),
)

/** The design's `color/border-strong`, for a control ring that `color.border` is too pale to draw. */
val smileBorderStrong: Color = Color(0xFFC2C5CB)

/** The design's `color/surface-2`, a cool grey subtle fill — `color.surface-alt` is a warm cream. */
val smileSurface2: Color = Color(0xFFEAECF0)

/** The design's `Off_black`: the warm strong foreground. Seven roles, one variable — see the `offBlack` delta. */
val smileOffBlackLight: Color = Color(0xFF2D2B2A)
val smileOffBlackDark: Color = Color(0xFFF9F0E7)

/** Avatar fills, one per profile, taken in list order and cycled beyond the list. */
val smileProfileHues: List<Color> = listOf(
    Color(0xFF151F72),
    Color(0xFF05723A),
    Color(0xFFB36500),
    Color(0xFF2D2B2A),
)

/** The session card's horizontal gradient. Both stops are translucent, so the card composites against the page. */
val smileTokenSessionGradient: List<Color> = listOf(Color(0xFF0C41B2), Color(0xFFA78BFA))
val smileTokenSessionGradientAlpha: List<Float> = listOf(0.78f, 0.79f)

/** The countdown ring: this colour solid for progress, and the same colour faded for the track. */
val smileTokenRing: Color = Color(0xFF06A850)
const val SMILE_TOKEN_RING_TRACK_OPACITY = 0.18f
/** The design's Type/Label: a point larger than text-style.overline, and spaced. */
val smileLabelSize = 11.sp
val smileLabelTracking = 0.88.sp
/** The card's two label runs and its stroke, each one property off a token — see the `cardLabelRuns` delta. */
val smileCardTitleTracking = -0.4.sp
const val SMILE_CARD_FAMILY_WEIGHT = 400
val smileCardStroke = 0.2.dp
