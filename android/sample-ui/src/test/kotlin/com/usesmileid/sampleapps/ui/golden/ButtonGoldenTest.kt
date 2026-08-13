package com.usesmileid.sampleapps.ui.golden

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.runtime.Composable
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleButton
import org.junit.Test

/**
 * The U1 primitive the composites reuse most, covered here so the harness is proven against
 * something already device-verified rather than only against new code. The loading state is left to
 * the gallery and the device pass: its progress indicator animates, and frame zero of an animation
 * is a golden that changes for reasons unrelated to this app.
 *
 * The dark golden shows the disabled button as a near-white slab. That is the recorded
 * `buttonDisabledBypassesSemanticTier` defect in the token source, not something to patch here.
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
