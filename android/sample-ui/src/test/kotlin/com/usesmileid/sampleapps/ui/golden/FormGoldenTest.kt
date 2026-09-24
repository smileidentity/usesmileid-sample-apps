package com.usesmileid.sampleapps.ui.golden

import com.usesmileid.sampleapps.ui.components.avatarColorForProfile
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleProfile

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.screens.CountryPickerSheet
import com.usesmileid.sampleapps.ui.screens.IdTypePickerSheet
import com.usesmileid.sampleapps.ui.screens.KycIdFormScreen
import com.usesmileid.sampleapps.ui.screens.UserDetailsScreen
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCountry
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdType
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenBindings
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetailsRequirement
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserField
import com.usesmileid.sampleapps.ui.state.userDetailsRequirement
import org.junit.Test

/** The two pre-flow forms and the sheets the ID form owns, in the states the spec names. */
class FormGoldenTest : GoldenTest() {

    @Test
    fun user_details_empty() = goldens("screen_user_details_empty") { UserDetails(UseSmileIDSampleUserDetails(), profile = null) }

    /** The first run with something typed: the organisation row and "Save as a new profile" both show. */
    @Test
    fun user_details_no_profile_complete() = goldens("screen_user_details_no_profile") {
        UserDetails(COMPLETE, profile = null, organisation = "Sahara Pay")
    }

    @Test
    fun user_details_no_profile_max_font_scale() =
        assertSurvivesMaxFontScale { UserDetails(COMPLETE, profile = null, organisation = "Sahara Pay") }

    /** The caret blinks on a 1s cycle, so the clock is held 250ms past focus — inside its visible half. */
    @Test
    fun user_details_editing() = goldens(
        name = "screen_user_details_editing",
        interact = {
            holdClock()
            type(UseSmileIDSampleTestIds.userDetailsField(UseSmileIDSampleUserField.LastName.id), LAST_NAME_TYPED)
            advance(CARET_VISIBLE_MILLIS)
        },
    ) { EditableUserDetails(PARTIAL) }

    @Test
    fun user_details_complete() = goldens("screen_user_details_complete") { UserDetails(COMPLETE) }

    @Test
    fun user_details_max_font_scale() = assertSurvivesMaxFontScale { UserDetails(COMPLETE) }

    @Test
    fun user_details_token_supplied() = goldens("screen_user_details_token_supplied") {
        UserDetails(UseSmileIDSampleUserDetails(), TOKEN_SUPPLIED_NAMES)
    }

    @Test
    fun user_details_token_supplied_max_font_scale() =
        assertSurvivesMaxFontScale { UserDetails(UseSmileIDSampleUserDetails(), TOKEN_SUPPLIED_NAMES) }

    @Test
    fun kyc_form_empty() = goldens("screen_kyc_form_empty") { KycForm(UseSmileIDSampleIdDetails()) }

    @Test
    fun kyc_form_selected() = goldens("screen_kyc_form_selected") { KycForm(SELECTED) }

    @Test
    fun kyc_form_max_font_scale() = assertSurvivesMaxFontScale { KycForm(SELECTED) }

    @Test
    fun country_picker_sheet() = goldens("sheet_country_picker", fullWindow = true) {
        Box(modifier = Modifier.fillMaxSize()) {
            KycForm(UseSmileIDSampleIdDetails())
            CountryPickerSheet(
                selected = null,
                query = "",
                onQueryChange = {},
                onSelect = {},
                onDismissRequest = {},
            )
        }
    }

    @Test
    fun id_type_picker_sheet() = goldens("sheet_id_type_picker", fullWindow = true) {
        Box(modifier = Modifier.fillMaxSize()) {
            KycForm(COUNTRY_ONLY)
            IdTypePickerSheet(
                country = UseSmileIDSampleCountry.Kenya,
                selected = null,
                query = "",
                onQueryChange = {},
                onSelect = {},
                onDismissRequest = {},
            )
        }
    }

    private companion object {
        /** Long enough past focus to be inside the caret's visible half, short enough to stay in the first cycle. */
        const val CARET_VISIBLE_MILLIS = 250L

        /** Typed into an empty field, so the caret ends up after the text rather than before it. */
        const val LAST_NAME_TYPED = "Asant"

        /** Mid-edit: the first name is in and the last name is still being typed. */
        val PARTIAL = UseSmileIDSampleUserDetails(firstName = "Kwame")

        /** A country chosen and nothing else, which is the only state that unlocks the ID-type trigger. */
        val COUNTRY_ONLY = UseSmileIDSampleIdDetails(country = UseSmileIDSampleCountry.Kenya)

        val COMPLETE = UseSmileIDSampleUserDetails(
            firstName = "Kwame",
            lastName = "Asante",
            email = "kwame@uptech.example",
            phone = "+254 700 000 000",
        )
        /** A token binding both names and no contact — the partial case the form has to explain. */
        val TOKEN_SUPPLIED_NAMES = UseSmileIDSampleTokenBindings(givenNames = true, lastName = true)
            .userDetailsRequirement()
        val SELECTED = UseSmileIDSampleIdDetails(
            country = UseSmileIDSampleCountry.Kenya,
            idType = UseSmileIDSampleIdType.NationalId,
            idNumber = "AO12345678",
        )
    }

    @Composable
    private fun UserDetails(
        details: UseSmileIDSampleUserDetails,
        requirement: UseSmileIDSampleUserDetailsRequirement = UseSmileIDSampleUserDetailsRequirement(),
        profile: UseSmileIDSampleProfile? = ProfileFixtures.Seeded.active,
        organisation: String = "",
    ) = UserDetailsScreen(
        productLabel = "Biometric KYC",
        details = details,
        profile = profile,
        profileColor = avatarColorForProfile(0),
        saveToProfile = true,
        onFieldChange = { _, _ -> },
        onSaveToProfileChange = {},
        onProfileClick = {},
        onBack = {},
        onContinue = {},
        requirement = requirement,
        organisation = organisation,
    )

    /** Its own state, so the keystroke the caret follows actually lands in the field. */
    @Composable
    private fun EditableUserDetails(initial: UseSmileIDSampleUserDetails) {
        var details by remember { mutableStateOf(initial) }
        UserDetailsScreen(
            productLabel = "Biometric KYC",
            details = details,
            profile = ProfileFixtures.Seeded.active,
            profileColor = avatarColorForProfile(0),
            saveToProfile = true,
            onFieldChange = { field, value -> details = field.write(details, value) },
            onSaveToProfileChange = {},
            onProfileClick = {},
            onBack = {},
            onContinue = {},
        )
    }

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
