package com.usesmileid.sampleapps.android.navigation

/**
 * The deep-link URI for every route in `spec/routes.json`.
 *
 * Paths are identical across the four apps; the scheme is per app
 * (`spec/app-identity.json` → `usesmileid-sample-android`), which is why these live in the shell
 * and never in `sample-ui` — the same library runs under eight application identities.
 *
 * Every route must open **cold**, with the process not already running. Cold start is where
 * argument parsing and state restoration break; warm start works by accident.
 */
internal object SampleDeepLinks {
    const val SCHEME = "usesmileid-sample-android"

    const val PRODUCTS = "$SCHEME://products"
    const val VERIFICATIONS = "$SCHEME://verifications"
    const val VERIFICATION_DETAILS = "$SCHEME://verifications/{jobId}"
    const val SETTINGS = "$SCHEME://settings"

    const val CONSENT_DETAILS_FORM = "$SCHEME://flow/{productId}/details"
    const val ID_DETAILS_FORM = "$SCHEME://flow/{productId}/id-details"
    const val COUNTRY_PICKER = "$SCHEME://flow/{productId}/id-details/country"
    const val ID_TYPE_PICKER = "$SCHEME://flow/{productId}/id-details/id-type"
    const val SDK_FLOW = "$SCHEME://flow/{productId}/run?route={route}"

    const val PROFILES = "$SCHEME://profiles"
    // `/profiles/switch` and `/profiles/new` are matched ahead of `/profiles/{profileId}` because
    // androidx ranks an argument-free deep link above one with arguments — declaration order,
    // which the route table calls out for the other platforms, is not what decides it here.
    const val PROFILE_SWITCH = "$SCHEME://profiles/switch"
    const val NEW_PROFILE = "$SCHEME://profiles/new"
    const val PROFILE_CONFIG = "$SCHEME://profiles/{profileId}"

    const val SCAN_TOKEN = "$SCHEME://token/scan"
    const val SCENARIO_DRAWER = "$SCHEME://debug/scenarios"
}
