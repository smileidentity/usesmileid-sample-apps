/// The accessibility ids this package attaches. Stable forever: deprecate, never rename.
///
/// Ids a screen assigns per row arrive with that screen; these are the ones a component owns.
abstract final class UseSmileIDSampleTestIds {
  /// Bottom nav destination: products.
  static const String navProducts = 'sample_nav_products';

  /// Bottom nav destination: verifications.
  static const String navVerifications = 'sample_nav_verifications';

  /// Bottom nav destination: settings.
  static const String navSettings = 'sample_nav_settings';

  /// The bottom nav's token affordance, which carries the countdown ring.
  static const String navToken = 'sample_nav_token';

  /// The active-session card on the products screen.
  static const String sessionCard = 'sample_session_card';

  /// The countdown inside the session card, asserted as a value.
  static const String sessionCountdown = 'sample_session_countdown';

  /// The neutral card that replaces the session card on expiry.
  static const String sessionEndedBanner = 'sample_session_ended_banner';

  /// The floating affordance that reaches the token session from inside a form.
  static const String tokenFloat = 'sample_token_float';

  /// The manual token entry row on the scan screen.
  static const String tokenManualEntry = 'sample_token_manual_entry';

  /// The paste action inside the manual entry row.
  static const String tokenPaste = 'sample_token_paste';

  /// Simulate a successful scan, which makes token flows testable with no QR source.
  static const String tokenSimulate = 'sample_token_simulate';

  /// The products screen root.
  static const String productsScreen = 'sample_products_screen';

  /// The header avatar button, which opens the profile-switch sheet.
  static const String profileAvatarButton = 'sample_profile_avatar_button';

  /// One product card, suffixed with the product id.
  static String productCard(String productId) =>
      'sample_product_card_$productId';

  /// The verifications root.
  static const String verificationsScreen = 'sample_verifications_screen';

  /// The verifications list with nothing in it, which is what a first launch shows.
  static const String verificationsEmpty = 'sample_verifications_empty';

  /// The settings root.
  static const String settingsScreen = 'sample_settings_screen';

  /// The profile row at the top of settings, which opens the profiles LIST.
  static const String profileSummary = 'sample_profile_summary';

  /// The Enhanced SmartSelfie switch, which drives enableEnhancedLiveness.
  static const String settingEnhancedSmartSelfie =
      'sample_setting_enhanced_smart_selfie';

  /// The Agent mode switch, which drives allowAgentMode.
  static const String settingAgentMode = 'sample_setting_agent_mode';

  /// The Dark mode switch.
  static const String settingDarkMode = 'sample_setting_dark_mode';

  /// The Consent screen switch, which includes or omits consent().
  static const String settingConsentStep = 'sample_setting_consent_step';

  /// The Instruction screen switch, which includes or omits instructions().
  static const String settingInstructionsStep =
      'sample_setting_instructions_step';

  /// The Preview screen switch, which includes or omits preview().
  static const String settingPreviewStep = 'sample_setting_preview_step';

  /// One ABOUT or LEGAL navigation row; suffixed with the row id.
  static const String settingNav = 'sample_setting_nav';

  /// The sign-out row.
  static const String signOut = 'sample_sign_out';

  /// The app name and version footer.
  static const String versionLabel = 'sample_version_label';

  /// The toast container, shared by the removal confirmation and the profile-created one.
  static const String toast = 'sample_toast';

  /// The action inside a toast, whatever it is labelled.
  static const String toastUndo = 'sample_toast_undo';

  /// One filter chip, suffixed with the filter's id.
  static String filterChip(String filterId) => 'sample_filter_chip_$filterId';

  /// A filter chip's count, asserted separately so a flow reads a number rather than prose.
  static String filterCount(String filterId) => 'sample_filter_count_$filterId';

  /// One verification row, suffixed with its position in the whole visible list.
  static String jobRow(int index) => 'sample_job_row_$index';

  /// The status badge inside a verification row, which the row attaches itself.
  static const String jobRowStatus = 'sample_job_row_status';

  /// The header action that enters and leaves select mode; its label flips Select / Cancel.
  static const String selectToggle = 'sample_select_toggle';

  /// One row's selection checkbox, suffixed with the row's position, present only in select mode.
  static String selectionCheckbox(int index) =>
      'sample_selection_checkbox_$index';

  /// One verification's detail page.
  static const String verificationDetailsScreen =
      'sample_verification_details_screen';

  /// The status badge on the detail page, which is NOT the row's badge id.
  static const String statusBadge = 'sample_status_badge';

  /// One label/value row on the detail page, suffixed with the field name.
  static String detailField(String field) => 'sample_detail_field_$field';

  /// A detail row's copy control, suffixed with the same field name.
  static String detailCopy(String field) => 'sample_detail_copy_$field';

  /// The detail page's destructive action, which hides the verification.
  static const String detailsDelete = 'sample_details_delete';

  /// The pull-to-refresh container, which the design draws in the processing state.
  static const String detailsRefresh = 'sample_details_refresh';

  /// What the detail page shows for a job this build never stored.
  static const String detailsEmpty = 'sample_details_empty';

  /// The selection bar shown instead of the nav bar.
  static const String selectionBar = 'sample_selection_bar';

  /// The "n selected" text, its own node so a flow asserts equality rather than parsing prose.
  static const String selectionCount = 'sample_selection_count';

  /// The remove action in the selection bar; the copy reads Hide from List.
  static const String selectionRemove = 'sample_selection_remove';

  /// Every id declared here, which the spec test checks against `spec/test-ids.json`.
  static const List<String> all = <String>[
    navProducts,
    navVerifications,
    navSettings,
    navToken,
    sessionCard,
    sessionCountdown,
    sessionEndedBanner,
    tokenFloat,
    tokenManualEntry,
    tokenPaste,
    tokenSimulate,
    productsScreen,
    profileAvatarButton,
    settingsScreen,
    profileSummary,
    settingEnhancedSmartSelfie,
    settingAgentMode,
    settingDarkMode,
    settingConsentStep,
    settingInstructionsStep,
    settingPreviewStep,
    settingNav,
    signOut,
    versionLabel,
    toast,
    toastUndo,
    jobRowStatus,
    selectToggle,
    verificationDetailsScreen,
    statusBadge,
    detailsDelete,
    detailsRefresh,
    detailsEmpty,
    selectionBar,
    selectionCount,
    selectionRemove,
  ];
}
