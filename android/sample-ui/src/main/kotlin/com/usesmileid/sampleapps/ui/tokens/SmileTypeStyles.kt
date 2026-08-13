@file:Suppress("MagicNumber")
// Smile ID Design System — GENERATED. Do not edit by hand.
//
// Regenerate with: scripts/sync_design_tokens.py --all
// Source: the design system's dist/json/tokens.flat.json (fully resolved light + dark).
//
// The upstream Compose emitter writes these styles as COMMENTS ONLY, so MaterialTheme.typography
// would otherwise be stock. Naming mirrors the Dart emitter's SmileType so the two are diffable.
// Delete this file once upstream emits real TextStyles; see spec/design-tokens.json -> deltas.

package com.smileid.designsystem

import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

/** The token source's type ramp, bound to the font families the app supplies. */
class SmileTypeStyles(display: FontFamily, body: FontFamily) {
    val textStyleDisplayLg = TextStyle(
        fontFamily = display,
        fontWeight = FontWeight(800),
        fontSize = 40.sp,
        lineHeight = 48.sp,
        letterSpacing = (-0.4).sp,
    )
    val textStyleDisplayMd = TextStyle(
        fontFamily = display,
        fontWeight = FontWeight(800),
        fontSize = 32.sp,
        lineHeight = 40.sp,
        letterSpacing = (-0.4).sp,
    )
    val textStyleHeadingPage = TextStyle(
        fontFamily = display,
        fontWeight = FontWeight(800),
        fontSize = 24.sp,
        lineHeight = 32.sp,
        letterSpacing = (-0.4).sp,
    )
    val textStyleHeadingCard = TextStyle(
        fontFamily = display,
        fontWeight = FontWeight(800),
        fontSize = 20.sp,
        lineHeight = 26.sp,
        letterSpacing = (-0.4).sp,
    )
    val textStyleHeadingSection = TextStyle(
        fontFamily = display,
        fontWeight = FontWeight(600),
        fontSize = 18.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.sp,
    )
    val textStyleTitle = TextStyle(
        fontFamily = body,
        fontWeight = FontWeight(700),
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.sp,
    )
    val textStyleSubtitle = TextStyle(
        fontFamily = body,
        fontWeight = FontWeight(500),
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.sp,
    )
    val textStyleBody = TextStyle(
        fontFamily = body,
        fontWeight = FontWeight(400),
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.sp,
    )
    val textStyleBodyStrong = TextStyle(
        fontFamily = body,
        fontWeight = FontWeight(600),
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.sp,
    )
    val textStyleBodySm = TextStyle(
        fontFamily = body,
        fontWeight = FontWeight(400),
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.sp,
    )
    val textStyleCaption = TextStyle(
        fontFamily = body,
        fontWeight = FontWeight(500),
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.sp,
    )
    val textStyleOverline = TextStyle(
        fontFamily = body,
        fontWeight = FontWeight(700),
        fontSize = 10.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.sp,
    )
    val textStyleButton = TextStyle(
        fontFamily = body,
        fontWeight = FontWeight(700),
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.sp,
    )
    val textStyleButtonSm = TextStyle(
        fontFamily = body,
        fontWeight = FontWeight(700),
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.sp,
    )
    val avatarFont = TextStyle(
        fontFamily = body,
        fontWeight = FontWeight(500),
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.sp,
    )
    val badgeFont = TextStyle(
        fontFamily = body,
        fontWeight = FontWeight(700),
        fontSize = 10.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.sp,
    )
    val bannerTitleFont = TextStyle(
        fontFamily = body,
        fontWeight = FontWeight(600),
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.sp,
    )
    val bannerTextFont = TextStyle(
        fontFamily = body,
        fontWeight = FontWeight(400),
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.sp,
    )
    val buttonFont = TextStyle(
        fontFamily = body,
        fontWeight = FontWeight(700),
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.sp,
    )
    val cardTitleFont = TextStyle(
        fontFamily = display,
        fontWeight = FontWeight(800),
        fontSize = 20.sp,
        lineHeight = 26.sp,
        letterSpacing = (-0.4).sp,
    )
    val dataFieldLabelFont = TextStyle(
        fontFamily = body,
        fontWeight = FontWeight(500),
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.sp,
    )
    val dataFieldValueFont = TextStyle(
        fontFamily = body,
        fontWeight = FontWeight(400),
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.sp,
    )
    val filterChipFont = TextStyle(
        fontFamily = body,
        fontWeight = FontWeight(400),
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.sp,
    )
    val inputFont = TextStyle(
        fontFamily = body,
        fontWeight = FontWeight(400),
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.sp,
    )
    val linkFont = TextStyle(
        fontFamily = body,
        fontWeight = FontWeight(400),
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.sp,
    )
    val searchFont = TextStyle(
        fontFamily = body,
        fontWeight = FontWeight(400),
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.sp,
    )
    val tableHeaderFont = TextStyle(
        fontFamily = body,
        fontWeight = FontWeight(700),
        fontSize = 10.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.sp,
    )
    val tableCellFont = TextStyle(
        fontFamily = body,
        fontWeight = FontWeight(400),
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.sp,
    )
    val tabFont = TextStyle(
        fontFamily = body,
        fontWeight = FontWeight(500),
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.sp,
    )
}
