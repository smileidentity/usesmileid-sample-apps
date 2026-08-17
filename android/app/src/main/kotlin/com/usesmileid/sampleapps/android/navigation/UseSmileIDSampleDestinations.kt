package com.usesmileid.sampleapps.android.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import com.ramcosta.composedestinations.annotation.Destination
import com.ramcosta.composedestinations.annotation.RootGraph
import com.ramcosta.composedestinations.annotation.parameters.DeepLink
import com.ramcosta.composedestinations.generated.destinations.ConsentDetailsFormScreenDestination
import com.ramcosta.composedestinations.generated.destinations.CountryPickerSheetDestination
import com.ramcosta.composedestinations.generated.destinations.IdDetailsFormScreenDestination
import com.ramcosta.composedestinations.generated.destinations.IdTypePickerSheetDestination
import com.ramcosta.composedestinations.generated.destinations.NewProfileSheetDestination
import com.ramcosta.composedestinations.generated.destinations.ProfileConfigScreenDestination
import com.ramcosta.composedestinations.generated.destinations.ProfileSwitchSheetDestination
import com.ramcosta.composedestinations.generated.destinations.ScanTokenScreenDestination
import com.ramcosta.composedestinations.generated.destinations.ScenarioDrawerSheetDestination
import com.ramcosta.composedestinations.generated.destinations.VerificationDetailsScreenDestination
import com.ramcosta.composedestinations.navigation.DestinationsNavigator
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.android.BuildConfig
import com.usesmileid.sampleapps.android.LocalUseSmileIDSampleAppState
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSelectionBar
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleToast
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJobFilter
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleVerificationsState
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleProductsState
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import com.usesmileid.sampleapps.ui.state.toCountdown
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import com.usesmileid.sampleapps.android.gallery.ComponentGalleryScreen as ComponentGalleryContent
import com.usesmileid.sampleapps.ui.screens.CountryPickerSheet as CountryPickerContent
import com.usesmileid.sampleapps.ui.screens.IdTypePickerSheet as IdTypePickerContent
import com.usesmileid.sampleapps.ui.screens.KycIdFormScreen as KycIdFormContent
import com.usesmileid.sampleapps.ui.screens.NewProfileSheet as NewProfileContent
import com.usesmileid.sampleapps.ui.screens.ProductsScreen as ProductsContent
import com.usesmileid.sampleapps.ui.screens.ProfileConfigScreen as ProfileConfigContent
import com.usesmileid.sampleapps.ui.screens.ProfileSwitchSheet as ProfileSwitchContent
import com.usesmileid.sampleapps.ui.screens.ProfilesScreen as ProfilesContent
import com.usesmileid.sampleapps.ui.screens.ScanTokenScreen as ScanTokenContent
import com.usesmileid.sampleapps.ui.screens.ScenarioDrawerSheet as ScenarioDrawerContent
import com.usesmileid.sampleapps.ui.screens.SettingsScreen as SettingsContent
import com.usesmileid.sampleapps.ui.screens.UserDetailsScreen as UserDetailsContent
import com.usesmileid.sampleapps.ui.screens.VerificationDetailsScreen as VerificationDetailsContent
import com.usesmileid.sampleapps.ui.screens.VerificationsScreen as VerificationsContent

/**
 * Every route the app owns. Function names are load-bearing: KSP names each generated
 * `…Destination` object after the function. Screens are imported under aliases because the same
 * simple name here would recurse instead of delegating.
 */

@Destination<ProductsGraph>(start = true, deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.PRODUCTS)])
@Composable
fun ProductsScreen(navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    ProductsContent(
        state = UseSmileIDSampleProductsState(
            environment = app.profiles.active.environment,
            initials = app.profiles.active.initials,
            sessionId = app.session?.id?.takeIf { app.sessionActive },
            sessionRemaining = app.session
                ?.takeIf { app.sessionActive }
                ?.remaining(app.nowMillis)
                ?.toCountdown(),
            sessionEnded = app.sessionExpired,
            result = app.flowResult.snapshot,
        ),
        onProductClick = { navigator.navigate(ConsentDetailsFormScreenDestination(productId = it.id)) },
        onProfileClick = { navigator.navigate(ProfileSwitchSheetDestination) },
        onScanClick = { navigator.navigate(ScanTokenScreenDestination) },
    )
}

