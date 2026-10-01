package com.usesmileid.sampleapps.ui

/** The accessibility ids this module attaches. Stable forever: deprecate, never rename. */
object UseSmileIDSampleTestIds {
    const val NAV_PRODUCTS = "sample_nav_products"
    const val NAV_VERIFICATIONS = "sample_nav_verifications"
    const val NAV_SETTINGS = "sample_nav_settings"
    const val NAV_TOKEN = "sample_nav_token"

    const val PRODUCTS_SCREEN = "sample_products_screen"
    const val VERIFICATIONS_SCREEN = "sample_verifications_screen"
    const val VERIFICATIONS_EMPTY = "sample_verifications_empty"
    const val DETAILS_EMPTY = "sample_details_empty"
    const val COUNTRY_EMPTY = "sample_country_empty"
    const val ID_TYPE_EMPTY = "sample_idtype_empty"
    const val DOCUMENT_EMPTY = "sample_document_empty"
    const val CATALOGUE_LOADING = "sample_catalogue_loading"
    const val CATALOGUE_ERROR = "sample_catalogue_error"
    const val CATALOGUE_RETRY = "sample_catalogue_retry"
    const val ID_NUMBER_ERROR = "sample_idnumber_error"
    const val DOCUMENT_TRIGGER = "sample_document_trigger"
    const val CAPTURE_AS_TRIGGER = "sample_capture_as_trigger"
    const val DOCUMENT_SHEET = "sample_document_sheet"
    const val DOCUMENT_SEARCH = "sample_document_search"
    const val CAPTURE_AS_SHEET = "sample_capture_as_sheet"
    const val GENERIC_DOCUMENT_SHEET = "sample_generic_document_sheet"
    const val GENERIC_DOCUMENT_NAME = "sample_generic_document_name"
    const val GENERIC_DOCUMENT_BACK_SIDE = "sample_generic_document_back_side"
    const val GENERIC_DOCUMENT_DONE = "sample_generic_document_done"
    const val SETTING_CAPTURE_MODE = "sample_setting_capture_mode"
    const val CAPTURE_MODE_SHEET = "sample_capture_mode_sheet"
    const val SETTING_GALLERY_UPLOAD = "sample_setting_gallery_upload"
    const val SETTING_CAPTURE_BOTH_SIDES = "sample_setting_capture_both_sides"
    const val SETTING_ALLOW_SKIP_BACK = "sample_setting_allow_skip_back"
    const val SETTING_SELFIE_FIRST = "sample_setting_selfie_first"
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
    const val LICENSES_SCREEN = "sample_licenses_screen"
    const val LICENSES_EMPTY = "sample_licenses_empty"

    // The drawer's own root; its opener is a separate id, matching every other sheet and opener.
    const val SCENARIO_DRAWER = "sample_scenario_drawer"
    const val SCENARIO_DRAWER_BUTTON = "sample_scenario_drawer_button"

