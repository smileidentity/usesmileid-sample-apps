package com.usesmileid.sampleapps.ui.golden

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.runtime.Composable
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.R
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleIcon
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import org.junit.Test

class IconGoldenTest : GoldenTest() {

    @Test
    fun icons() = goldens("icons") { IconSheet() }

    @OptIn(ExperimentalLayoutApi::class)
    @Composable
    private fun IconSheet() {
        FlowRow(horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingMd)) {
            ICONS.forEach { id ->
                UseSmileIDSampleIcon(
                    id = id,
                    tint = UseSmileIDSampleTheme.colors.textTitle,
                    size = SmileDimens.sizeIconLg,
                )
            }
        }
    }

    private companion object {
        val ICONS = listOf(
            R.drawable.sample_ic_smart_selfie_enrollment,
            R.drawable.sample_ic_smart_selfie_auth,
            R.drawable.sample_ic_document_verification,
            R.drawable.sample_ic_biometric_kyc,
            R.drawable.sample_ic_products,
            R.drawable.sample_ic_verifications,
            R.drawable.sample_ic_settings,
            R.drawable.sample_ic_token_scan,
        )
    }
}
