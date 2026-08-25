package com.usesmileid.sampleapps.android.navigation

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.runtime.Composable
import com.ramcosta.composedestinations.annotation.Destination
import com.ramcosta.composedestinations.annotation.parameters.DeepLink
import com.ramcosta.composedestinations.generated.destinations.ProfilesScreenDestination
import com.ramcosta.composedestinations.generated.destinations.ScenarioDrawerSheetDestination
import com.ramcosta.composedestinations.navigation.DestinationsNavigator
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.android.BuildConfig
import com.usesmileid.sampleapps.android.LocalUseSmileIDSampleAppState
import com.usesmileid.sampleapps.android.flow.tokenBindsConsent
import com.usesmileid.sampleapps.ui.components.avatarColorForProfile
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleSettingsState
import kotlinx.coroutines.launch
import com.usesmileid.sampleapps.ui.screens.SettingsScreen as SettingsContent

/** The settings tab's route. Function names are load-bearing: KSP names each generated `…Destination` after the function. */

@Destination<SettingsGraph>(start = true, deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.SETTINGS)])
@Composable
fun SettingsScreen(navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    val chrome = LocalUseSmileIDSampleChrome.current
    SettingsContent(
        contentPadding = PaddingValues(bottom = chrome.navBarHeight + SmileDimens.spacingMd),
        state = UseSmileIDSampleSettingsState(
            settings = app.settings,
            organisation = app.profiles.active.organisation,
            initials = app.profiles.active.initials,
            avatarColor = avatarColorForProfile(app.profiles.activeIndex),
            versionLabel = "$APP_DISPLAY_NAME · ${BuildConfig.VERSION_NAME}",
            consentBoundByToken = app.tokenBindsConsent,
        ),
        onSettingChange = { setting, enabled -> app.storeScope.launch { app.store.setSetting(setting, enabled) } },
        // The row opens the list: configuring any profile and creating one are both reached from there.
        onProfileClick = { navigator.navigate(ProfilesScreenDestination) },
        onNavRowClick = {},
        onOpenScenarioDrawer = { navigator.navigate(ScenarioDrawerSheetDestination) },
        onSignOut = {},
    )
}

private const val APP_DISPLAY_NAME = "UseSmileID Sample"
