package com.usesmileid.sampleapps.android.navigation

/**
 * The deep-link URI for every route. Paths are shared across the four sample apps; the scheme is
 * per app, which is why these live in the shell and never in the shared UI module.
 */
internal object UseSmileIDSampleDeepLinks {
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
    // androidx ranks argument-free deep links first, so these beat /profiles/{profileId}.
    const val PROFILE_SWITCH = "$SCHEME://profiles/switch"
    const val NEW_PROFILE = "$SCHEME://profiles/new"
    const val PROFILE_CONFIG = "$SCHEME://profiles/{profileId}"

    const val SCAN_TOKEN = "$SCHEME://token/scan"
    const val SCENARIO_DRAWER = "$SCHEME://debug/scenarios"

    // A dev-only shell surface, so it is not in spec/routes.json. It still needs a link, because
    // reaching it cold is the only way a flow can drive it.
    const val COMPONENT_GALLERY = "$SCHEME://debug/components"
}
