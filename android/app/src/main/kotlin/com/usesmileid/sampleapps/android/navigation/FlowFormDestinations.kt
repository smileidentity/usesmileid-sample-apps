package com.usesmileid.sampleapps.android.navigation

import com.usesmileid.sampleapps.ui.localizedTitle
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import com.usesmileid.sampleapps.android.LocalUseSmileIDSampleAppState
import com.usesmileid.sampleapps.android.flow.entryFor
import com.usesmileid.sampleapps.android.flow.userDetailsRequirement
import androidx.compose.runtime.LaunchedEffect
import com.usesmileid.sampleapps.ui.components.avatarColorForProfile
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.state.keep
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCaptureAs
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueFamily
import com.usesmileid.sampleapps.ui.state.catalogueFamily
import com.usesmileid.sampleapps.ui.state.resolvedCaptureAs
import com.usesmileid.sampleapps.ui.screens.CaptureAsSheet as CaptureAsContent
import com.usesmileid.sampleapps.ui.screens.CountryPickerSheet as CountryPickerContent
import com.usesmileid.sampleapps.ui.screens.GenericDocumentSheet as GenericDocumentContent
import com.usesmileid.sampleapps.ui.screens.DocumentPickerSheet as DocumentPickerContent
import com.usesmileid.sampleapps.ui.screens.IdTypePickerSheet as IdTypePickerContent
import com.usesmileid.sampleapps.ui.screens.KycIdFormScreen as KycIdFormContent
import com.usesmileid.sampleapps.ui.screens.UserDetailsScreen as UserDetailsContent
import com.usesmileid.sampleapps.ui.screens.AuthUserIdScreen as AuthUserIdContent
import com.usesmileid.sampleapps.ui.state.previousAuthUsers
import com.usesmileid.sampleapps.ui.state.settledItems

/** The pre-flow wizard's steps. Each form's Continue is `next`, and the graph skips the forms the run's facts leave out. */

/** The Consent Details Form. Shown for every product, before the SDK flow starts. */
@Composable
internal fun ConsentDetailsFormScreen(scope: UseSmileIDSampleStepScope) {
    val app = LocalUseSmileIDSampleAppState.current
    val engine = LocalUseSmileIDSampleEngine.current
    val productId = engine.runProductId(scope.entry).orEmpty()
    val product = productOf(productId)
    var filled by rememberSaveable { mutableStateOf(false) }
    if (!app.profiles.loaded) return
    LaunchedEffect(Unit) {
        if (!filled) app.profiles.active?.let(app.forms::fillFrom)
        filled = true
    }
    // A deep link to this form skips the product tap, so the lists start here if nothing has started them.
    LaunchedEffect(app.environment, app.catalogueLocale, app.session?.id) { app.ensureCatalogue(product) }
    val profile = app.profiles.active
    val requirement = app.userDetailsRequirement(product)
    UserDetailsContent(
        productLabel = product?.localizedTitle() ?: productId,
        details = app.forms.userDetails,
        profile = profile,
        profileColor = avatarColorForProfile(app.profiles.activeIndex),
        saveToProfile = app.forms.saveToProfile,
        onFieldChange = app.forms::setUserField,
        onSaveToProfileChange = app.forms::saveToProfile,
        onProfileClick = { scope.navigator.go(UseSmileIDSampleStep.ProfileSwitch) },
        onBack = scope.navigator::back,
        onContinue = {
            app.profiles.keep(app.forms, requirement)
            scope.navigator.next()
        },
        requirement = requirement,
        organisation = app.forms.organisation,
        onOrganisationChange = app.forms::organisation,
    )
}

/** SmartSelfie Authentication's user ID, typed or picked from runs that enrolled one; the run never makes one up. */
@Composable
internal fun AuthUserIdScreen(scope: UseSmileIDSampleStepScope) {
    val app = LocalUseSmileIDSampleAppState.current
    val engine = LocalUseSmileIDSampleEngine.current
    AuthUserIdContent(
        userId = app.forms.authUserId,
        // A user is enrolled under one partner in one environment, so another's IDs would authenticate nobody.
        previousUsers = previousAuthUsers(app.jobs.orEmpty(), app.session?.partnerId, app.useSandbox),
        onUserIdChange = app.forms::authUserId,
        onRegister = {
            app.forms.startRun(app.profiles.active)
            val enrolment = UseSmileIDSampleProduct.SmartSelfieEnrollment
            val start = engine.runStart(scope.entry)?.id
            val run = app.entryFor(engine.graph, enrolment)
            if (run == null) {
                scope.navigator.go(UseSmileIDSampleStep.ScanToken.wireName, replace = start)
            } else {
                engine.startRun(scope.entry, enrolment, run, replace = start)
            }
        },
        onBack = scope.navigator::back,
        onContinue = scope.navigator::next,
    )
}