@Destination<VerificationsGraph>(start = true, deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.VERIFICATIONS)])
@Composable
fun VerificationsScreen(navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    var filter by rememberSaveable { mutableStateOf(UseSmileIDSampleJobFilter.All) }
    var selectMode by rememberSaveable { mutableStateOf(false) }
    var selected by rememberSaveable { mutableStateOf(emptySet<String>()) }
    var removedCount by rememberSaveable { mutableIntStateOf(0) }

    // One path for both removals — the swipe and the selection bar — so they cannot drift apart.
    val removeJobs: (Set<String>) -> Unit = { ids ->
        app.jobs.remove(ids)
        removedCount = ids.size
        selected = emptySet()
        selectMode = false
        // Removing a filter's last row otherwise leaves an empty screen under a chip reading 0,
        // with nothing to say why, so fall back to the filter that always has something to show.
        if (app.jobs.count(filter) == 0) filter = UseSmileIDSampleJobFilter.All
    }

    Box(modifier = Modifier.fillMaxSize()) {
        VerificationsContent(
            state = UseSmileIDSampleVerificationsState(
                jobs = app.jobs.all,
                counts = UseSmileIDSampleJobFilter.entries.associateWith(app.jobs::count),
                filter = filter,
                selectMode = selectMode,
                selected = selected,
                nowMillis = app.nowMillis,
            ),
            onFilterChange = { filter = it },
            onSelectModeChange = { selectMode = it; if (!it) selected = emptySet() },
            onSelectionChange = { id, checked -> selected = if (checked) selected + id else selected - id },
            onJobClick = { navigator.navigate(VerificationDetailsScreenDestination(jobId = it.id)) },
            onRemove = removeJobs,
        )
        if (selectMode) {
            UseSmileIDSampleSelectionBar(
                selectedCount = selected.size,
                onRemove = { removeJobs(selected) },
                modifier = Modifier.align(Alignment.BottomCenter),
            )
        }
        if (removedCount > 0) {
            // Bounded, so a toast left up cannot restore rows long after the removal it belonged to.
            LaunchedEffect(removedCount) {
                delay(UNDO_WINDOW_MILLIS)
                removedCount = 0
            }
            UseSmileIDSampleToast(
                message = if (removedCount == 1) "Verification removed" else "$removedCount verifications removed",
                actionLabel = "Undo",
                onAction = { app.jobs.undoRemove(); removedCount = 0 },
                // One gap above the container's bottom, which the shell has already inset past the
                // floating nav bar — adding the navigationBars inset again lifts it into the list.
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingXxs),
            )
        }
    }
}

@Destination<SettingsGraph>(start = true, deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.SETTINGS)])
@Composable
fun SettingsScreen(navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    SettingsContent(
        settings = app.settings,
        onSettingChange = { setting, enabled -> app.storeScope.launch { app.store.setSetting(setting, enabled) } },
        organisation = app.profiles.active.organisation,
        initials = app.profiles.active.initials,
        versionLabel = "$APP_DISPLAY_NAME · ${BuildConfig.VERSION_NAME}",
        onProfileClick = { navigator.navigate(ProfileConfigScreenDestination(profileId = app.profiles.activeId)) },
        onNavRowClick = {},
        onOpenScenarioDrawer = { navigator.navigate(ScenarioDrawerSheetDestination) },
        onSignOut = {},
    )
}

/** Also the post-submission landing route: on a result the flow and both forms are replaced. */
@Destination<VerificationsGraph>(deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.VERIFICATION_DETAILS)])
@Composable
fun VerificationDetailsScreen(jobId: String, navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    val clipboard = LocalClipboardManager.current
    VerificationDetailsContent(
        jobId = jobId,
        job = app.jobs.all.firstOrNull { it.id == jobId },
        result = app.flowResult.snapshot,
        onBack = { navigator.navigateUp() },
        onDelete = { app.jobs.remove(setOf(jobId)); navigator.navigateUp() },
        onCopy = { clipboard.setText(AnnotatedString(it)) },
    )
}

/** The Consent Details Form. Shown for every product, before the SDK flow starts. */
@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.CONSENT_DETAILS_FORM)])
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
            if (product?.needsIdDetails == true) {
                navigator.navigate(IdDetailsFormScreenDestination(productId = productId))
            }
        },
    )
}

/** Only for products that need ID details. */
@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.ID_DETAILS_FORM)])
@Composable
fun IdDetailsFormScreen(productId: String, navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    KycIdFormContent(
        productLabel = productOf(productId)?.label ?: productId,
        details = app.forms.idDetails,
        onCountryClick = { navigator.navigate(CountryPickerSheetDestination(productId = productId)) },
        onIdTypeClick = { navigator.navigate(IdTypePickerSheetDestination(productId = productId)) },
        onIdNumberChange = app.forms::setIdNumber,
        onBack = { navigator.navigateUp() },
        onContinue = {},
        onTokenClick = { navigator.navigate(ScanTokenScreenDestination) },
    )
}

