// Smile ID product hues — GENERATED. Do not edit by hand.
// Regenerate with: scripts/sync_design_tokens.py --all
//
// A stopgap: the source is spec/design-tokens.json → productHues, not the design system. Delete this
// file once the design system carries a decorative product role; a port generates from the same entry.

package com.smileid.designsystem

import androidx.compose.ui.graphics.Color

/** One product card's colouring. `scrim` is applied at 16%: the go pill and the ghost glyph. `tile` is the soft icon-tile fill a list row uses. */
data class SmileProductHue(
    val from: Color,
    val to: Color,
    val icon: Color,
    val scrim: Color,
    val tile: Color,
)

/** Keyed by the product id in spec/scenarios.json. A product absent here has no hue yet. */
val smileProductHues: Map<String, SmileProductHue> = mapOf(
    "smartSelfieEnrollment" to SmileProductHue(
        from = Color(0xFF05723A),
        to = Color(0xFF0A9B4C),
        icon = Color(0xFF05723A),
        scrim = Color(0xFFFFFFFF),
        tile = Color(0xFFE4F2EA),
    ),
    "smartSelfieAuth" to SmileProductHue(
        from = Color(0xFF3A49B4),
        to = Color(0xFF5361D6),
        icon = Color(0xFF3A49B4),
        scrim = Color(0xFFFFFFFF),
        tile = Color(0xFFE9EBFA),
    ),
    "documentVerification" to SmileProductHue(
        from = Color(0xFFE08600),
        to = Color(0xFFFFB53D),
        icon = Color(0xFFC46F00),
        scrim = Color(0xFF2D2B2A),
        tile = Color(0xFFFBEEDA),
    ),
    "enhancedDocumentVerification" to SmileProductHue(
        from = Color(0xFF2D2B2A),
        to = Color(0xFF4A4645),
        icon = Color(0xFF2D2B2A),
        scrim = Color(0xFFFFFFFF),
        tile = Color(0xFFEDEBEA),
    ),
    "biometricKyc" to SmileProductHue(
        from = Color(0xFF151F72),
        to = Color(0xFF2B3A9E),
        icon = Color(0xFF151F72),
        scrim = Color(0xFFFFFFFF),
        tile = Color(0xFFE5EDFF),
    ),
    "enhancedKyc" to SmileProductHue(
        from = Color(0xFF05726E),
        to = Color(0xFF0A9B96),
        icon = Color(0xFF05726E),
        scrim = Color(0xFFFFFFFF),
        tile = Color(0xFFE4F1F0),
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
