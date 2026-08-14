package com.usesmileid.sampleapps.ui.golden

import androidx.compose.runtime.Composable
import com.usesmileid.sampleapps.ui.screens.KycIdFormScreen
import com.usesmileid.sampleapps.ui.screens.UserDetailsScreen
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCountry
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdType
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import org.junit.Test

/** The two pre-flow forms, in the states `spec/screens.json` names. */
class FormGoldenTest : GoldenTest() {

    @Test
    fun user_details_empty() = goldens("screen_user_details_empty") { UserDetails(UseSmileIDSampleUserDetails()) }

    @Test
    fun user_details_complete() = goldens("screen_user_details_complete") { UserDetails(COMPLETE) }

    @Test
    fun user_details_max_font_scale() = assertSurvivesMaxFontScale { UserDetails(COMPLETE) }

    @Test
    fun kyc_form_empty() = goldens("screen_kyc_form_empty") { KycForm(UseSmileIDSampleIdDetails()) }

    @Test
    fun kyc_form_selected() = goldens("screen_kyc_form_selected") { KycForm(SELECTED) }

    @Test
    fun kyc_form_max_font_scale() = assertSurvivesMaxFontScale { KycForm(SELECTED) }

    private companion object {
        val COMPLETE = UseSmileIDSampleUserDetails(
            firstName = "Kwame",
            lastName = "Asante",
            email = "kwame@uptech.example",
            phone = "+254 700 000 000",
        )
        val SELECTED = UseSmileIDSampleIdDetails(
            country = UseSmileIDSampleCountry.Kenya,
            idType = UseSmileIDSampleIdType.NationalId,
            idNumber = "AO12345678",
        )
    }

    @Composable
    private fun UserDetails(details: UseSmileIDSampleUserDetails) = UserDetailsScreen(
        productLabel = "Biometric KYC",
        details = details,
        rememberDetails = true,
        onFieldChange = { _, _ -> },
        onRememberChange = {},
        onBack = {},
        onContinue = {},
    )

    @Composable
    private fun KycForm(details: UseSmileIDSampleIdDetails) = KycIdFormScreen(
        productLabel = "Biometric KYC",
        details = details,
        onCountryClick = {},
        onIdTypeClick = {},
        onIdNumberChange = {},
        onBack = {},
        onContinue = {},
        onTokenClick = {},
    )
}
