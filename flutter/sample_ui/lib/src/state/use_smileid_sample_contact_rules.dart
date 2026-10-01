import 'use_smileid_sample_profiles.dart';

/// The email and phone checks from `spec/contact-rules.json`, which mirror the v3 API's own request schema.
abstract final class UseSmileIDSampleContactRules {
  /// Shown for an email the server would refuse.
  static const String emailError = 'Enter an email like name@company.com.';

  /// Shown for a phone number the server would refuse.
  static const String phoneError =
      'Enter the number with its country code, like +254 700 000 000.';

  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final RegExp _phoneSeparators = RegExp(r'[\s().-]');
  static final RegExp _phone = RegExp(r'^\+[1-9][0-9]{6,14}$');

  /// [value] as it is submitted: trimmed, and a phone number without its separators.
  static String submitted(UseSmileIDSampleUserField field, String value) {
    final String trimmed = value.trim();
    return field == UseSmileIDSampleUserField.phone
        ? trimmed.replaceAll(_phoneSeparators, '')
        : trimmed;
  }

  /// Why [value] would fail the job as [field], or null when it would pass; blank always passes.
  static String? problem(UseSmileIDSampleUserField field, String value) {
    final String candidate = submitted(field, value);
    if (candidate.isEmpty) {
      return null;
    }
    return switch (field) {
      UseSmileIDSampleUserField.email =>
        _email.hasMatch(candidate) ? null : emailError,
      UseSmileIDSampleUserField.phone =>
        _phone.hasMatch(candidate) ? null : phoneError,
      _ => null,
    };
  }
}

/// The contact checks as the forms read them.
extension UseSmileIDSampleContactDetails on UseSmileIDSampleUserDetails {
  /// Why the email or phone would fail the job, email first; null when both would pass.
  String? get contactProblem =>
      UseSmileIDSampleContactRules.problem(
        UseSmileIDSampleUserField.email,
        email,
      ) ??
      UseSmileIDSampleContactRules.problem(
        UseSmileIDSampleUserField.phone,
        phone,
      );

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
