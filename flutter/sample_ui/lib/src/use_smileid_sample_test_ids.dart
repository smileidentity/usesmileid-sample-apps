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

  /// The toast container, shared by the removal confirmation and the profile-created one.
  static const String toast = 'sample_toast';

  /// The action inside a toast, whatever it is labelled.
  static const String toastUndo = 'sample_toast_undo';

  /// The status badge inside a verification row, which the row attaches itself.
  static const String jobRowStatus = 'sample_job_row_status';

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
    toast,
    toastUndo,
    jobRowStatus,
    selectionBar,
    selectionCount,
    selectionRemove,
  ];
}
