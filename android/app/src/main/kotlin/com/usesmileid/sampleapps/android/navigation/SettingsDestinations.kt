package com.usesmileid.sampleapps.android.navigation

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.platform.LocalContext
import com.ramcosta.composedestinations.annotation.Destination
import com.ramcosta.composedestinations.annotation.parameters.DeepLink
import com.ramcosta.composedestinations.generated.NavGraphs
import com.ramcosta.composedestinations.generated.destinations.LicensesScreenDestination
import com.ramcosta.composedestinations.generated.destinations.ProfilesScreenDestination
import com.ramcosta.composedestinations.generated.destinations.ScenarioDrawerSheetDestination
import com.ramcosta.composedestinations.generated.navgraphs.ProductsNavGraph
import com.ramcosta.composedestinations.navigation.DestinationsNavigator
import com.ramcosta.composedestinations.utils.startDestination
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.android.BuildConfig
import com.usesmileid.sampleapps.android.LocalUseSmileIDSampleAppState
import com.usesmileid.sampleapps.android.flow.tokenBindsConsent
import com.usesmileid.sampleapps.ui.components.avatarColorForProfile
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleLicenses
import com.usesmileid.sampleapps.ui.model.parseUseSmileIDSampleLicenses
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleNavRow
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleSettingsState
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import com.usesmileid.sampleapps.ui.screens.LicensesScreen as LicensesContent
import com.usesmileid.sampleapps.ui.screens.SettingsScreen as SettingsContent

/** The settings tab's route. Function names are load-bearing: KSP names each generated `…Destination` after the function. */

@Destination<SettingsGraph>(start = true, deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.SETTINGS)])
@Composable
fun SettingsScreen(navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    val chrome = LocalUseSmileIDSampleChrome.current
    val context = LocalContext.current
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
        // Every row but Open-source licenses opens externally; that one is a screen in this app.
        onNavRowClick = { row ->
            row.url?.let { context.openExternally(it, row) } ?: navigator.navigate(LicensesScreenDestination)
        },
        // Debug builds only, and no launch argument reveals it: every flow reaches the drawer by deep link.
        onOpenScenarioDrawer = if (BuildConfig.DEBUG) {
            { navigator.navigate(ScenarioDrawerSheetDestination) }
        } else {
            null
        },
        // There is no auth to leave, so signing out is the local state a partner would expect gone.
        onSignOut = {
            app.storeScope.launch { app.store.clearTokenSession() }
            app.forms.clear()
            // The nav bar's own tab switch, so the stack lands where selecting Products would.
            navigator.navigate(ProductsNavGraph) {
                popUpTo(NavGraphs.root.startDestination) { saveState = true }
                launchSingleTop = true
                restoreState = true
            }
        },
    )
}

/** The notices screen. Its asset is read here and handed in, so the screen stays a function of its arguments. */
@Destination<SettingsGraph>(deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.LICENSES)])
@Composable
fun LicensesScreen(navigator: DestinationsNavigator) {
    val context = LocalContext.current
    val chrome = LocalUseSmileIDSampleChrome.current
    // Off the main thread: the asset is the Apache-2.0 text plus two hundred entries.
    val licenses by produceState(UseSmileIDSampleLicenses(), context) {
        value = withContext(Dispatchers.IO) {
            runCatching {
                context.assets.open(LICENSES_ASSET).bufferedReader().use { it.readText() }
            }.map(::parseUseSmileIDSampleLicenses).getOrElse { UseSmileIDSampleLicenses() }
        }
    }
    LicensesContent(
        licenses = licenses,
        contentPadding = PaddingValues(bottom = chrome.navBarHeight + SmileDimens.spacingMd),
        onBack = { navigator.navigateUp() },
        onOpenUrl = { url -> context.openExternally(url, licenseRow) },
    )
}

/** A plain view intent, not a Custom Tab: that needs `androidx.browser`, and this repo asks before adding one. */
private fun Context.openExternally(url: String, row: UseSmileIDSampleNavRow) {
    try {
        startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
    } catch (e: ActivityNotFoundException) {
        // A device with no browser is a real configuration; a crash is a worse answer than a log.
        Log.w("UseSmileIDSample", "No activity could open the ${row.id} row", e)
    }
}

// Brand copy rather than the launcher label — see spec/app-identity.json.
private const val APP_DISPLAY_NAME = "Smile ID Sample App"

private const val LICENSES_ASSET = "licenses.json"

// Names the surface a failed open came from, the way the settings rows do.
private val licenseRow = UseSmileIDSampleNavRow(id = "licenses", title = "Open-source licenses")