@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.COUNTRY_PICKER)])
@Composable
fun CountryPickerSheet(productId: String, navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    var query by rememberSaveable { mutableStateOf("") }
    CountryPickerContent(
        selected = app.forms.idDetails.country,
        query = query,
        onQueryChange = { query = it },
        onSelect = { app.forms.setCountry(it); navigator.navigateUp() },
        onDismissRequest = { navigator.navigateUp() },
    )
}

@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.ID_TYPE_PICKER)])
@Composable
fun IdTypePickerSheet(productId: String, navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    var query by rememberSaveable { mutableStateOf("") }
    IdTypePickerContent(
        country = app.forms.idDetails.country,
        selected = app.forms.idDetails.idType,
        query = query,
        onQueryChange = { query = it },
        onSelect = { app.forms.setIdType(it); navigator.navigateUp() },
        onDismissRequest = { navigator.navigateUp() },
    )
}

private fun productOf(productId: String) = UseSmileIDSampleProduct.entries.firstOrNull { it.id == productId }

@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.PROFILE_SWITCH)])
@Composable
fun ProfileSwitchSheet(navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    ProfileSwitchContent(
        profiles = app.profiles.all,
        activeId = app.profiles.activeId,
        onSelect = { app.profiles.setActive(it.id); navigator.navigateUp() },
        onDismissRequest = { navigator.navigateUp() },
    )
}

@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.PROFILES)])
@Composable
fun ProfilesScreen(navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    ProfilesContent(
        profiles = app.profiles.all,
        activeId = app.profiles.activeId,
        onProfileClick = { navigator.navigate(ProfileConfigScreenDestination(profileId = it.id)) },
        onCreate = { navigator.navigate(NewProfileSheetDestination) },
        onBack = { navigator.navigateUp() },
    )
}

@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.PROFILE_CONFIG)])
@Composable
fun ProfileConfigScreen(profileId: String, navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    val profile = app.profiles.find(profileId)
    var defaults by rememberSaveable(profileId, saver = UseSmileIDSampleUserDetails.Saver) {
        mutableStateOf(profile?.defaults ?: UseSmileIDSampleUserDetails())
    }
    ProfileConfigContent(
        organisation = profile?.organisation ?: profileId,
        defaults = defaults,
        onFieldChange = { field, value -> defaults = field.write(defaults, value) },
        onBack = { navigator.navigateUp() },
        onSave = {
            app.profiles.setDefaults(profileId, defaults)
            navigator.navigateUp()
        },
    )
}

@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.NEW_PROFILE)])
@Composable
fun NewProfileSheet(navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    var name by rememberSaveable { mutableStateOf("") }
    NewProfileContent(
        name = name,
        onNameChange = { name = it },
        onSave = { app.profiles.add(organisation = name, person = ""); navigator.navigateUp() },
        onDismissRequest = { navigator.navigateUp() },
    )
}

@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.SCAN_TOKEN)])
@Composable
fun ScanTokenScreen(navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    ScanTokenContent(
        onBack = { navigator.navigateUp() },
        onPaste = {},
        onSimulate = {
            // On the app-level scope, so leaving this screen cannot cancel the write half-done.
            app.storeScope.launch {
                app.store.linkTokenSession(
                    id = SIMULATED_SESSION_ID,
                    expiresAtMillis = System.currentTimeMillis() +
                        UseSmileIDSampleTokenSession.DEFAULT_DURATION.inWholeMilliseconds,
                )
            }
            navigator.navigateUp()
        },
    )
}

@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.SCENARIO_DRAWER)])
@Composable
fun ScenarioDrawerSheet(navigator: DestinationsNavigator) {
    // App-level, not sheet-local: the result card reports the same selection.
    val app = LocalUseSmileIDSampleAppState.current
    ScenarioDrawerContent(
        activeScenario = app.flowResult.scenario,
        activeTheme = app.flowResult.theme,
        onScenarioSelect = app.flowResult::selectScenario,
        onThemeSelect = app.flowResult::selectTheme,
        onDismissRequest = { navigator.navigateUp() },
    )
}

/** Dev-only, and a shell route by design: `sample-ui` never holds a gallery or a scratchpad. */
@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.COMPONENT_GALLERY)])
@Composable
fun ComponentGalleryScreen() = ComponentGalleryContent()

private const val SIMULATED_SESSION_ID = "9f3a"
private const val UNDO_WINDOW_MILLIS = 5_000L
private const val APP_DISPLAY_NAME = "UseSmileID Sample"
