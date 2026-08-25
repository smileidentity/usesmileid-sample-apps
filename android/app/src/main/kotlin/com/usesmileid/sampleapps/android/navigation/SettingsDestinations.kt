package com.usesmileid.sampleapps.android.navigation

import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Intent
import android.util.Log
import androidx.browser.customtabs.CustomTabColorSchemeParams
import androidx.browser.customtabs.CustomTabsClient
import androidx.browser.customtabs.CustomTabsIntent
import androidx.browser.customtabs.CustomTabsServiceConnection
import androidx.browser.customtabs.CustomTabsSession
import androidx.core.net.toUri
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.ProvidableCompositionLocal
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.toArgb
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
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleSettingsState
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
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
    val openUrl = LocalUseSmileIDSampleUrlOpener.current
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
            row.url?.let { openUrl(it, row.id, row.opensInApp) } ?: navigator.navigate(LicensesScreenDestination)
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
    val openUrl = LocalUseSmileIDSampleUrlOpener.current
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
        onOpenUrl = { url -> openUrl(url, "licenses", true) },
    )
}

/** Opens a settings link: `(url, label, inApp)`. */
typealias UseSmileIDSampleUrlOpener = (url: String, label: String, inApp: Boolean) -> Unit

/** Provided once by the shell: a `remember` in each screen bound a second Custom Tabs service. */
val LocalUseSmileIDSampleUrlOpener: ProvidableCompositionLocal<UseSmileIDSampleUrlOpener> =
    compositionLocalOf { error("No UseSmileIDSampleUrlOpener provided") }

/** Provides [LocalUseSmileIDSampleUrlOpener] for [content]. */
@Composable
fun ProvideUseSmileIDSampleUrlOpener(content: @Composable () -> Unit) =
    CompositionLocalProvider(LocalUseSmileIDSampleUrlOpener provides rememberUrlOpener(), content = content)

/** A Custom Tab where the page renders in one, the browser where it does not. Never a WebView. */
@Composable
private fun rememberUrlOpener(): UseSmileIDSampleUrlOpener {
    val context = LocalContext.current
    val session = rememberWarmCustomTabsSession()
    // Per scheme: one shared colour left a white bar on a white page in light mode.
    val light = UseSmileIDSampleTheme.colors.primary.toArgb()
    val dark = UseSmileIDSampleTheme.colors.surface.toArgb()
    return { url, label, inApp ->
        try {
            if (inApp) {
                val tab = CustomTabsIntent.Builder(session)
                    .setColorSchemeParams(CustomTabsIntent.COLOR_SCHEME_LIGHT, toolbar(light))
                    .setColorSchemeParams(CustomTabsIntent.COLOR_SCHEME_DARK, toolbar(dark))
                    .setShowTitle(true)
                    .build()
                // Browsers only: an implicit view intent is open to any app claiming the domain.
                tab.intent.addCategory(Intent.CATEGORY_BROWSABLE)
                tab.launchUrl(context, url.toUri())
            } else {
                context.startActivity(
                    Intent(Intent.ACTION_VIEW, url.toUri()).apply {
                        addCategory(Intent.CATEGORY_BROWSABLE)
                        // Its own task: ejecting means the page is not part of this app's history.
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    },
                )
            }
        } catch (e: ActivityNotFoundException) {
            // A device with no browser at all is a real configuration; a crash is worse than a log.
            Log.w("UseSmileIDSample", "No activity could open $label", e)
        }
    }
}

private fun toolbar(color: Int) = CustomTabColorSchemeParams.Builder().setToolbarColor(color).build()

/**
 * Warms the browser so the first tab paints rather than appearing empty. `warmup()` only:
 * pre-fetching would spend a partner's data on a link they may never tap.
 */
@Composable
private fun rememberWarmCustomTabsSession(): CustomTabsSession? {
    val context = LocalContext.current
    var session by remember { mutableStateOf<CustomTabsSession?>(null) }
    DisposableEffect(context) {
        val browser = CustomTabsClient.getPackageName(context, null)
        val connection = object : CustomTabsServiceConnection() {
            override fun onCustomTabsServiceConnected(name: ComponentName, client: CustomTabsClient) {
                client.warmup(0)
                session = client.newSession(null)
            }

            override fun onServiceDisconnected(name: ComponentName) {
                session = null
            }
        }
        val bound = browser != null && CustomTabsClient.bindCustomTabsService(context, browser, connection)
        onDispose {
            if (bound) context.unbindService(connection)
            session = null
        }
    }
    return session
}

// Brand copy rather than the launcher label — see spec/app-identity.json.
private const val APP_DISPLAY_NAME = "Smile ID Sample App"

private const val LICENSES_ASSET = "licenses.json"
