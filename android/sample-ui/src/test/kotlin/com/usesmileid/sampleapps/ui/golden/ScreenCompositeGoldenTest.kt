package com.usesmileid.sampleapps.ui.golden

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleFloatingTokenButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleJobRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleNavBar
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleNavItem
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleProductCard
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleProductGrid
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleProfileEnvChip
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleScanGlyph
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleScanSheet
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionHeader
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSessionCard
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSessionEndedBanner
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSwipeAction
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTokenRing
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import org.junit.Test

/** Hues come from the token palette in order, not a guessed product mapping: that list is still outstanding. */
class ScreenCompositeGoldenTest : GoldenTest() {

    @Test
    fun product_card() = goldens("product_card") { ProductCards() }

    @Test
    fun product_card_max_font_scale() = assertSurvivesMaxFontScale { ProductCards() }

    @Test
    fun product_grid() = goldens("product_grid") { ProductGrid() }

    @Test
    fun product_grid_max_font_scale() = assertSurvivesMaxFontScale { ProductGrid() }

    @Test
    fun section_header() = goldens("section_header") { SectionHeaders() }

    @Test
    fun section_header_max_font_scale() = assertSurvivesMaxFontScale { SectionHeaders() }

    @Test
    fun profile_env_chip() = goldens("profile_env_chip") { EnvChips() }

    @Test
    fun profile_env_chip_max_font_scale() = assertSurvivesMaxFontScale { EnvChips() }

    @Test
    fun nav_bar() = goldens("nav_bar") { NavBars() }

    @Test
    fun nav_bar_max_font_scale() = assertSurvivesMaxFontScale { NavBars() }

    @Test
    fun token_ring() = goldens("token_ring") { TokenRings() }

    @Test
    fun session_card() = goldens("session_card") { SessionCards() }

    @Test
    fun session_card_max_font_scale() = assertSurvivesMaxFontScale { SessionCards() }

    @Test
    fun session_ended_banner() = goldens("session_ended_banner") { SessionEndedBanners() }

    @Test
    fun session_ended_banner_max_font_scale() = assertSurvivesMaxFontScale { SessionEndedBanners() }

    @Test
    fun floating_token_button() = goldens("floating_token_button") { FloatingTokenButtons() }

    @Test
    fun scan_glyph() = goldens("scan_glyph") { ScanGlyphs() }

    @Test
    fun scan_sheet() = goldens("scan_sheet") { ScanSheets() }

    @Test
    fun scan_sheet_max_font_scale() = assertSurvivesMaxFontScale { ScanSheets() }

    @Test
    fun swipe_action() = goldens("swipe_action") { SwipeActions() }

    @Test
    fun swipe_action_max_font_scale() = assertSurvivesMaxFontScale { SwipeActions() }
}

private val stack: Arrangement.Vertical = Arrangement.spacedBy(SmileDimens.spacingXs)

@Composable
private fun ProductCards() = Column(verticalArrangement = stack) {
    UseSmileIDSampleProductCard(
        title = "SmartSelfie Enrollment",
        onClick = {},
        containerColor = UseSmileIDSampleTheme.colors.decorative.darkGreen,
    )
    UseSmileIDSampleProductCard(
        title = "SmartSelfie Authentication",
        onClick = {},
        containerColor = UseSmileIDSampleTheme.colors.decorative.sky,
    )
    UseSmileIDSampleProductCard(
        title = "Enhanced KYC",
        onClick = {},
        containerColor = UseSmileIDSampleTheme.colors.decorative.orange,
        enabled = false,
    )
}

@Composable
private fun ProductGrid() {
    val hues = UseSmileIDSampleTheme.colors.decorative.all
    val titles = listOf(
        "SmartSelfie Enrollment",
        "SmartSelfie Authentication",
        "Document Verification",
        "Enhanced Document Verification",
        "Biometric KYC",
    )
    UseSmileIDSampleProductGrid(itemCount = titles.size) { index ->
        UseSmileIDSampleProductCard(
            title = titles[index],
            onClick = {},
            containerColor = hues[index % hues.size],
        )
    }
}

@Composable
private fun SectionHeaders() = Column(verticalArrangement = stack) {
    UseSmileIDSampleSectionHeader(text = "Authentication")
    UseSmileIDSampleSectionHeader(text = "Verifications")
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun EnvChips() = FlowRow(horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs)) {
    UseSmileIDSampleProfileEnvChip(environment = UseSmileIDSampleEnvironment.Sandbox)
    UseSmileIDSampleProfileEnvChip(environment = UseSmileIDSampleEnvironment.Production)
}

@Composable
private fun NavBars() = Column(verticalArrangement = stack) {
    UseSmileIDSampleNavBar(
        selected = UseSmileIDSampleNavItem.Products,
        onSelect = {},
        onTokenClick = {},
    )
    UseSmileIDSampleNavBar(
        selected = UseSmileIDSampleNavItem.Verifications,
        onSelect = {},
        onTokenClick = {},
        sessionProgress = 0.65f,
    )
}

@Composable
private fun TokenRings() = Row(
    horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
    verticalAlignment = Alignment.CenterVertically,
) {
    listOf(1f, 0.65f, 0.15f, 0f).forEach { progress ->
        Box(modifier = Modifier.size(SmileDimens.space64)) {
            UseSmileIDSampleTokenRing(progress = progress, modifier = Modifier.size(SmileDimens.space64))
        }
    }
}

@Composable
private fun SessionCards() = Column(verticalArrangement = stack) {
    UseSmileIDSampleSessionCard(sessionId = "9f3a", remaining = "3:20")
    UseSmileIDSampleSessionCard(sessionId = "9f3a", remaining = "0:09")
}

@Composable
private fun SessionEndedBanners() = UseSmileIDSampleSessionEndedBanner(onScan = {})

@Composable
private fun FloatingTokenButtons() = UseSmileIDSampleFloatingTokenButton(onClick = {})

@Composable
private fun ScanGlyphs() = Column(verticalArrangement = stack) {
    UseSmileIDSampleScanGlyph()
    UseSmileIDSampleScanGlyph(sweep = true)
}

@Composable
private fun ScanSheets() = UseSmileIDSampleScanSheet(onPaste = {}, onSimulate = {})

@Composable
private fun SwipeActions() = UseSmileIDSampleSwipeAction(onRemove = {}) {
    UseSmileIDSampleJobRow(
        product = "SmartSelfie Enrollment",
        jobId = "7d2f01aa…",
        time = "13:03:41",
        status = UseSmileIDSampleStatus.Clear,
    )
}
