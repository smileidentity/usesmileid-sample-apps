/// The four job statuses, Title case as the design sets them — never upper-cased.
enum UseSmileIDSampleStatus {
  /// Cleared.
  clear('Clear', 'success'),

  /// Needs attention.
  attention('Attention', 'warning'),

  /// Blocked.
  blocked('Blocked', 'error'),

  /// Still processing.
  processing('Processing', 'info');

  const UseSmileIDSampleStatus(this.label, this.role);

  /// The pill's text, already cased.
  final String label;

  /// The feedback role whose soft fill the pill draws.
  final String role;
}
