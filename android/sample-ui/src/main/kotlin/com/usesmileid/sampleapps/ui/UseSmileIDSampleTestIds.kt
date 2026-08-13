package com.usesmileid.sampleapps.ui

/** The accessibility ids this module attaches. Stable forever: deprecate, never rename. */
object UseSmileIDSampleTestIds {
    const val NAV_PRODUCTS = "sample_nav_products"
    const val NAV_VERIFICATIONS = "sample_nav_verifications"
    const val NAV_SETTINGS = "sample_nav_settings"
    const val NAV_TOKEN = "sample_nav_token"

    const val PRODUCTS_SCREEN = "sample_products_screen"
    const val VERIFICATIONS_SCREEN = "sample_verifications_screen"
    const val VERIFICATION_DETAILS_SCREEN = "sample_verification_details_screen"
    const val SETTINGS_SCREEN = "sample_settings_screen"
    const val USER_DETAILS_SCREEN = "sample_user_details_screen"
    const val KYC_FORM_SCREEN = "sample_kyc_form_screen"
    const val COUNTRY_SHEET = "sample_country_sheet"
    const val ID_TYPE_SHEET = "sample_idtype_sheet"
    const val PROFILE_SWITCH_SHEET = "sample_profile_switch_sheet"
    const val PROFILES_SCREEN = "sample_profiles_screen"
    const val PROFILE_CONFIG_SCREEN = "sample_profile_config_screen"
    const val NEW_PROFILE_SHEET = "sample_new_profile_sheet"
    const val SCAN_TOKEN_SCREEN = "sample_scan_token_screen"
    const val SCENARIO_DRAWER = "sample_scenario_drawer"

    // Attached by the toast itself; the spec assigns these to the component rather than to a screen.
    const val TOAST = "sample_toast"
    const val TOAST_UNDO = "sample_toast_undo"

    val all = listOf(
        NAV_PRODUCTS,
        NAV_VERIFICATIONS,
        NAV_SETTINGS,
        NAV_TOKEN,
        PRODUCTS_SCREEN,
        VERIFICATIONS_SCREEN,
        VERIFICATION_DETAILS_SCREEN,
        SETTINGS_SCREEN,
        USER_DETAILS_SCREEN,
        KYC_FORM_SCREEN,
        COUNTRY_SHEET,
        ID_TYPE_SHEET,
        PROFILE_SWITCH_SHEET,
        PROFILES_SCREEN,
        PROFILE_CONFIG_SCREEN,
        NEW_PROFILE_SHEET,
        SCAN_TOKEN_SCREEN,
        SCENARIO_DRAWER,
        TOAST,
        TOAST_UNDO,
    )
}
