/// The accessibility ids this package attaches. Stable forever: deprecate, never rename.
abstract final class UseSmileIDSampleTestIds {
  /// The toast container, shared by the removal confirmation and the profile-created one.
  static const String toast = 'sample_toast';

  /// The action inside a toast, whatever it is labelled.
  static const String toastUndo = 'sample_toast_undo';

  /// Every id declared here, which the spec test checks against `spec/test-ids.json`.
  static const List<String> all = <String>[toast, toastUndo];
}
