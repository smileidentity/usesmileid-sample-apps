package com.usesmileid.sampleapps.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import com.smileid.designsystem.SmileTypeStyles
import com.usesmileid.sampleapps.ui.R

/** DM Sans, bundled rather than downloaded: a provider would make text depend on Play Services and goldens on the network. */
private val DmSans = FontFamily(
    Font(R.font.dm_sans_regular, FontWeight.Normal),
    Font(R.font.dm_sans_medium, FontWeight.Medium),
    Font(R.font.dm_sans_semibold, FontWeight.SemiBold),
    Font(R.font.dm_sans_bold, FontWeight.Bold),
    Font(R.font.dm_sans_extrabold, FontWeight.ExtraBold),
)

/** Display styles name Epilogue first with DM Sans as their own declared fallback, and it is not shipped. */
internal val smileTypeStyles = SmileTypeStyles(display = DmSans, body = DmSans)

/** The ramp on all fifteen Material slots, reusing the nearest style where it has none — an unmapped slot falls back to the platform font. Styles Material cannot hold are read from [UseSmileIDSampleTheme.type]. */
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