    const val PROFILE_SUMMARY = "sample_profile_summary"
    const val SETTING_ENHANCED_SMART_SELFIE = "sample_setting_enhanced_smart_selfie"
    const val SETTING_AGENT_MODE = "sample_setting_agent_mode"
    const val SETTING_DARK_MODE = "sample_setting_dark_mode"
    const val SETTING_CONSENT_STEP = "sample_setting_consent_step"
    const val SETTING_INSTRUCTIONS_STEP = "sample_setting_instructions_step"
    const val SETTING_PREVIEW_STEP = "sample_setting_preview_step"
    const val SIGN_OUT = "sample_sign_out"
    const val SIGN_OUT_CONFIRM = "sample_sign_out_confirm"
    const val VERSION_LABEL = "sample_version_label"
    const val SELECT_TOGGLE = "sample_select_toggle"
    const val STATUS_BADGE = "sample_status_badge"
    const val DETAILS_REFRESH = "sample_details_refresh"
    const val DETAILS_DELETE = "sample_details_delete"
    const val USER_DETAILS_HINT = "sample_user_details_hint"
    const val REMEMBER_DETAILS_SWITCH = "sample_remember_details_switch"
    const val USER_DETAILS_PROFILE = "sample_user_details_profile"
    const val USER_DETAILS_CONTINUE = "sample_user_details_continue"
    const val COUNTRY_TRIGGER = "sample_country_trigger"
    const val ID_TYPE_TRIGGER = "sample_idtype_trigger"
    const val ID_NUMBER_INPUT = "sample_idnumber_input"
    const val KYC_CONTINUE = "sample_kyc_continue"
    const val COUNTRY_SEARCH = "sample_country_search"
    const val ID_TYPE_SEARCH = "sample_idtype_search"
    const val CREATE_PROFILE = "sample_create_profile"
    const val NEW_PROFILE_NAME = "sample_new_profile_name"
    const val NEW_PROFILE_FIRST_NAME = "sample_new_profile_first_name"
    const val NEW_PROFILE_LAST_NAME = "sample_new_profile_last_name"
    const val NEW_PROFILE_EMAIL = "sample_new_profile_email"
    const val NEW_PROFILE_PHONE = "sample_new_profile_phone"
    const val NEW_PROFILE_SAVE = "sample_new_profile_save"
    const val PROFILE_CONFIG_CALLBACK_URL = "sample_profile_config_callback_url"
    const val PROFILE_CONFIG_SAVE = "sample_profile_config_save"
    const val PROFILE_CONFIG_CONTACT_ERROR = "sample_profile_config_contact_error"
    const val PROFILE_CONFIG_NAME = "sample_profile_config_name"
    const val PROFILE_CONFIG_DELETE = "sample_profile_config_delete"
    const val PROFILE_DELETE_CONFIRM = "sample_profile_delete_confirm"
    const val PROFILE_SWITCH_NEW = "sample_profile_switch_new"

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
    const val TOKEN_PORTAL_LINK = "sample_token_portal_link"

    const val RESULT_CARD = "sample_result_card"
    const val RESULT_ACTIVE_SCENARIO = "sample_result_active_scenario"
    const val RESULT_ACTIVE_THEME = "sample_result_active_theme"
    const val RESULT_ROUTE = "sample_result_route"
    const val RESULT_ENVIRONMENT = "sample_result_environment"
    const val RESULT_JOB_ID = "sample_result_job_id"
    const val RESULT_USER_ID = "sample_result_user_id"
    const val RESULT_JOB_STATUS = "sample_result_job_status"
    const val RESULT_RESULT_COUNT = "sample_result_result_count"
    const val RESULT_REFRESH_COUNT = "sample_result_refresh_count"
    const val RESULT_LAST_ERROR = "sample_result_last_error"
    const val RESULT_SDK_VERSION = "sample_result_sdk_version"

