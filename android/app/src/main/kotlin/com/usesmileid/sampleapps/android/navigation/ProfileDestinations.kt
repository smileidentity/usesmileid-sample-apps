package com.usesmileid.sampleapps.android.navigation

import com.usesmileid.njia.stepOf

import androidx.compose.ui.res.stringResource
import com.usesmileid.sampleapps.ui.R
import androidx.compose.ui.platform.LocalResources
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

/** The profile steps: the switch sheet, the profiles list, one profile's configuration and the new-profile sheet. */

/** The profile switch over Products or the user-details form, which refills from the profile picked or created. */
@Composable
internal fun ProfileSwitchSheet(scope: UseSmileIDSampleStepScope) {
    val app = LocalUseSmileIDSampleAppState.current
    val engine = LocalUseSmileIDSampleEngine.current
    var creating by rememberSaveable { mutableStateOf(false) }
    if (!app.profiles.loaded) return
    val entries = engine.state.entries
    val under = entries.getOrNull(entries.indexOfFirst { it.id == scope.entry.id } - 1)
    val onPicked: (UseSmileIDSampleProfile) -> Unit = { picked ->
        if (under != null && engine.stepOf(under).kind == UseSmileIDSampleStep.ConsentDetailsForm) app.forms.fillFrom(picked)
    }
    if (creating) {
        NewProfileForm(onDismissRequest = scope.navigator::back, activate = true, onCreated = onPicked)
    } else {
        ProfileSwitchContent(
            profiles = app.profiles.all,
            activeId = app.profiles.activeId,
            onSelect = {
                app.profiles.setActive(it.id)
                onPicked(it)
                scope.navigator.back()
            },
            onDismissRequest = scope.navigator::back,
            onCreate = { creating = true },
        )
    }
}

/** Every profile, reached from Settings. */
@Composable
internal fun ProfilesScreen(scope: UseSmileIDSampleStepScope) {
    val app = LocalUseSmileIDSampleAppState.current
    val chrome = LocalUseSmileIDSampleChrome.current
    val notice = rememberTransientNotice()
    val pendingId = app.profiles.lastCreatedId
    val resources = LocalResources.current
    // Consumed on sight, so returning cannot re-show it.
    LaunchedEffect(pendingId) {
        val id = pendingId ?: return@LaunchedEffect
        app.profiles.clearLastCreated()
        val created = app.profiles.find(id) ?: return@LaunchedEffect
        // A new profile is not made active by creating it, so the confirmation carries the offer.
        notice.show(
            message = resources.getString(R.string.sample_profiles_created, created.title(resources.getString(R.string.sample_profiles_unnamed))),
            actionLabel = resources.getString(R.string.sample_profiles_make_active),
            onAction = { app.profiles.setActive(created.id) },
        )
    }
    Box(modifier = Modifier.fillMaxSize()) {
        ProfilesContent(
            contentPadding = PaddingValues(bottom = chrome.navBarHeight + SmileDimens.spacingMd),
            profiles = app.profiles.all,
            activeId = app.profiles.activeId,
            onProfileClick = { scope.navigator.go(UseSmileIDSampleStep.ProfileConfig, arg = it.id) },
            onCreate = { scope.navigator.go(UseSmileIDSampleStep.NewProfile) },
            onBack = scope.navigator::back,
        )
        UseSmileIDSampleTransientNoticeHost(
            state = notice,
            // The host already inset this past the system bar; insetting again lifts it into the list.
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingLg),
        )
    }
}

/** One profile's configuration, the profile its argument names. */
@Composable
internal fun ProfileConfigScreen(scope: UseSmileIDSampleStepScope) {
    val app = LocalUseSmileIDSampleAppState.current
    val profileId = scope.entry.arg.orEmpty()
    var deleted by rememberSaveable(profileId) { mutableStateOf(false) }
    if (!app.profiles.loaded) return
    val profile = app.profiles.find(profileId)
    if (profile == null) {
        if (!deleted) LaunchedEffect(Unit) { scope.navigator.back() }
        return
    }
    var name by rememberSaveable(profileId) { mutableStateOf(profile.organisation) }
    var defaults by rememberSaveable(profileId, saver = UseSmileIDSampleUserDetails.Saver) {
        mutableStateOf(profile.defaults)
    }
    var callbackUrl by rememberSaveable(profileId) { mutableStateOf(profile.callbackUrl) }
    ProfileConfigContent(
        title = profile.title,
        isActive = profileId == app.profiles.activeId,
        changed = name.trim() != profile.organisation || defaults != profile.defaults ||
            callbackUrl.trim() != profile.callbackUrl,
        organisation = name,
        onOrganisationChange = { name = it },
        defaults = defaults,
        onFieldChange = { field, value -> defaults = field.write(defaults, value) },
        callbackUrl = callbackUrl,
        onCallbackUrlChange = { callbackUrl = it },
        callbackOverride = app.session?.callbackOverrideCaption()?.let { stringResource(it) },
        onBack = scope.navigator::back,
        onSave = {
            app.profiles.update(profileId, organisation = name, defaults = defaults, callbackUrl = callbackUrl)
            app.profiles.setActive(profileId)
            scope.navigator.back()
        },
        onDelete = {
            deleted = true
            app.profiles.delete(profileId)
            scope.navigator.back()
        },
    )
}

/** The new-profile sheet over the profiles list; its five fields start empty each time it opens. */
@Composable
internal fun NewProfileSheet(scope: UseSmileIDSampleStepScope) {
    NewProfileForm(onDismissRequest = scope.navigator::back)
}

/** The new-profile form, as its own sheet or in the switch sheet's place. */
@Composable
private fun NewProfileForm(
    onDismissRequest: () -> Unit,
    activate: Boolean = false,
    onCreated: (UseSmileIDSampleProfile) -> Unit = {},
) {
    val app = LocalUseSmileIDSampleAppState.current
    var name by rememberSaveable { mutableStateOf("") }
    if (!app.profiles.loaded) return
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
