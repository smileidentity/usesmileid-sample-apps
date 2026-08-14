// Smile ID product hues — GENERATED. Do not edit by hand.
//
// Regenerate with: scripts/sync_design_tokens.py --all
//
// A stopgap, and not from the design system: these live only in the design file, bound to no
// variable, so there is no upstream output to read. The source is spec/design-tokens.json →
// productHues. Delete this file once the design system carries a decorative product role, and
// never hand-copy these values into another codebase — a port generates from the same spec entry.

package com.smileid.designsystem

import androidx.compose.ui.graphics.Color

/** One product card's colouring. `scrim` is applied at 16%: the go pill and the ghost glyph. */
data class SmileProductHue(
    val from: Color,
    val to: Color,
    val icon: Color,
    val scrim: Color,
)

/** Keyed by the product id in spec/scenarios.json. A product absent here has no hue yet. */
val smileProductHues: Map<String, SmileProductHue> = mapOf(
    "smartSelfieEnrollment" to SmileProductHue(
        from = Color(0xFF05723A),
        to = Color(0xFF0A9B4C),
        icon = Color(0xFF05723A),
        scrim = Color(0xFFFFFFFF),
    ),
    "smartSelfieAuth" to SmileProductHue(
        from = Color(0xFF3A49B4),
        to = Color(0xFF5361D6),
        icon = Color(0xFF3A49B4),
        scrim = Color(0xFFFFFFFF),
    ),
    "documentVerification" to SmileProductHue(
        from = Color(0xFFE08600),
        to = Color(0xFFFFB53D),
        icon = Color(0xFFC46F00),
        scrim = Color(0xFF2D2B2A),
    ),
    "enhancedDocumentVerification" to SmileProductHue(
        from = Color(0xFF2D2B2A),
        to = Color(0xFF4A4645),
        icon = Color(0xFF2D2B2A),
        scrim = Color(0xFFFFFFFF),
    ),
    "biometricKyc" to SmileProductHue(
        from = Color(0xFF151F72),
        to = Color(0xFF2B3A9E),
        icon = Color(0xFF151F72),
        scrim = Color(0xFFFFFFFF),
    ),
    "enhancedKyc" to SmileProductHue(
        from = Color(0xFF05726E),
        to = Color(0xFF0A9B96),
        icon = Color(0xFF05726E),
        scrim = Color(0xFFFFFFFF),
    ),
)
