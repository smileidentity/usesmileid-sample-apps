/// A coordinate carries characters an id may not, folded the same way on every platform.
String _idSafe(String value) => value.replaceAll(RegExp('[^A-Za-z0-9]'), '_');

/// The accessibility ids this package attaches. Stable forever: deprecate, never rename.
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

  /// The scan token screen root.
  static const String scanTokenScreen = 'sample_scan_token_screen';

  /// One environment chip, suffixed with the environment id.
  static String tokenEnvironment(String environmentId) =>
      'sample_token_environment_$environmentId';

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

  /// The sign-out confirmation's destructive action.
  static const String signOutConfirm = 'sample_sign_out_confirm';

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

  /// The profiles list.
  static const String profilesScreen = 'sample_profiles_screen';

  /// One profile row, suffixed with that profile's id; the list and the switch sheet share it.
  static String profileRow(String profileId) => 'sample_profile_row_$profileId';

  /// The row that opens the new-profile sheet.
  static const String createProfile = 'sample_create_profile';

  /// One profile's own page.
  static const String profileConfigScreen = 'sample_profile_config_screen';

  /// One editable field on that page, suffixed with the field's camelCase id.
  static String profileConfigField(String field) =>
      'sample_profile_config_field_$field';

  /// The profile's webhook URL, in its own section below the details.
  static const String profileConfigCallbackUrl =
      'sample_profile_config_callback_url';

  /// The page's only write: it saves the details AND makes the profile active.
  static const String profileConfigSave = 'sample_profile_config_save';

  /// The profile's organisation row.
  static const String profileConfigName = 'sample_profile_config_name';

  /// Deletes the profile after a confirmation.
  static const String profileConfigDelete = 'sample_profile_config_delete';

  /// The delete confirmation's destructive action.
  static const String profileDeleteConfirm = 'sample_profile_delete_confirm';

  /// The result card container, and the compact line that stands in for it on products.
  static const String resultCard = 'sample_result_card';

  /// The scenario the run actually got.
  static const String resultActiveScenario = 'sample_result_active_scenario';

  /// The theme scenario in effect.
  static const String resultActiveTheme = 'sample_result_active_theme';

  /// The route hosting the flow.
  static const String resultRoute = 'sample_result_route';

  /// The environment the run submitted to; the only surface that says so.
  static const String resultEnvironment = 'sample_result_environment';

  /// The SDK's job id.
  static const String resultJobId = 'sample_result_job_id';

  /// The server's user id.
  static const String resultUserId = 'sample_result_user_id';

  /// The run status, cancelled and failed kept apart.
  static const String resultJobStatus = 'sample_result_job_status';

  /// How many times the host result callback fired.
  static const String resultResultCount = 'sample_result_result_count';

  /// How many times the token refresh callback fired.
  static const String resultRefreshCount = 'sample_result_refresh_count';

  /// The last error the host saw.
  static const String resultLastError = 'sample_result_last_error';

  /// The SDK version the run exercised.
  static const String resultSdkVersion = 'sample_result_sdk_version';

  /// The switch sheet, which Products owns.
  static const String profileSwitchSheet = 'sample_profile_switch_sheet';

  /// The switch sheet's last row, which creates a profile and makes it active.
  static const String profileSwitchNew = 'sample_profile_switch_new';

  /// The new-profile sheet, which the profiles list owns.
  static const String newProfileSheet = 'sample_new_profile_sheet';

  /// The new profile's organisation.
  static const String newProfileName = 'sample_new_profile_name';

  /// The new profile's given name.
  static const String newProfileFirstName = 'sample_new_profile_first_name';

  /// The new profile's family name.
  static const String newProfileLastName = 'sample_new_profile_last_name';

  /// The new profile's email, which never gates the confirm.
  static const String newProfileEmail = 'sample_new_profile_email';

  /// The new profile's phone, which never gates the confirm.
  static const String newProfilePhone = 'sample_new_profile_phone';

  /// Creates the profile; the confirmation offers to make it active.
  static const String newProfileSave = 'sample_new_profile_save';

  /// The consent details form, which every product shows before its flow.
  static const String userDetailsScreen = 'sample_user_details_screen';

  /// One of its four rows, suffixed with the field's camelCase id.
  static String userDetailsField(String field) =>
      'sample_user_details_field_$field';

  /// The line under the card that says what is still outstanding.
  static const String userDetailsHint = 'sample_user_details_hint';

  /// The remember switch, which appears only once the form is satisfied.
  static const String rememberDetailsSwitch = 'sample_remember_details_switch';

  /// Whose details the form shows; opens the switch sheet.
  static const String userDetailsProfile = 'sample_user_details_profile';

  /// The consent form's continue.
  static const String userDetailsContinue = 'sample_user_details_continue';

  /// The ID details form, shown only for the products that need one.
  static const String kycFormScreen = 'sample_kyc_form_screen';

  /// The country select trigger.
  static const String countryTrigger = 'sample_country_trigger';

  /// The ID type select trigger, disabled until a country is chosen.
  static const String idTypeTrigger = 'sample_idtype_trigger';

  /// The ID number field.
  static const String idNumberInput = 'sample_idnumber_input';

  /// The ID form's continue.
  static const String kycContinue = 'sample_kyc_continue';

  /// The country picker sheet.
  static const String countrySheet = 'sample_country_sheet';

  /// Its search field, which filters on the country NAME and never the code.
  static const String countrySearch = 'sample_country_search';

  /// One country row, suffixed with its ISO code.
  static String countryOption(String code) => 'sample_country_option_$code';

  /// What the country picker shows when the search matches nothing.
  static const String countryEmpty = 'sample_country_empty';

  /// The ID type picker sheet.
  static const String idTypeSheet = 'sample_idtype_sheet';

  /// Its search field.
  static const String idTypeSearch = 'sample_idtype_search';

  /// One ID type row, suffixed with its id.
  static String idTypeOption(String typeId) => 'sample_idtype_option_$typeId';

  /// What the ID type picker shows with no country, and with no match.
  static const String idTypeEmpty = 'sample_idtype_empty';

  /// The scenario drawer, a debug affordance the design does not cover.
  static const String scenarioDrawer = 'sample_scenario_drawer';

  /// The settings row that opens it.
  static const String scenarioDrawerButton = 'sample_scenario_drawer_button';

  /// One flow-scenario row, suffixed with the scenario id.
  static String scenarioItem(String scenarioId) =>
      'sample_scenario_item_$scenarioId';

  /// One theme-scenario row, suffixed with the theme id.
  static String themeItem(String themeId) => 'sample_theme_item_$themeId';

  /// The third-party notices screen.
  static const String licensesScreen = 'sample_licenses_screen';

  /// One notice row, suffixed with its package name.
  static String licenseRow(String package) =>
      'sample_license_row_${_idSafe(package)}';

  /// The expanded licence body, suffixed with its package name.
  static String licenseText(String package) =>
      'sample_license_text_${_idSafe(package)}';

  /// What the screen says when the notices did not ship.
  static const String licensesEmpty = 'sample_licenses_empty';

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
    scanTokenScreen,
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
    signOutConfirm,
    versionLabel,
    toast,
    toastUndo,
    jobRowStatus,
    selectToggle,
    verificationDetailsScreen,
    verificationsScreen,
    verificationsEmpty,
    statusBadge,
    detailsDelete,
    detailsRefresh,
    detailsEmpty,
    profilesScreen,
    createProfile,
    profileConfigScreen,
    profileConfigCallbackUrl,
    profileConfigSave,
    profileConfigName,
    profileConfigDelete,
    profileDeleteConfirm,
    resultCard,
    resultActiveScenario,
    resultActiveTheme,
    resultRoute,
    resultEnvironment,
    resultJobId,
    resultUserId,
    resultJobStatus,
    resultResultCount,
    resultRefreshCount,
    resultLastError,
    resultSdkVersion,
    profileSwitchSheet,
    profileSwitchNew,
    newProfileSheet,
    newProfileName,
    newProfileFirstName,
    newProfileLastName,
    newProfileEmail,
    newProfilePhone,
    newProfileSave,
    userDetailsScreen,
    userDetailsHint,
    rememberDetailsSwitch,
    userDetailsProfile,
    userDetailsContinue,
    kycFormScreen,
    countryTrigger,
    idTypeTrigger,
    idNumberInput,
    kycContinue,
    countrySheet,
    countrySearch,
    countryEmpty,
    idTypeSheet,
    idTypeSearch,
    idTypeEmpty,
    scenarioDrawer,
    scenarioDrawerButton,
    licensesScreen,
    licensesEmpty,
    selectionBar,
    selectionCount,
    selectionRemove,
  ];
}
