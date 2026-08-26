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
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import com.usesmileid.sampleapps.ui.screens.NewProfileSheet as NewProfileContent
import com.usesmileid.sampleapps.ui.screens.ProfileConfigScreen as ProfileConfigContent
import com.usesmileid.sampleapps.ui.screens.ProfileSwitchSheet as ProfileSwitchContent
import com.usesmileid.sampleapps.ui.screens.ProfilesScreen as ProfilesContent

/** The profile routes. Function names are load-bearing: KSP names each generated `…Destination` after the function. */

/** A layer Products owns; it is not a destination (R12). */
@Composable
internal fun ProfileSwitchSheet(onDismissRequest: () -> Unit) {
    val app = LocalUseSmileIDSampleAppState.current
    ProfileSwitchContent(
        profiles = app.profiles.all,
        activeId = app.profiles.activeId,
        onSelect = { app.profiles.setActive(it.id); onDismissRequest() },
        onDismissRequest = onDismissRequest,
    )
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
            message = "${created.organisation} created",
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

/** A layer the profiles list owns; it is not a destination (R12). */
@Composable
internal fun NewProfileSheet(onDismissRequest: () -> Unit) {
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
            onDismissRequest()
        },
        onDismissRequest = onDismissRequest,
    )
}
