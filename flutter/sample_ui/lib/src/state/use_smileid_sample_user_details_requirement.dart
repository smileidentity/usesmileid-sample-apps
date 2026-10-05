import '../use_smileid_sample_strings.dart';
import 'use_smileid_sample_contact_rules.dart';
import 'use_smileid_sample_profiles.dart';
import 'use_smileid_sample_token_decoder.dart';

/// What the consent form still has to collect, which a token can narrow.
class UseSmileIDSampleUserDetailsRequirement {
  /// Everything required, which is what a launch with no token gets.
  const UseSmileIDSampleUserDetailsRequirement({
    this.firstName = true,
    this.lastName = true,
    this.contact = true,
  });

  /// Whether a given name is still needed.
  final bool firstName;

  /// Whether a family name is still needed.
  final bool lastName;

  /// Whether an email OR a phone is still needed; one of, never both.
  final bool contact;

  /// Nothing left to ask, so the form has no reason to appear.
  bool get isSatisfied => !firstName && !lastName && !contact;

  /// Whether the token supplied [field].
  bool supplies(UseSmileIDSampleUserField field) => switch (field) {
    UseSmileIDSampleUserField.firstName => !firstName,
    UseSmileIDSampleUserField.lastName => !lastName,
    // Contact is one of two, so neither row is supplied on its own.
    UseSmileIDSampleUserField.email || UseSmileIDSampleUserField.phone => false,
  };

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleUserDetailsRequirement &&
      other.firstName == firstName &&
      other.lastName == lastName &&
      other.contact == contact;

  @override
  int get hashCode => Object.hash(firstName, lastName, contact);

  /// Whether [details] satisfies what is still outstanding, in a form the server accepts.
  bool isSatisfiedBy(UseSmileIDSampleUserDetails details) =>
      (!firstName || details.firstName.trim().isNotEmpty) &&
      (!lastName || details.lastName.trim().isNotEmpty) &&
      (!contact ||
          details.email.trim().isNotEmpty ||
          details.phone.trim().isNotEmpty) &&
      details.contactProblem == null;

  /// The row's label, which gains "(optional)" only once a token has covered contact.
  String labelFor(
    UseSmileIDSampleUserField field,
    UseSmileIDSampleStrings strings,
  ) => contact && !field.isRequired
      ? field.title(strings)
      : field.label(strings);

  /// What this requirement still asks for; the SCREEN decides when nothing is outstanding.
  String prompt(UseSmileIDSampleStrings strings) {
    final List<String> outstanding = <String>[
      if (firstName) strings.userRequirementFirstName,
      if (lastName) strings.userRequirementLastName,
      if (contact) strings.userRequirementContact,
    ];
    if (outstanding.isEmpty) {
      return strings.userDetailsEditHint;
    }
    final String sentence = outstanding.length == 1
        ? strings.userRequirementOne(field: outstanding.single)
        : strings.userRequirementMany(
            fields: outstanding.join(strings.userRequirementSeparator),
          );
    return '${sentence[0].toUpperCase()}${sentence.substring(1)}';
  }
}

/// The requirement a token leaves behind.
UseSmileIDSampleUserDetailsRequirement useSmileIDSampleUserDetailsRequirement(
  UseSmileIDSampleTokenBindings? bindings,
) => UseSmileIDSampleUserDetailsRequirement(
  firstName: bindings?.givenNames != true,
  lastName: bindings?.lastName != true,
  contact: !(bindings?.email == true || bindings?.phoneNumber == true),
);

/// Mirrors the SDK's internal `bindsRequiredUserDetails`.
extension UseSmileIDSampleRequiredUserDetails on UseSmileIDSampleTokenBindings {
  /// Whether the token binds enough for the SDK to stop requiring `userDetails`.
  bool get bindsRequiredUserDetails =>
      useSmileIDSampleUserDetailsRequirement(this).isSatisfied;
}
