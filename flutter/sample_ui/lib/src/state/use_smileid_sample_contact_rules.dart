import '../use_smileid_sample_strings.dart';
import 'use_smileid_sample_profiles.dart';

/// The email and phone checks from `spec/contact-rules.json`, which mirror the v3 API's own request schema.
abstract final class UseSmileIDSampleContactRules {
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
  static UseSmileIDSampleContactProblem? problem(
    UseSmileIDSampleUserField field,
    String value,
  ) {
    final String candidate = submitted(field, value);
    if (candidate.isEmpty) {
      return null;
    }
    return switch (field) {
      UseSmileIDSampleUserField.email =>
        _email.hasMatch(candidate)
            ? null
            : UseSmileIDSampleContactProblem.email,
      UseSmileIDSampleUserField.phone =>
        _phone.hasMatch(candidate)
            ? null
            : UseSmileIDSampleContactProblem.phone,
      _ => null,
    };
  }
}

/// Which contact value the server would refuse, worded where it is shown.
enum UseSmileIDSampleContactProblem {
  /// The email.
  email,

  /// The phone number.
  phone;

  /// The line under the field, in the app's language.
  String message(UseSmileIDSampleStrings strings) => switch (this) {
    UseSmileIDSampleContactProblem.email => strings.userFieldEmailError,
    UseSmileIDSampleContactProblem.phone => strings.userFieldPhoneError,
  };
}

/// The contact checks as the forms read them.
extension UseSmileIDSampleContactDetails on UseSmileIDSampleUserDetails {
  /// Why the email or phone would fail the job, email first; null when both would pass.
  UseSmileIDSampleContactProblem? get contactProblem =>
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
