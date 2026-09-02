/// The `sample_*` ids from `spec/test-ids.json`. Attach to leaves — a container id overrides children.
public enum UseSmileIDSampleTestIds {
  public static let productsScreen = "sample_products_screen"
  public static let verificationsScreen = "sample_verifications_screen"
  public static let verificationDetailsScreen = "sample_verification_details_screen"
  public static let settingsScreen = "sample_settings_screen"

  public static let navProducts = "sample_nav_products"
  public static let navVerifications = "sample_nav_verifications"
  public static let navSettings = "sample_nav_settings"

  /// The bar carries the first, its action the second. Both sit on leaves: an identifier on the
  /// bar itself would override the action's.
  public static let toast = "sample_toast"
  public static let toastUndo = "sample_toast_undo"

  public static let envChip = "sample_env_chip"
  public static let profileAvatarButton = "sample_profile_avatar_button"
  public static let profileSummary = "sample_profile_summary"
  public static let sessionCard = "sample_session_card"
  public static let sessionCountdown = "sample_session_countdown"
  public static let sessionEndedBanner = "sample_session_ended_banner"
  public static let scenarioDrawerButton = "sample_scenario_drawer_button"
  public static let signOut = "sample_sign_out"
  public static let versionLabel = "sample_version_label"
  public static let settingEnhancedSmartSelfie = "sample_setting_enhanced_smart_selfie"
  public static let settingAgentMode = "sample_setting_agent_mode"
  public static let settingDarkMode = "sample_setting_dark_mode"
  public static let settingConsentStep = "sample_setting_consent_step"
  public static let settingInstructionsStep = "sample_setting_instructions_step"
  public static let settingPreviewStep = "sample_setting_preview_step"

  /// Per-item ids the screens build; the spec lists the prefixes rather than every value.
  public static func productCard(_ product: String) -> String {
    "\(productCardPrefix)_\(product)"
  }

  public static func navRow(_ row: String) -> String {
    "\(settingNavPrefix)_\(row)"
  }

  public static func detailField(_ field: String) -> String {
    "\(detailFieldPrefix)_\(field)"
  }

  public static func detailCopy(_ field: String) -> String {
    "\(detailCopyPrefix)_\(field)"
  }

  public static func userDetailsField(_ field: String) -> String {
    "\(userDetailsFieldPrefix)_\(field)"
  }

  public static func countryOption(_ code: String) -> String {
    "\(countryOptionPrefix)_\(code)"
  }

  public static func idTypeOption(_ id: String) -> String {
    "\(idTypeOptionPrefix)_\(id)"
  }

  public static func profileRow(_ profileId: String) -> String {
    "\(profileRowPrefix)_\(profileId)"
  }

  public static func profileConfigField(_ field: String) -> String {
    "\(profileConfigFieldPrefix)_\(field)"
  }

  public static let navToken = "sample_nav_token"
  public static let productCardPrefix = "sample_product_card"
  public static let settingNavPrefix = "sample_setting_nav"
  public static let detailFieldPrefix = "sample_detail_field"
  public static let detailCopyPrefix = "sample_detail_copy"
  public static let userDetailsFieldPrefix = "sample_user_details_field"
  public static let countryOptionPrefix = "sample_country_option"
  public static let idTypeOptionPrefix = "sample_idtype_option"
  public static let profileRowPrefix = "sample_profile_row"
  public static let profileConfigFieldPrefix = "sample_profile_config_field"

  public static let kycFormScreen = "sample_kyc_form_screen"
  public static let countryTrigger = "sample_country_trigger"
  public static let idTypeTrigger = "sample_idtype_trigger"
  public static let idNumberInput = "sample_idnumber_input"
  public static let kycContinue = "sample_kyc_continue"
  public static let tokenFloat = "sample_token_float"
  public static let countrySheet = "sample_country_sheet"
  public static let countrySearch = "sample_country_search"
  public static let countryEmpty = "sample_country_empty"
  public static let idTypeSheet = "sample_idtype_sheet"
  public static let idTypeSearch = "sample_idtype_search"
  public static let idTypeEmpty = "sample_idtype_empty"

  public static let userDetailsScreen = "sample_user_details_screen"
  public static let userDetailsHint = "sample_user_details_hint"
  public static let userDetailsContinue = "sample_user_details_continue"
  public static let rememberDetailsSwitch = "sample_remember_details_switch"

  public static let profilesScreen = "sample_profiles_screen"
  public static let createProfile = "sample_create_profile"
  public static let profileConfigScreen = "sample_profile_config_screen"
  public static let profileConfigSave = "sample_profile_config_save"
  public static let profileSwitchSheet = "sample_profile_switch_sheet"
  public static let newProfileSheet = "sample_new_profile_sheet"
  public static let newProfileName = "sample_new_profile_name"
  public static let newProfileFirstName = "sample_new_profile_first_name"
  public static let newProfileLastName = "sample_new_profile_last_name"
  public static let newProfileEmail = "sample_new_profile_email"
  public static let newProfilePhone = "sample_new_profile_phone"
  public static let newProfileSave = "sample_new_profile_save"

  public static let statusBadge = "sample_status_badge"
  public static let detailsDelete = "sample_details_delete"
  public static let detailsEmpty = "sample_details_empty"

  public static let jobRow = "sample_job_row"
  public static let jobRowStatus = "sample_job_row_status"
  public static let filterChip = "sample_filter_chip"
  public static let filterCount = "sample_filter_count"
  public static let selectionBar = "sample_selection_bar"
  public static let selectionCheckbox = "sample_selection_checkbox"
  public static let selectionCount = "sample_selection_count"
  public static let selectionRemove = "sample_selection_remove"

  /// Every id above, so the spec test cannot pass by omission.
  static let all = [
    productsScreen, verificationsScreen, verificationDetailsScreen, settingsScreen,
    navProducts, navVerifications, navSettings,
    toast, toastUndo,
    envChip, navToken, productCardPrefix, settingNavPrefix,
    detailFieldPrefix, detailCopyPrefix, statusBadge, detailsDelete, detailsEmpty,
    userDetailsScreen, userDetailsFieldPrefix, userDetailsHint, userDetailsContinue,
    rememberDetailsSwitch,
    kycFormScreen, countryTrigger, idTypeTrigger, idNumberInput, kycContinue, tokenFloat,
    countrySheet, countrySearch, countryEmpty, countryOptionPrefix,
    idTypeSheet, idTypeSearch, idTypeEmpty, idTypeOptionPrefix,
    profileAvatarButton, profileSummary,
    profilesScreen, profileRowPrefix, createProfile,
    profileConfigScreen, profileConfigFieldPrefix, profileConfigSave,
    profileSwitchSheet, newProfileSheet, newProfileName, newProfileFirstName, newProfileLastName,
    newProfileEmail, newProfilePhone, newProfileSave,
    sessionCard, sessionCountdown, sessionEndedBanner,
    scenarioDrawerButton, signOut, versionLabel,
    settingEnhancedSmartSelfie, settingAgentMode, settingDarkMode,
    settingConsentStep, settingInstructionsStep, settingPreviewStep,
    jobRow, jobRowStatus, filterChip, filterCount,
    selectionBar, selectionCheckbox, selectionCount, selectionRemove
  ]
}
