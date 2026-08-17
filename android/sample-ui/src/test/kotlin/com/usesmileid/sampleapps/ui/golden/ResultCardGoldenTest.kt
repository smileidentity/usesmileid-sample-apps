package com.usesmileid.sampleapps.ui.golden

import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleResultCard
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleResultLine
import org.junit.Test

class ResultCardGoldenTest : GoldenTest() {

    @Test
    fun result_card_idle() = goldens("result_card_idle") { UseSmileIDSampleResultCard(ResultFixtures.Idle) }

    @Test
    fun result_card_succeeded() =
        goldens("result_card_succeeded") { UseSmileIDSampleResultCard(ResultFixtures.Succeeded) }

    @Test
    fun result_card_cancelled() =
        goldens("result_card_cancelled") { UseSmileIDSampleResultCard(ResultFixtures.Cancelled) }

    @Test
    fun result_card_failed() = goldens("result_card_failed") { UseSmileIDSampleResultCard(ResultFixtures.Failed) }

    @Test
    fun result_card_max_font_scale() =
        assertSurvivesMaxFontScale { UseSmileIDSampleResultCard(ResultFixtures.Failed) }

    @Test
    fun result_line_running() = goldens("result_line_running") { UseSmileIDSampleResultLine(ResultFixtures.Running) }

    @Test
    fun result_line_max_font_scale() =
        assertSurvivesMaxFontScale { UseSmileIDSampleResultLine(ResultFixtures.Running) }
}
