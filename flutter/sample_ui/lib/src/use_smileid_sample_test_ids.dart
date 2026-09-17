/// The accessibility ids this package attaches. Stable forever: deprecate, never rename.
///
/// Ids a screen assigns per row arrive with that screen; these are the ones a component owns.
abstract final class UseSmileIDSampleTestIds {
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
    toast,
    toastUndo,
    jobRowStatus,
    selectionBar,
    selectionCount,
    selectionRemove,
  ];
}
