package com.usesmileid.sampleapps.android.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.ramcosta.composedestinations.annotation.Destination
import com.ramcosta.composedestinations.annotation.RootGraph
import com.ramcosta.composedestinations.annotation.parameters.DeepLink
import com.ramcosta.composedestinations.generated.destinations.ProfileConfigScreenDestination
import com.ramcosta.composedestinations.navigation.DestinationsNavigator
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.android.LocalUseSmileIDSampleAppState
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTransientNoticeHost
import com.usesmileid.sampleapps.ui.components.rememberTransientNotice
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleProfile
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import com.usesmileid.sampleapps.ui.state.callbackOverrideCaption
import com.usesmileid.sampleapps.ui.screens.NewProfileSheet as NewProfileContent
import com.usesmileid.sampleapps.ui.screens.ProfileConfigScreen as ProfileConfigContent
import com.usesmileid.sampleapps.ui.screens.ProfileSwitchSheet as ProfileSwitchContent
import com.usesmileid.sampleapps.ui.screens.ProfilesScreen as ProfilesContent

/** The profile routes. Function names are load-bearing: KSP names each generated `…Destination` after the function. */

/** A layer Products and the user-details form own; it is not a destination (R12). */
@Composable
internal fun ProfileSwitchSheet(
    onDismissRequest: () -> Unit,
    /** The profile now active, picked or just created, so a form showing its details can refill. */
    onPicked: (UseSmileIDSampleProfile) -> Unit = {},
    /** What a form had typed, so a profile created from it is not typed twice. */
    draft: UseSmileIDSampleUserDetails = UseSmileIDSampleUserDetails(),
    draftOrganisation: String = "",
) {
    val app = LocalUseSmileIDSampleAppState.current
    var creating by rememberSaveable { mutableStateOf(false) }
    if (creating) {
        // Active at once: whoever opened this sheet was choosing who to run as.
        NewProfileSheet(
            onDismissRequest = onDismissRequest,
            activate = true,
            onCreated = onPicked,
            draft = draft,
            draftOrganisation = draftOrganisation,
        )
    } else {
        ProfileSwitchContent(
            profiles = app.profiles.all,
            activeId = app.profiles.activeId,
            onSelect = {
                app.profiles.setActive(it.id)
                onPicked(it)
                onDismissRequest()
            },
            onDismissRequest = onDismissRequest,
            onCreate = { creating = true },
        )
    }
}

@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.PROFILES)])
@Composable
fun ProfilesScreen(navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    val chrome = LocalUseSmileIDSampleChrome.current
    val notice = rememberTransientNotice()
    var creating by rememberUseSmileIDSampleSheetState(UseSmileIDSampleSheet.NewProfile)
    val pendingId = app.profiles.lastCreatedId
    // Consumed on sight, so returning cannot re-show it.
    LaunchedEffect(pendingId) {
        val id = pendingId ?: return@LaunchedEffect
        app.profiles.clearLastCreated()
        val created = app.profiles.find(id) ?: return@LaunchedEffect
        // A new profile is not made active by creating it, so the confirmation carries the offer.
        notice.show(
            message = "${created.title} created",
            actionLabel = "Make active",
            onAction = { app.profiles.setActive(created.id) },
        )
    }
    Box(modifier = Modifier.fillMaxSize()) {
        ProfilesContent(
            contentPadding = PaddingValues(bottom = chrome.navBarHeight + SmileDimens.spacingMd),
            profiles = app.profiles.all,
            activeId = app.profiles.activeId,
            onProfileClick = { navigator.navigate(ProfileConfigScreenDestination(profileId = it.id)) },
            onCreate = { creating = true },
            onBack = { navigator.navigateUp() },
        )
        // Composed only while open, so its five fields start empty each time.
        if (creating) NewProfileSheet(onDismissRequest = { creating = false })
        UseSmileIDSampleTransientNoticeHost(
            state = notice,
            // The host already inset this past the system bar; insetting again lifts it into the list.
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingLg),
        )
    }
}

@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.PROFILE_CONFIG)])
@Composable
fun ProfileConfigScreen(profileId: String, navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    var deleted by rememberSaveable(profileId) { mutableStateOf(false) }
    if (!app.profiles.loaded) return
    val profile = app.profiles.find(profileId)
    if (profile == null) {
        // A link to a profile this device does not hold goes back, rather than to an empty page; a delete already went.
        if (!deleted) LaunchedEffect(Unit) { navigator.navigateUp() }
        return
    }
    var name by rememberSaveable(profileId) { mutableStateOf(profile.organisation) }
    var defaults by rememberSaveable(profileId, saver = UseSmileIDSampleUserDetails.Saver) {
        mutableStateOf(profile.defaults)
    }
    var callbackUrl by rememberSaveable(profileId) { mutableStateOf(profile.callbackUrl) }
    ProfileConfigContent(
        organisation = profile.title,
        isActive = profileId == app.profiles.activeId,
        changed = name.trim() != profile.organisation || defaults != profile.defaults ||
            callbackUrl.trim() != profile.callbackUrl,
        name = name,
        onNameChange = { name = it },
        defaults = defaults,
        onFieldChange = { field, value -> defaults = field.write(defaults, value) },
        callbackUrl = callbackUrl,
        onCallbackUrlChange = { callbackUrl = it },
        callbackOverride = app.session?.callbackOverrideCaption(),
        onBack = { navigator.navigateUp() },
        onSave = {
            // On another profile the one action reads "Use this profile", so it saves and activates.
            app.profiles.update(profileId, organisation = name, defaults = defaults, callbackUrl = callbackUrl)
            app.profiles.setActive(profileId)
            navigator.navigateUp()
        },
        onDelete = {
            deleted = true
            app.profiles.delete(profileId)
            navigator.navigateUp()
        },
    )
}

/** A layer the profiles list and the switch sheet own; it is not a destination (R12). */
@Composable
internal fun NewProfileSheet(
    onDismissRequest: () -> Unit,
    activate: Boolean = false,
    onCreated: (UseSmileIDSampleProfile) -> Unit = {},
    draft: UseSmileIDSampleUserDetails = UseSmileIDSampleUserDetails(),
    draftOrganisation: String = "",
) {
    val app = LocalUseSmileIDSampleAppState.current
    var name by rememberSaveable { mutableStateOf(draftOrganisation) }
    var firstName by rememberSaveable { mutableStateOf(draft.firstName) }
    var lastName by rememberSaveable { mutableStateOf(draft.lastName) }
    var email by rememberSaveable { mutableStateOf(draft.email) }
    var phone by rememberSaveable { mutableStateOf(draft.phone) }
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
            // All four seed the details its jobs start from; the two names are also who the profile names.
            val created = app.profiles.add(
                organisation = name,
                defaults = UseSmileIDSampleUserDetails(
                    firstName = firstName,
                    lastName = lastName,
                    email = email,
                    phone = phone,
                ),
                activate = activate,
            )
            onCreated(created)
            onDismissRequest()
        },
        onDismissRequest = onDismissRequest,
    )
}