/** Only for products that need ID details; its pickers are sheet steps over it. */
@Composable
internal fun IdDetailsFormScreen(scope: UseSmileIDSampleStepScope) {
    val app = LocalUseSmileIDSampleAppState.current
    val engine = LocalUseSmileIDSampleEngine.current
    val productId = engine.runProductId(scope.entry).orEmpty()
    val product = productOf(productId)
    val family = product?.catalogueFamily ?: UseSmileIDSampleCatalogueFamily.Kyc
    // A deep link lands here without the product tap that fetches ahead, so the form starts it if nothing has.
    LaunchedEffect(app.environment, app.catalogueLocale, app.session?.id) { app.ensureCatalogue(product) }
    LaunchedEffect(product) { product?.let(app.forms::keepDocumentListedOn) }
    val details = app.forms.idDetails
    val countryCode = details.country?.code
    val countries = app.catalogue.countries(family, product)
    if (product == UseSmileIDSampleProduct.EnhancedDocumentVerification) {
        val enabledDocuments = countryCode?.let { app.catalogue.documents(it, product).settledItems }
        LaunchedEffect(countries.settledItems, enabledDocuments) {
            // Read again: the ensure effect above may have just reset a previous session's list.
            val code = app.forms.idDetails.country?.code
            app.forms.keepOnlyEnabled(
                app.catalogue.countries(family, product).settledItems,
                code?.let { app.catalogue.documents(it, product).settledItems },
            )
        }
    }
    KycIdFormContent(
        productLabel = product?.localizedTitle() ?: productId,
        family = family,
        details = details,
        countryList = when {
            countryCode == null -> countries
            family == UseSmileIDSampleCatalogueFamily.Kyc -> app.catalogue.idTypes(countryCode)
            else -> app.catalogue.documents(countryCode, product ?: UseSmileIDSampleProduct.DocumentVerification)
        },
        onCountryClick = { scope.navigator.go(UseSmileIDSampleStep.CountryPicker) },
        onIdTypeClick = { scope.navigator.go(UseSmileIDSampleStep.IdTypePicker) },
        onDocumentClick = { scope.navigator.go(UseSmileIDSampleStep.DocumentPicker) },
        onCaptureAsClick = { scope.navigator.go(UseSmileIDSampleStep.CaptureAs) },
        onIdNumberChange = app.forms::setIdNumber,
        onBack = scope.navigator::back,
        onContinue = scope.navigator::next,
        onTokenClick = { scope.navigator.go(UseSmileIDSampleStep.ScanToken) },
    )
}

/** The country picker over the ID-details form. */
@Composable
internal fun CountryPickerSheet(scope: UseSmileIDSampleStepScope) {
    val app = LocalUseSmileIDSampleAppState.current
    val product = productOf(LocalUseSmileIDSampleEngine.current.runProductId(scope.entry))
    val family = product?.catalogueFamily ?: UseSmileIDSampleCatalogueFamily.Kyc
    var query by rememberSaveable { mutableStateOf("") }
    CountryPickerContent(
        catalogue = app.catalogue.countries(family, product),
        selected = app.forms.idDetails.country,
        query = query,
        onQueryChange = { query = it },
        onSelect = { app.forms.setCountry(it); scope.navigator.back() },
        onRetry = app.catalogue::retry,
        onDismissRequest = scope.navigator::back,
    )
}

/** The ID-type picker, which needs a country first; a link that arrives before one is picked closes it. */
@Composable
internal fun IdTypePickerSheet(scope: UseSmileIDSampleStepScope) {
    val app = LocalUseSmileIDSampleAppState.current
    val countryCode = app.forms.idDetails.country?.code
    if (countryCode == null) {
        LaunchedEffect(Unit) { scope.navigator.back() }
        return
    }
    var query by rememberSaveable { mutableStateOf("") }
    IdTypePickerContent(
        country = app.forms.idDetails.country,
        catalogue = app.catalogue.idTypes(countryCode),
        selected = app.forms.idDetails.idType,
        query = query,
        onQueryChange = { query = it },
        onSelect = { app.forms.setIdType(it); scope.navigator.back() },
        onRetry = app.catalogue::retry,
        onDismissRequest = scope.navigator::back,
    )
}

/** The document picker, which needs a country first; a link that arrives before one is picked closes it. */
@Composable
internal fun DocumentPickerSheet(scope: UseSmileIDSampleStepScope) {
    val app = LocalUseSmileIDSampleAppState.current
    val product = productOf(LocalUseSmileIDSampleEngine.current.runProductId(scope.entry)) ?: UseSmileIDSampleProduct.DocumentVerification
    val countryCode = app.forms.idDetails.country?.code
    if (countryCode == null) {
        LaunchedEffect(Unit) { scope.navigator.back() }
        return
    }
    var query by rememberSaveable { mutableStateOf("") }
    DocumentPickerContent(
        country = app.forms.idDetails.country,
        catalogue = app.catalogue.documents(countryCode, product),
        selected = app.forms.idDetails.document,
        query = query,
        onQueryChange = { query = it },
        onSelect = { app.forms.setDocument(it); scope.navigator.back() },
        onRetry = app.catalogue::retry,
        onDismissRequest = scope.navigator::back,
    )
}

/** How the picked document is captured; a generic document swaps this sheet for its builder. */
@Composable
internal fun CaptureAsSheet(scope: UseSmileIDSampleStepScope) {
    val app = LocalUseSmileIDSampleAppState.current
    val details = app.forms.idDetails
    val document = details.document
    if (document == null) {
        LaunchedEffect(Unit) { scope.navigator.back() }
        return
    }
    CaptureAsContent(
        selected = details.captureAsOverride,
        matched = resolvedCaptureAs(document, override = null, details.genericDocument),
        onSelect = { choice ->
            if (choice == UseSmileIDSampleCaptureAs.GenericDocument) {
                scope.navigator.go(UseSmileIDSampleStep.GenericDocument.wireName, replace = scope.entry.id)
            } else {
                app.forms.setCaptureAs(choice)
                scope.navigator.back()
            }
        },
        onDismissRequest = scope.navigator::back,
    )
}

/** The generic document's builder, in the capture-as sheet's place. */
@Composable
internal fun GenericDocumentSheet(scope: UseSmileIDSampleStepScope) {
    val app = LocalUseSmileIDSampleAppState.current
    GenericDocumentContent(
        initial = app.forms.idDetails.genericDocument,
        onDone = { app.forms.setGenericDocument(it); scope.navigator.back() },
        onDismissRequest = scope.navigator::back,
    )
}

private fun productOf(productId: String?) = UseSmileIDSampleProduct.entries.firstOrNull { it.id == productId }
