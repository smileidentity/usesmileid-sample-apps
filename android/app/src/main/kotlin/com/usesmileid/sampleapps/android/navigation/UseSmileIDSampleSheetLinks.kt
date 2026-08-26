package com.usesmileid.sampleapps.android.navigation

import android.content.Intent
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.core.net.toUri
import androidx.navigation.NavHostController

/**
 * A sheet is a LAYER over the screen that owns it, never a destination that replaces it — R12 in
 * `docs/plan/navigation-plan.md`, because a destination leaves the scrim covering a grey void. The five
 * sheet paths in `spec/routes.json` stay deep-linkable: each resolves to its owner's own link plus a
 * request the owner picks up.
 */
internal enum class UseSmileIDSampleSheet {
    ProfileSwitch,
    NewProfile,
    ScenarioDrawer,
    CountryPicker,
    IdTypePicker,
}

internal data class UseSmileIDSampleSheetLink(val sheet: UseSmileIDSampleSheet, val ownerUri: String)

/** String in, string out, so `spec/routes.json` can assert the whole table without a device. */
internal object UseSmileIDSampleSheetLinks {

    /** Null for every other link, which the graph still claims itself. */
    fun resolve(link: String): UseSmileIDSampleSheetLink? {
        // Dropped, not carried: `probes` reaches the app off the launching intent, not off the route.
        val uri = link.substringBefore('?').substringBefore('#')
        FIXED[uri]?.let { return it }
        val sheet = PICKERS[uri.substringAfterLast('/')] ?: return null
        val owner = uri.substringBeforeLast('/')
        return if (owner.matches(ID_DETAILS)) UseSmileIDSampleSheetLink(sheet, owner) else null
    }

    /** Owners that share no path with their sheet, so the pairing has to be stated. */
    private val FIXED = mapOf(
        UseSmileIDSampleDeepLinks.PROFILE_SWITCH to
            UseSmileIDSampleSheetLink(UseSmileIDSampleSheet.ProfileSwitch, UseSmileIDSampleDeepLinks.PRODUCTS),
        UseSmileIDSampleDeepLinks.NEW_PROFILE to
            UseSmileIDSampleSheetLink(UseSmileIDSampleSheet.NewProfile, UseSmileIDSampleDeepLinks.PROFILES),
        UseSmileIDSampleDeepLinks.SCENARIO_DRAWER to
            UseSmileIDSampleSheetLink(UseSmileIDSampleSheet.ScenarioDrawer, UseSmileIDSampleDeepLinks.SETTINGS),
    )

    /** The pickers hang off the form's own path, so their owner is the link minus its last segment. */
    private val PICKERS = mapOf(
        UseSmileIDSampleDeepLinks.COUNTRY_PICKER.substringAfterLast('/') to UseSmileIDSampleSheet.CountryPicker,
        UseSmileIDSampleDeepLinks.ID_TYPE_PICKER.substringAfterLast('/') to UseSmileIDSampleSheet.IdTypePicker,
    )

    /** Built from the constant so a renamed path cannot leave this behind. */
    private val ID_DETAILS = UseSmileIDSampleDeepLinks.ID_DETAILS_FORM.split(PRODUCT_ID).let { (head, tail) ->
        Regex(Regex.escape(head) + "[^/]+" + Regex.escape(tail))
    }
}

/** Opens the owner exactly as its own link would, then asks it for the sheet. */
internal fun NavHostController.openUseSmileIDSampleSheet(
    link: UseSmileIDSampleSheetLink,
    requests: UseSmileIDSampleSheetRequests,
) {
    val owner = link.ownerUri.toUri()
    val here = currentDestination
    // Already there on a cold link to a tab root, and re-handling would replace the screen the sheet
    // layers over. Argument-free only: the same pattern with a different argument is another screen.
    val alreadyThere = here != null && here.arguments.isEmpty() && here.hasDeepLink(owner)
    if (alreadyThere || handleDeepLink(Intent(Intent.ACTION_VIEW, owner))) requests.request(link.sheet)
}

/** Held above the graph because the screen that owns the sheet is not composed yet when the link arrives. */
internal class UseSmileIDSampleSheetRequests {
    var pending: UseSmileIDSampleSheet? by mutableStateOf(null)
        private set

    fun request(sheet: UseSmileIDSampleSheet) {
        pending = sheet
    }

    /** Consumed on sight, so returning to the owner cannot replay a sheet the link already opened. */
    fun consume(sheet: UseSmileIDSampleSheet): Boolean {
        if (pending != sheet) return false
        pending = null
        return true
    }
}

internal val LocalUseSmileIDSampleSheetRequests = compositionLocalOf { UseSmileIDSampleSheetRequests() }

/** Whether the owner is showing [sheet]. Saveable, so a rotation with the sheet open keeps it open. */
@Composable
internal fun rememberUseSmileIDSampleSheetState(sheet: UseSmileIDSampleSheet): MutableState<Boolean> {
    val requests = LocalUseSmileIDSampleSheetRequests.current
    val open = rememberSaveable { mutableStateOf(false) }
    // Keyed on the request, not run once: a link can arrive before or after this screen composes.
    LaunchedEffect(requests.pending) { if (requests.consume(sheet)) open.value = true }
    return open
}

private const val PRODUCT_ID = "{productId}"
