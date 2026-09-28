package com.usesmileid.sampleapps.android.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import com.ramcosta.composedestinations.annotation.Destination
import com.ramcosta.composedestinations.annotation.parameters.DeepLink
import com.ramcosta.composedestinations.generated.destinations.ScanTokenScreenDestination
import com.ramcosta.composedestinations.navigation.DestinationsNavigator
import com.usesmileid.sampleapps.android.LocalUseSmileIDSampleAppState
import com.usesmileid.sampleapps.android.flow.sdkFlow
import com.usesmileid.sampleapps.android.flow.stepAfterUserDetails
import com.usesmileid.sampleapps.android.flow.tokenUserDetailsRequirement
import androidx.compose.runtime.LaunchedEffect
import com.usesmileid.sampleapps.ui.components.avatarColorForProfile
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.state.keep
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCaptureAs
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueFamily
import com.usesmileid.sampleapps.ui.state.catalogueFamily
import com.usesmileid.sampleapps.ui.screens.CaptureAsSheet as CaptureAsContent
import com.usesmileid.sampleapps.ui.screens.CountryPickerSheet as CountryPickerContent
import com.usesmileid.sampleapps.ui.screens.CustomDocumentSheet as CustomDocumentContent
import com.usesmileid.sampleapps.ui.screens.DocumentPickerSheet as DocumentPickerContent
import com.usesmileid.sampleapps.ui.screens.IdTypePickerSheet as IdTypePickerContent
import com.usesmileid.sampleapps.ui.screens.KycIdFormScreen as KycIdFormContent
import com.usesmileid.sampleapps.ui.screens.UserDetailsScreen as UserDetailsContent

/** The pre-flow wizard's routes. Function names are load-bearing: KSP names each generated `…Destination` after the function. */

/** The Consent Details Form. Shown for every product, before the SDK flow starts. */
@Destination<FlowGraph>(start = true, deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.CONSENT_DETAILS_FORM)])
@Composable
fun ConsentDetailsFormScreen(productId: String, navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    val product = productOf(productId)
    var filled by rememberSaveable { mutableStateOf(false) }
    var switchingProfile by rememberSaveable { mutableStateOf(false) }
    if (!app.profiles.loaded) return
    LaunchedEffect(Unit) {
        if (!filled) app.profiles.active?.let(app.forms::fillFrom)
        filled = true
    }
    // A deep link to this form skips the product tap, so the lists start here if nothing has started them.
    LaunchedEffect(app.environment, app.catalogueLocale) {
        if (product?.catalogueFamily != null) app.catalogue.ensure(app.environment, app.catalogueLocale)
    }
    val profile = app.profiles.active
    UserDetailsContent(
        productLabel = product?.label ?: productId,
        details = app.forms.userDetails,
        profile = profile,
        profileColor = avatarColorForProfile(app.profiles.activeIndex),
        saveToProfile = app.forms.saveToProfile,
        onFieldChange = app.forms::setUserField,
        onSaveToProfileChange = app.forms::saveToProfile,
        onProfileClick = { switchingProfile = true },
        onBack = { navigator.navigateUp() },
        onContinue = {
            app.profiles.keep(app.forms, app.tokenUserDetailsRequirement)
            val next = product?.let(app::stepAfterUserDetails) ?: app.sdkFlow(productId)
            navigator.navigate(next) { launchSingleTop = true }
        },
        requirement = app.tokenUserDetailsRequirement,
        organisation = app.forms.organisation,
        onOrganisationChange = app.forms::organisation,
    )
    if (switchingProfile) {
        ProfileSwitchSheet(
            onDismissRequest = { switchingProfile = false },
            onPicked = app.forms::fillFrom,
            draft = app.forms.userDetails,
            draftOrganisation = app.forms.organisation,
        )
    }
}

