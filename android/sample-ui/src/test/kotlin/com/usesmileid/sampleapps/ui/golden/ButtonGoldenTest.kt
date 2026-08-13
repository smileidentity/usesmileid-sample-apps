package com.usesmileid.sampleapps.ui.golden

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.runtime.Composable
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleButton
import org.junit.Test

/**
 * Proves the harness against an already device-verified primitive. Loading is left out: frame zero of an animation is a fragile golden.
 *
 * The near-white disabled slab in dark is the recorded `buttonDisabledBypassesSemanticTier` defect, not something to patch here.
 */
class ButtonGoldenTest : GoldenTest() {

    @Test
    fun button_states() = goldens("button_states") { ButtonStates() }

    @Test
    fun button_survives_max_font_scale() = assertSurvivesMaxFontScale { ButtonStates(loading = true) }
}

@Composable
private fun ButtonStates(loading: Boolean = false) {
    Column(verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs)) {
        UseSmileIDSampleButton(text = "Continue", onClick = {})
        UseSmileIDSampleButton(text = "Continue", onClick = {}, enabled = false)
        if (loading) UseSmileIDSampleButton(text = "Continue", onClick = {}, loading = true)
        UseSmileIDSampleButton(text = "SmartSelfie Authentication", onClick = {})
    }
}
