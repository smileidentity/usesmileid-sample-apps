import 'use_smileid_sample_profiles.dart';

/// How `spec/contact-rules.json` submits an email or a phone number; no form checks either.
abstract final class UseSmileIDSampleContactRules {
  static final RegExp _phoneSeparators = RegExp(r'[\s().-]');

  /// [value] as it is submitted: trimmed, and a phone number without its separators.
  static String submitted(UseSmileIDSampleUserField field, String value) {
    final String trimmed = value.trim();
    return field == UseSmileIDSampleUserField.phone
        ? trimmed.replaceAll(_phoneSeparators, '')
        : trimmed;
  }
}

/// The contact values as the run submits them.
extension UseSmileIDSampleContactDetails on UseSmileIDSampleUserDetails {
  /// The email as the server wants it, or null when blank.
  String? get submittedEmail => _nullIfEmpty(
    UseSmileIDSampleContactRules.submitted(
      UseSmileIDSampleUserField.email,
      email,
    ),
  );

  /// The phone number as the server wants it, or null when blank.
  String? get submittedPhone => _nullIfEmpty(
    UseSmileIDSampleContactRules.submitted(
      UseSmileIDSampleUserField.phone,
      phone,
    ),
  );
}

String? _nullIfEmpty(String value) => value.isEmpty ? null : value;
