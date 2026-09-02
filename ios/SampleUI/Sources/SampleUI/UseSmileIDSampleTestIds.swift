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

  public static let navToken = "sample_nav_token"
  public static let productCardPrefix = "sample_product_card"
  public static let settingNavPrefix = "sample_setting_nav"
  public static let detailFieldPrefix = "sample_detail_field"
  public static let detailCopyPrefix = "sample_detail_copy"

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
    profileAvatarButton, profileSummary,
    sessionCard, sessionCountdown, sessionEndedBanner,
    scenarioDrawerButton, signOut, versionLabel,
    settingEnhancedSmartSelfie, settingAgentMode, settingDarkMode,
    settingConsentStep, settingInstructionsStep, settingPreviewStep,
    jobRow, jobRowStatus, filterChip, filterCount,
    selectionBar, selectionCheckbox, selectionCount, selectionRemove
  ]
}
