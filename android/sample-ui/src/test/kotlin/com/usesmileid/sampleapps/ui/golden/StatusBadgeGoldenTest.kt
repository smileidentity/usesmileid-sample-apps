package com.usesmileid.sampleapps.ui.golden

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.runtime.Composable
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatusBadge
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleStatus
import org.junit.Test

/** One pill per job status, so a status whose colour or label drifts changes a picture. */
class StatusBadgeGoldenTest : GoldenTest() {

    @Test
    fun status_badges() = goldens("status_badges") { StatusBadges() }

    @Test
    fun status_badges_max_font_scale() = assertSurvivesMaxFontScale { StatusBadges() }

    @OptIn(ExperimentalLayoutApi::class)
    @Composable
    private fun StatusBadges() = FlowRow(horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs)) {
        UseSmileIDSampleStatus.entries.forEach { UseSmileIDSampleStatusBadge(status = it) }
    }
}
