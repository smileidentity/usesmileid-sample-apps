import '../use_smileid_sample_strings.dart';

/// The four job statuses, Title case as the design sets them — never upper-cased.
enum UseSmileIDSampleStatus {
  /// Cleared.
  clear('success'),

  /// Needs attention.
  attention('warning'),

  /// Blocked.
  blocked('error'),

  /// Still processing.
  processing('info');

  const UseSmileIDSampleStatus(this.role);

  /// The pill's text, already cased.
  String label(UseSmileIDSampleStrings strings) => switch (this) {
    UseSmileIDSampleStatus.clear => strings.statusClear,
    UseSmileIDSampleStatus.attention => strings.statusAttention,
    UseSmileIDSampleStatus.blocked => strings.statusBlocked,
    UseSmileIDSampleStatus.processing => strings.statusProcessing,
  };

  /// The feedback role whose soft fill the pill draws.
  final String role;
}
