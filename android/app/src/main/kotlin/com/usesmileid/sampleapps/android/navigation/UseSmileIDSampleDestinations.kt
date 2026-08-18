package com.usesmileid.sampleapps.android.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
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
import com.ramcosta.composedestinations.generated.destinations.ProfilesScreenDestination
import com.ramcosta.composedestinations.generated.destinations.ScanTokenScreenDestination
import com.ramcosta.composedestinations.generated.destinations.ScenarioDrawerSheetDestination
import com.ramcosta.composedestinations.generated.destinations.VerificationDetailsScreenDestination
import com.ramcosta.composedestinations.navigation.DestinationsNavigator
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.android.BuildConfig
import com.usesmileid.sampleapps.android.LocalUseSmileIDSampleAppState
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleOverlay
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleToast
import com.usesmileid.sampleapps.ui.components.avatarColorForProfile
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
            avatarColor = avatarColorForProfile(app.profiles.activeIndex),
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
    // The count outlives the toast so it still reads correctly while the toast slides away; the
    // token restarts the window even when two removals in a row are the same size. Both are
    // deliberately NOT saveable: a saved token replays the confirmation every time you come back to
    // this screen, so opening a verification and pressing back re-showed a removal from minutes ago.
    var removedCount by remember { mutableIntStateOf(0) }
    var removalToken by remember { mutableIntStateOf(0) }

    // One path for both removals — the swipe and the selection bar — so they cannot drift apart.
    val removeJobs: (Set<String>) -> Unit = { ids ->
        app.jobs.remove(ids)
        removedCount = ids.size
        removalToken += 1
        selectMode = false
        // Emptying a filter otherwise leaves a blank screen under a chip reading 0.
        if (app.jobs.count(filter) == 0) filter = UseSmileIDSampleJobFilter.All
    }

    // Published to the shell rather than drawn here: the design replaces the nav bar with it.
    val chrome = LocalUseSmileIDSampleChrome.current
    LaunchedEffect(selectMode, selected) {
        chrome.selection = if (selectMode) {
            UseSmileIDSampleSelectionChrome(count = selected.size, onRemove = { removeJobs(selected) })
        } else {
            null
        }
    }
    DisposableEffect(Unit) { onDispose { chrome.selection = null } }

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
            // Cleared on the way IN, so the bar still shows its count while it slides away.
            onSelectModeChange = { selectMode = it; if (it) selected = emptySet() },
            onSelectionChange = { id, checked -> selected = if (checked) selected + id else selected - id },
            onJobClick = { navigator.navigate(VerificationDetailsScreenDestination(jobId = it.id)) },
            onRemove = removeJobs,
        )
        // Bounded, so a toast left up cannot restore rows long after the removal it belonged to.
        var removalShown by remember { mutableStateOf(false) }
        LaunchedEffect(removalToken) {
            if (removalToken == 0) return@LaunchedEffect
            removalShown = true
            delay(SNACKBAR_WINDOW_MILLIS)
            removalShown = false
        }
        UseSmileIDSampleOverlay(
            visible = removalShown,
            // The shell already inset this past the floating nav bar; insetting again lifts it into the list.
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingXxs),
        ) {
            UseSmileIDSampleToast(
                message = if (removedCount == 1) "Verification removed" else "$removedCount verifications removed",
                actionLabel = "Undo",
                onAction = { app.jobs.undoRemove(); removalShown = false },
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
        avatarColor = avatarColorForProfile(app.profiles.activeIndex),
        versionLabel = "$APP_DISPLAY_NAME · ${BuildConfig.VERSION_NAME}",
        // The row opens the list: configuring any profile and creating one are both reached from there.
        onProfileClick = { navigator.navigate(ProfilesScreenDestination) },
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

@Destination<RootGraph>(style = UseSmileIDSampleSheetTransitions::class, deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.COUNTRY_PICKER)])
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

