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
import com.usesmileid.sampleapps.ui.CatalogueFixtures
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleAspectRatio
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCaptureAs
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogue
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueFamily
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleDocument
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleDocumentOrientation
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleGenericDocument
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdDetails
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
    fun kyc_form_id_number_invalid() = goldens("screen_kyc_form_id_number_invalid") { KycForm(INVALID_NUMBER) }

    @Test
    fun kyc_form_id_number_invalid_max_font_scale() = assertSurvivesMaxFontScale { KycForm(INVALID_NUMBER) }

    /** The country's list is still arriving: the trigger stays enabled and says so. */
    @Test
    fun kyc_form_loading() = goldens("screen_kyc_form_loading") {
        KycForm(COUNTRY_ONLY, countryList = UseSmileIDSampleCatalogue.Loading)
    }

    /** The list failed: the trigger goes back to its prompt, so the form never looks stuck. */
    @Test
    fun kyc_form_catalogue_error() = goldens("screen_kyc_form_catalogue_error") {
        KycForm(COUNTRY_ONLY, countryList = UseSmileIDSampleCatalogue.Failed("offline"))
    }

    @Test
    fun document_form_selected() = goldens("screen_document_form_selected") {
        KycForm(DOCUMENT_SELECTED, family = UseSmileIDSampleCatalogueFamily.Document, productLabel = "Document Verification")
    }

    @Test
    fun document_form_passport_matched() = goldens("screen_document_form_passport_matched") {
        KycForm(documentForm("KE") { it.code == "PASSPORT" }, family = UseSmileIDSampleCatalogueFamily.Document, productLabel = "Document Verification")
    }

    @Test
    fun document_form_two_sided_matched() = goldens("screen_document_form_two_sided_matched") {
        KycForm(documentForm("KE") { it.code == "IDENTITY_CARD" }, family = UseSmileIDSampleCatalogueFamily.Document, productLabel = "Document Verification")
    }

    @Test
    fun document_form_one_sided_matched() = goldens("screen_document_form_one_sided_matched") {
        KycForm(documentForm("KE") { it.code == "ALIEN_CARD" }, family = UseSmileIDSampleCatalogueFamily.Document, productLabel = "Document Verification")
    }

    @Test
    fun document_form_preset_chosen() = goldens("screen_document_form_preset_chosen") {
        val details = documentForm("KE") { it.code == "IDENTITY_CARD" }.copy(captureAsOverride = UseSmileIDSampleCaptureAs.Passport)
        KycForm(details, family = UseSmileIDSampleCatalogueFamily.Document, productLabel = "Document Verification")
    }

    @Test
    fun document_form_generic_chosen() = goldens("screen_document_form_generic_chosen") {
        val details = documentForm("KE") { it.code == "PASSPORT" }.copy(
            captureAsOverride = UseSmileIDSampleCaptureAs.GenericDocument,
            genericDocument = UseSmileIDSampleGenericDocument(
                displayName = "Booklet",
                orientation = UseSmileIDSampleDocumentOrientation.Portrait,
                aspectRatio = UseSmileIDSampleAspectRatio.Booklet,
            ),
        )
        KycForm(details, family = UseSmileIDSampleCatalogueFamily.Document, productLabel = "Document Verification")
    }

    @Test
    fun document_form_max_font_scale() = assertSurvivesMaxFontScale {
        KycForm(DOCUMENT_SELECTED, family = UseSmileIDSampleCatalogueFamily.Document, productLabel = "Document Verification")
    }

    @Test
    fun country_picker_sheet() = goldens("sheet_country_picker", fullWindow = true) {
        Box(modifier = Modifier.fillMaxSize()) {
            KycForm(UseSmileIDSampleIdDetails())
            CountryPickerSheet(
                catalogue = UseSmileIDSampleCatalogue.Ready(CatalogueFixtures.countries(UseSmileIDSampleCatalogueFamily.Kyc)),
                selected = null,
                query = "",
                onQueryChange = {},
                onSelect = {},
                onRetry = {},
                onDismissRequest = {},
            )
        }
    }

    @Test
    fun id_type_picker_sheet() = goldens("sheet_id_type_picker", fullWindow = true) {
        Box(modifier = Modifier.fillMaxSize()) {
            KycForm(COUNTRY_ONLY)
            IdTypePickerSheet(
                country = CatalogueFixtures.kenya,
                catalogue = UseSmileIDSampleCatalogue.Ready(CatalogueFixtures.idTypes("KE")),
                selected = null,
                query = "",
                onQueryChange = {},
                onSelect = {},
                onRetry = {},
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
        val COUNTRY_ONLY = UseSmileIDSampleIdDetails(country = CatalogueFixtures.kenya)

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
            country = CatalogueFixtures.kenya,
            idType = CatalogueFixtures.idTypes("KE").first { it.type == "NATIONAL_ID" },
            idNumber = "12345678",
        )

        /** Letters where Kenya's National ID takes only digits, so the field explains the format. */
        val INVALID_NUMBER = SELECTED.copy(idNumber = "AO12345678")

        /** A fixture country's row, with "Capture as" untouched. */
        fun documentForm(country: String, row: (UseSmileIDSampleDocument) -> Boolean) = UseSmileIDSampleIdDetails(
            country = if (country == "KE") CatalogueFixtures.kenya else CatalogueFixtures.southAfrica,
            document = CatalogueFixtures.documents(country).first(row),
        )

        /** The Green Book: a standalone sub-type row, which Match document captures as the Green Book preset. */
        val DOCUMENT_SELECTED = UseSmileIDSampleIdDetails(
            country = CatalogueFixtures.southAfrica,
            document = CatalogueFixtures.documents("ZA").first { it.subType == "green_book" },
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
    private fun KycForm(
        details: UseSmileIDSampleIdDetails,
        family: UseSmileIDSampleCatalogueFamily = UseSmileIDSampleCatalogueFamily.Kyc,
        productLabel: String = "Biometric KYC",
        countryList: UseSmileIDSampleCatalogue<*> = UseSmileIDSampleCatalogue.Ready(emptyList<Unit>()),
    ) = KycIdFormScreen(
        productLabel = productLabel,
        family = family,
        details = details,
        countryList = countryList,
        captureBothSides = true,
        onCountryClick = {},
        onIdTypeClick = {},
        onDocumentClick = {},
        onCaptureAsClick = {},
        onIdNumberChange = {},
        onBack = {},
        onContinue = {},
        onTokenClick = {},
    )
}
