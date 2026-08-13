package com.usesmileid.sampleapps.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import com.smileid.designsystem.SmileTypeStyles
import com.usesmileid.sampleapps.ui.R

/**
 * DM Sans, bundled rather than downloaded. The token source says to ship the font, and a
 * downloadable provider resolves over the network on first use — which would make text rendering
 * depend on Play Services being present, and golden tests depend on the network.
 *
 * The five faces are exactly the weights the token ramp asks for (400/500/600/700/800).
 */
private val DmSans = FontFamily(
    Font(R.font.dm_sans_regular, FontWeight.Normal),
    Font(R.font.dm_sans_medium, FontWeight.Medium),
    Font(R.font.dm_sans_semibold, FontWeight.SemiBold),
    Font(R.font.dm_sans_bold, FontWeight.Bold),
    Font(R.font.dm_sans_extrabold, FontWeight.ExtraBold),
)

/**
 * All 29 token type styles. The display styles name Epilogue first with DM Sans as their own
 * declared fallback, and the design system deliberately does not ship Epilogue — so DM Sans is
 * what resolves, which is the token's intent rather than a substitution of ours.
 */
internal val smileTypeStyles = SmileTypeStyles(display = DmSans, body = DmSans)

/**
 * The token ramp mapped onto Material 3's fifteen slots, so every Material component inherits
 * DM Sans instead of the platform face. Material has no slot for `bodyStrong` or for any of the
 * component fonts — those are read from [UseSmileIDSampleTheme.type].
 *
 * Where the ramp has no distinct style for a slot the nearest one is reused, because an unmapped
 * slot silently falls back to the platform font.
 */
internal val typography = with(smileTypeStyles) {
    Typography(
        displayLarge = textStyleDisplayLg,
        displayMedium = textStyleDisplayMd,
        displaySmall = textStyleHeadingPage,
        headlineLarge = textStyleHeadingPage,
        headlineMedium = textStyleHeadingCard,
        headlineSmall = textStyleHeadingSection,
        titleLarge = textStyleTitle,
        titleMedium = textStyleSubtitle,
        titleSmall = textStyleSubtitle,
        bodyLarge = textStyleBody,
        bodyMedium = textStyleBodySm,
        bodySmall = textStyleCaption,
        labelLarge = textStyleButton,
        labelMedium = textStyleButtonSm,
        labelSmall = textStyleOverline,
    )
}
