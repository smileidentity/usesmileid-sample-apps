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

    // The drawer's own root; its opener is a separate id, matching every other sheet and opener.
    const val SCENARIO_DRAWER = "sample_scenario_drawer"
    const val SCENARIO_DRAWER_BUTTON = "sample_scenario_drawer_button"

    const val PROFILE_SUMMARY = "sample_profile_summary"
    const val SETTING_SMILE_TO_CAPTURE = "sample_setting_smile_to_capture"
    const val SETTING_AGENT_MODE = "sample_setting_agent_mode"
    const val SETTING_DARK_MODE = "sample_setting_dark_mode"
    const val SETTING_CONSENT_STEP = "sample_setting_consent_step"
    const val SETTING_INSTRUCTIONS_STEP = "sample_setting_instructions_step"
    const val SETTING_PREVIEW_STEP = "sample_setting_preview_step"
    const val SIGN_OUT = "sample_sign_out"
    const val VERSION_LABEL = "sample_version_label"

    // Attached by the component itself: the spec assigns these to it, not to a screen.
    const val TOAST = "sample_toast"
    const val TOAST_UNDO = "sample_toast_undo"
    const val SELECTION_BAR = "sample_selection_bar"
    const val SELECTION_COUNT = "sample_selection_count"
    const val SELECTION_REMOVE = "sample_selection_remove"
    const val JOB_ROW_STATUS = "sample_job_row_status"
    const val SESSION_CARD = "sample_session_card"
    const val SESSION_COUNTDOWN = "sample_session_countdown"
    const val SESSION_ENDED_BANNER = "sample_session_ended_banner"
    const val ENV_CHIP = "sample_env_chip"
    const val PROFILE_AVATAR_BUTTON = "sample_profile_avatar_button"
    const val TOKEN_FLOAT = "sample_token_float"
    const val TOKEN_MANUAL_ENTRY = "sample_token_manual_entry"
    const val TOKEN_PASTE = "sample_token_paste"
    const val TOKEN_SIMULATE = "sample_token_simulate"

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
        SELECTION_BAR,
        SELECTION_COUNT,
        SELECTION_REMOVE,
        JOB_ROW_STATUS,
        SESSION_CARD,
        SESSION_COUNTDOWN,
        SESSION_ENDED_BANNER,
        ENV_CHIP,
        PROFILE_AVATAR_BUTTON,
        TOKEN_FLOAT,
        TOKEN_MANUAL_ENTRY,
        TOKEN_PASTE,
        TOKEN_SIMULATE,
        SCENARIO_DRAWER_BUTTON,
        PROFILE_SUMMARY,
        SETTING_SMILE_TO_CAPTURE,
        SETTING_AGENT_MODE,
        SETTING_DARK_MODE,
        SETTING_CONSENT_STEP,
        SETTING_INSTRUCTIONS_STEP,
        SETTING_PREVIEW_STEP,
        SIGN_OUT,
        VERSION_LABEL,
    )

    /** Suffixed ids derive from other spec files, so they are built rather than listed. */
    fun productCard(productId: String) = "sample_product_card_$productId"

    fun settingNav(rowId: String) = "sample_setting_nav_$rowId"

    fun scenarioItem(scenarioId: String) = "sample_scenario_item_$scenarioId"

    fun themeItem(themeId: String) = "sample_theme_item_$themeId"
}