    val all = listOf(
        NAV_PRODUCTS,
        NAV_VERIFICATIONS,
        NAV_SETTINGS,
        NAV_TOKEN,
        PRODUCTS_SCREEN,
        VERIFICATIONS_SCREEN,
        VERIFICATIONS_EMPTY,
        DETAILS_EMPTY,
        COUNTRY_EMPTY,
        ID_TYPE_EMPTY,
        DOCUMENT_EMPTY,
        CATALOGUE_LOADING,
        CATALOGUE_ERROR,
        CATALOGUE_RETRY,
        ID_NUMBER_ERROR,
        DOCUMENT_TRIGGER,
        CAPTURE_AS_TRIGGER,
        DOCUMENT_SHEET,
        DOCUMENT_SEARCH,
        CAPTURE_AS_SHEET,
        GENERIC_DOCUMENT_SHEET,
        GENERIC_DOCUMENT_NAME,
        GENERIC_DOCUMENT_BACK_SIDE,
        GENERIC_DOCUMENT_DONE,
        SETTING_CAPTURE_MODE,
        CAPTURE_MODE_SHEET,
        SETTING_GALLERY_UPLOAD,
        SETTING_CAPTURE_BOTH_SIDES,
        SETTING_ALLOW_SKIP_BACK,
        SETTING_SELFIE_FIRST,
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
        LICENSES_SCREEN,
        LICENSES_EMPTY,
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
        TOKEN_PORTAL_LINK,
        SCENARIO_DRAWER_BUTTON,
        PROFILE_SUMMARY,
        SETTING_ENHANCED_SMART_SELFIE,
        SETTING_AGENT_MODE,
        SETTING_DARK_MODE,
        SETTING_CONSENT_STEP,
        SETTING_INSTRUCTIONS_STEP,
        SETTING_PREVIEW_STEP,
        SIGN_OUT,
        SIGN_OUT_CONFIRM,
        VERSION_LABEL,
        SELECT_TOGGLE,
        STATUS_BADGE,
        DETAILS_REFRESH,
        DETAILS_DELETE,
        USER_DETAILS_HINT,
        REMEMBER_DETAILS_SWITCH,
        USER_DETAILS_PROFILE,
        USER_DETAILS_CONTINUE,
        COUNTRY_TRIGGER,
        ID_TYPE_TRIGGER,
        ID_NUMBER_INPUT,
        KYC_CONTINUE,
        COUNTRY_SEARCH,
        ID_TYPE_SEARCH,
        CREATE_PROFILE,
        NEW_PROFILE_NAME,
        NEW_PROFILE_FIRST_NAME,
        NEW_PROFILE_LAST_NAME,
        NEW_PROFILE_EMAIL,
        NEW_PROFILE_PHONE,
        NEW_PROFILE_SAVE,
        PROFILE_CONFIG_CALLBACK_URL,
        PROFILE_CONFIG_SAVE,
        PROFILE_CONFIG_CONTACT_ERROR,
        PROFILE_CONFIG_NAME,
        PROFILE_CONFIG_DELETE,
        PROFILE_DELETE_CONFIRM,
        PROFILE_SWITCH_NEW,
        RESULT_CARD,
        RESULT_ACTIVE_SCENARIO,
        RESULT_ACTIVE_THEME,
        RESULT_ROUTE,
        RESULT_ENVIRONMENT,
        RESULT_JOB_ID,
        RESULT_USER_ID,
        RESULT_JOB_STATUS,
        RESULT_RESULT_COUNT,
        RESULT_REFRESH_COUNT,
        RESULT_LAST_ERROR,
        RESULT_SDK_VERSION,
    )

    /** Suffixed ids derive from other spec files, so they are built rather than listed. */
    fun productCard(productId: String) = "sample_product_card_$productId"

    fun tokenEnvironment(environmentId: String) = "sample_token_environment_$environmentId"

    fun settingNav(rowId: String) = "sample_setting_nav_$rowId"

    /** Coordinates carry dots and colons, which no id may: they become underscores. */
    fun licenseRow(artifact: String) = "sample_license_row_${artifact.idSafe()}"

    fun licenseText(artifact: String) = "sample_license_text_${artifact.idSafe()}"

    fun licenseLink(artifact: String) = "sample_license_link_${artifact.idSafe()}"

    fun scenarioItem(scenarioId: String) = "sample_scenario_item_$scenarioId"

    fun themeItem(themeId: String) = "sample_theme_item_$themeId"

    fun filterChip(status: String) = "sample_filter_chip_$status"

    fun filterCount(status: String) = "sample_filter_count_$status"

    fun jobRow(index: Int) = "sample_job_row_$index"

    fun selectionCheckbox(index: Int) = "sample_selection_checkbox_$index"

    fun detailField(field: String) = "sample_detail_field_$field"

    fun detailCopy(field: String) = "sample_detail_copy_$field"

    fun userDetailsField(field: String) = "sample_user_details_field_$field"

    fun countryOption(isoCode: String) = "sample_country_option_$isoCode"

    fun idTypeOption(typeId: String) = "sample_idtype_option_$typeId"

    /** Suffixed with the code, and `_<subType>` on a standalone sub-type row. */
    fun documentOption(documentId: String) = "sample_document_option_$documentId"

    fun captureAsOption(optionId: String) = "sample_capture_as_option_$optionId"

    fun captureModeOption(modeId: String) = "sample_capture_mode_option_$modeId"

    fun genericDocumentOrientation(orientationId: String) = "sample_generic_document_orientation_$orientationId"

    fun genericDocumentAspectRatio(ratioId: String) = "sample_generic_document_aspect_ratio_$ratioId"

    fun profileRow(profileId: String) = "sample_profile_row_$profileId"

    fun profileConfigField(field: String) = "sample_profile_config_field_$field"

    private fun String.idSafe() = replace(ID_UNSAFE, "_")

    private val ID_UNSAFE = Regex("[^A-Za-z0-9]")
}
