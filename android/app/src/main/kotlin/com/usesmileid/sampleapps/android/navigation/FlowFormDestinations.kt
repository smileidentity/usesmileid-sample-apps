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
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.screens.CountryPickerSheet as CountryPickerContent
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
    UserDetailsContent(
        productLabel = product?.label ?: productId,
        details = app.forms.userDetails,
        rememberDetails = app.forms.rememberDetails,
        onFieldChange = app.forms::setUserField,
        onRememberChange = app.forms::rememberDetails,
        onBack = { navigator.navigateUp() },
        onContinue = {
            val next = product?.let(app::stepAfterUserDetails) ?: app.sdkFlow(productId)
            navigator.navigate(next) { launchSingleTop = true }
        },
        requirement = app.tokenUserDetailsRequirement,
    )
}

/** Only for products that need ID details. */
@Destination<FlowGraph>(deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.ID_DETAILS_FORM)])
@Composable
fun IdDetailsFormScreen(productId: String, navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    var pickingCountry by rememberUseSmileIDSampleSheetState(UseSmileIDSampleSheet.CountryPicker)
    var pickingIdType by rememberUseSmileIDSampleSheetState(UseSmileIDSampleSheet.IdTypePicker)
    KycIdFormContent(
        productLabel = productOf(productId)?.label ?: productId,
        details = app.forms.idDetails,
        onCountryClick = { pickingCountry = true },
        onIdTypeClick = { pickingIdType = true },
        onIdNumberChange = app.forms::setIdNumber,
        onBack = { navigator.navigateUp() },
        onContinue = { navigator.navigate(app.sdkFlow(productId)) { launchSingleTop = true } },
        onTokenClick = { navigator.navigate(ScanTokenScreenDestination) },
    )
    if (pickingCountry) CountryPickerSheet(onDismissRequest = { pickingCountry = false })
    if (pickingIdType) IdTypePickerSheet(onDismissRequest = { pickingIdType = false })
}

/** A layer the ID-details form owns; it is not a destination (R12). */
@Composable
private fun CountryPickerSheet(onDismissRequest: () -> Unit) {
    val app = LocalUseSmileIDSampleAppState.current
    var query by rememberSaveable { mutableStateOf("") }
    CountryPickerContent(
        selected = app.forms.idDetails.country,
        query = query,
        onQueryChange = { query = it },
        onSelect = { app.forms.setCountry(it); onDismissRequest() },
        onDismissRequest = onDismissRequest,
    )
}

/** A layer the ID-details form owns; it is not a destination (R12). */
@Composable
private fun IdTypePickerSheet(onDismissRequest: () -> Unit) {
    val app = LocalUseSmileIDSampleAppState.current
    var query by rememberSaveable { mutableStateOf("") }
    IdTypePickerContent(
        country = app.forms.idDetails.country,
        selected = app.forms.idDetails.idType,
        query = query,
        onQueryChange = { query = it },
        onSelect = { app.forms.setIdType(it); onDismissRequest() },
        onDismissRequest = onDismissRequest,
    )
}

private fun productOf(productId: String) = UseSmileIDSampleProduct.entries.firstOrNull { it.id == productId }