@Destination<RootGraph>(style = UseSmileIDSampleSheetTransitions::class, deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.ID_TYPE_PICKER)])
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

@Destination<RootGraph>(style = UseSmileIDSampleSheetTransitions::class, deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.PROFILE_SWITCH)])
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
    // Consumed on sight, so leaving and returning cannot re-show an old confirmation. The window is
    // a second effect: clearing the store flips the first one's key, which would cancel its delay
    // before it ever reset, leaving the confirmation up for good.
    var confirmedId by remember { mutableStateOf<String?>(null) }
    var confirmationShown by remember { mutableStateOf(false) }
    val pendingId = app.profiles.lastCreatedId
    LaunchedEffect(pendingId) {
        val id = pendingId ?: return@LaunchedEffect
        app.profiles.clearLastCreated()
        confirmedId = id
        confirmationShown = true
    }
    LaunchedEffect(confirmedId) {
        if (confirmedId == null) return@LaunchedEffect
        delay(SNACKBAR_WINDOW_MILLIS)
        confirmationShown = false
    }
    val created = confirmedId?.let(app.profiles::find)
    Box(modifier = Modifier.fillMaxSize()) {
        ProfilesContent(
            profiles = app.profiles.all,
            activeId = app.profiles.activeId,
            onProfileClick = { navigator.navigate(ProfileConfigScreenDestination(profileId = it.id)) },
            onCreate = { navigator.navigate(NewProfileSheetDestination) },
            onBack = { navigator.navigateUp() },
        )
        // A new profile is not made active by creating it, so the confirmation carries the offer.
        UseSmileIDSampleOverlay(
            visible = confirmationShown && created != null,
            // The host already inset this past the system bar; insetting again lifts it into the list.
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingLg),
        ) {
            UseSmileIDSampleToast(
                message = "${created?.organisation.orEmpty()} created",
                actionLabel = "Make active",
                onAction = { created?.let { app.profiles.setActive(it.id) }; confirmationShown = false },
            )
        }
    }
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
        isActive = profileId == app.profiles.activeId,
        defaults = defaults,
        onFieldChange = { field, value -> defaults = field.write(defaults, value) },
        onBack = { navigator.navigateUp() },
        onSave = {
            // The CTA reads "Make this profile active", so it has to do both.
            app.profiles.setDefaults(profileId, defaults)
            app.profiles.setActive(profileId)
            navigator.navigateUp()
        },
    )
}

@Destination<RootGraph>(style = UseSmileIDSampleSheetTransitions::class, deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.NEW_PROFILE)])
@Composable
fun NewProfileSheet(navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    var name by rememberSaveable { mutableStateOf("") }
    var firstName by rememberSaveable { mutableStateOf("") }
    var lastName by rememberSaveable { mutableStateOf("") }
    var email by rememberSaveable { mutableStateOf("") }
    var phone by rememberSaveable { mutableStateOf("") }
    NewProfileContent(
        name = name,
        firstName = firstName,
        lastName = lastName,
        email = email,
        phone = phone,
        onNameChange = { name = it },
        onFirstNameChange = { firstName = it },
        onLastNameChange = { lastName = it },
        onEmailChange = { email = it },
        onPhoneChange = { phone = it },
        onSave = {
            // The person is the two required names; all four seed the details its jobs start from.
            app.profiles.add(
                organisation = name,
                person = "$firstName $lastName".trim(),
                defaults = UseSmileIDSampleUserDetails(
                    firstName = firstName,
                    lastName = lastName,
                    email = email,
                    phone = phone,
                ),
            )
            navigator.navigateUp()
        },
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

@Destination<RootGraph>(style = UseSmileIDSampleSheetTransitions::class, deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.SCENARIO_DRAWER)])
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
/** How long a snackbar with an action stays up: long enough to undo, short enough not to outlive its cause. */
private const val SNACKBAR_WINDOW_MILLIS = 5_000L
private const val APP_DISPLAY_NAME = "UseSmileID Sample"