/** Only for products that need ID details. */
@Destination<FlowGraph>(deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.ID_DETAILS_FORM)])
@Composable
fun IdDetailsFormScreen(productId: String, navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    val family = productOf(productId)?.catalogueFamily ?: UseSmileIDSampleCatalogueFamily.Kyc
    var pickingCountry by rememberUseSmileIDSampleSheetState(UseSmileIDSampleSheet.CountryPicker)
    var pickingIdType by rememberUseSmileIDSampleSheetState(UseSmileIDSampleSheet.IdTypePicker)
    var pickingDocument by rememberUseSmileIDSampleSheetState(UseSmileIDSampleSheet.DocumentPicker)
    var pickingCaptureAs by rememberUseSmileIDSampleSheetState(UseSmileIDSampleSheet.CaptureAs)
    var buildingCustom by rememberUseSmileIDSampleSheetState(UseSmileIDSampleSheet.CustomDocument)
    // A deep link lands here without the product tap that fetches ahead, so the form starts it if nothing has.
    LaunchedEffect(app.environment, app.catalogueLocale) { app.catalogue.ensure(app.environment, app.catalogueLocale) }
    // A link straight to the custom sheet selects Custom too, so the form never shows a shape it did not choose.
    LaunchedEffect(buildingCustom) { if (buildingCustom) app.forms.setCaptureAs(UseSmileIDSampleCaptureAs.Custom) }
    val details = app.forms.idDetails
    val countryCode = details.country?.code
    // A link can ask for a second-level sheet before its trigger could open; refused, not held until later.
    LaunchedEffect(pickingIdType, pickingDocument, pickingCaptureAs, countryCode, details.document) {
        if (countryCode == null) {
            pickingIdType = false
            pickingDocument = false
        }
        if (details.document == null) pickingCaptureAs = false
    }
    KycIdFormContent(
        productLabel = productOf(productId)?.label ?: productId,
        family = family,
        details = details,
        countryList = when {
            countryCode == null -> app.catalogue.countries(family)
            family == UseSmileIDSampleCatalogueFamily.Kyc -> app.catalogue.idTypes(countryCode)
            else -> app.catalogue.documents(countryCode)
        },
        onCountryClick = { pickingCountry = true },
        onIdTypeClick = { pickingIdType = true },
        onDocumentClick = { pickingDocument = true },
        onCaptureAsClick = { pickingCaptureAs = true },
        onIdNumberChange = app.forms::setIdNumber,
        onBack = { navigator.navigateUp() },
        onContinue = { navigator.navigate(app.sdkFlow(productId)) { launchSingleTop = true } },
        onTokenClick = { navigator.navigate(ScanTokenScreenDestination) },
    )
    if (pickingCountry) CountryPickerSheet(family, onDismissRequest = { pickingCountry = false })
    if (pickingIdType && countryCode != null) IdTypePickerSheet(countryCode, onDismissRequest = { pickingIdType = false })
    if (pickingDocument && countryCode != null) DocumentPickerSheet(countryCode, onDismissRequest = { pickingDocument = false })
    if (pickingCaptureAs && details.document != null) {
        CaptureAsContent(
            selected = details.captureAs,
            onSelect = { choice ->
                pickingCaptureAs = false
                if (choice == UseSmileIDSampleCaptureAs.Custom) buildingCustom = true else app.forms.setCaptureAs(choice)
            },
            onDismissRequest = { pickingCaptureAs = false },
        )
    }
    if (buildingCustom) {
        CustomDocumentContent(
            initial = details.custom,
            onDone = { app.forms.setCustomDocument(it); buildingCustom = false },
            onDismissRequest = { buildingCustom = false },
        )
    }
}

/** A layer the ID-details form owns; it is not a destination (R12). */
@Composable
private fun CountryPickerSheet(family: UseSmileIDSampleCatalogueFamily, onDismissRequest: () -> Unit) {
    val app = LocalUseSmileIDSampleAppState.current
    var query by rememberSaveable { mutableStateOf("") }
    CountryPickerContent(
        catalogue = app.catalogue.countries(family),
        selected = app.forms.idDetails.country,
        query = query,
        onQueryChange = { query = it },
        onSelect = { app.forms.setCountry(it); onDismissRequest() },
        onRetry = app.catalogue::retry,
        onDismissRequest = onDismissRequest,
    )
}

/** A layer the ID-details form owns; it is not a destination (R12). */
@Composable
private fun IdTypePickerSheet(countryCode: String, onDismissRequest: () -> Unit) {
    val app = LocalUseSmileIDSampleAppState.current
    var query by rememberSaveable { mutableStateOf("") }
    IdTypePickerContent(
        country = app.forms.idDetails.country,
        catalogue = app.catalogue.idTypes(countryCode),
        selected = app.forms.idDetails.idType,
        query = query,
        onQueryChange = { query = it },
        onSelect = { app.forms.setIdType(it); onDismissRequest() },
        onRetry = app.catalogue::retry,
        onDismissRequest = onDismissRequest,
    )
}

/** A layer the ID-details form owns; it is not a destination (R12). */
@Composable
private fun DocumentPickerSheet(countryCode: String, onDismissRequest: () -> Unit) {
    val app = LocalUseSmileIDSampleAppState.current
    var query by rememberSaveable { mutableStateOf("") }
    DocumentPickerContent(
        country = app.forms.idDetails.country,
        catalogue = app.catalogue.documents(countryCode),
        selected = app.forms.idDetails.document,
        query = query,
        onQueryChange = { query = it },
        onSelect = { app.forms.setDocument(it); onDismissRequest() },
        onRetry = app.catalogue::retry,
        onDismissRequest = onDismissRequest,
    )
}

private fun productOf(productId: String) = UseSmileIDSampleProduct.entries.firstOrNull { it.id == productId }
