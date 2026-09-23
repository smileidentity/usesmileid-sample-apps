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

  /// Whether [field] is one the token already supplied, which is why it renders as provided.
  bool supplies(UseSmileIDSampleUserField field) => switch (field) {
    UseSmileIDSampleUserField.firstName => !firstName,
    UseSmileIDSampleUserField.lastName => !lastName,
    // Contact is "one of", so a bound email leaves phone askable: only the requirement lifts.
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

  /// Whether [details] satisfies what is still outstanding.
  bool isSatisfiedBy(UseSmileIDSampleUserDetails details) =>
      (!firstName || details.firstName.trim().isNotEmpty) &&
      (!lastName || details.lastName.trim().isNotEmpty) &&
      (!contact ||
          details.email.trim().isNotEmpty ||
          details.phone.trim().isNotEmpty);

  /// The row's label, which gains "(optional)" only once a token has covered contact.
  String labelFor(UseSmileIDSampleUserField field) => switch (field) {
    UseSmileIDSampleUserField.firstName => 'First name',
    UseSmileIDSampleUserField.lastName => 'Last name',
    UseSmileIDSampleUserField.email => contact ? 'Email' : 'Email (optional)',
    UseSmileIDSampleUserField.phone => contact ? 'Phone' : 'Phone (optional)',
  };

  /// What this requirement still asks for; the SCREEN decides when nothing is outstanding.
  String get prompt {
    final List<String> outstanding = <String>[
      if (firstName) 'first name',
      if (lastName) 'last name',
      if (contact) 'an email or phone number',
    ];
    if (outstanding.isEmpty) {
      return 'Tap any field to edit.';
    }
    if (outstanding.length == 1) {
      final String only = outstanding.single;
      return '${only[0].toUpperCase()}${only.substring(1)} is required.';
    }
    return 'Required: ${outstanding.join(', ')}.';
  }
}

/// The requirement a token leaves behind: the SDK's union rule, field for field.
UseSmileIDSampleUserDetailsRequirement useSmileIDSampleUserDetailsRequirement(
  UseSmileIDSampleTokenBindings? bindings,
) => UseSmileIDSampleUserDetailsRequirement(
  firstName: bindings?.givenNames != true,
  lastName: bindings?.lastName != true,
  contact: !(bindings?.email == true || bindings?.phoneNumber == true),
);

/// A duplicate of the SDK's internal `bindsRequiredUserDetails`: both names plus one contact field.
extension UseSmileIDSampleRequiredUserDetails on UseSmileIDSampleTokenBindings {
  /// Whether the token binds enough for the SDK to stop requiring `userDetails`.
  bool get bindsRequiredUserDetails =>
      useSmileIDSampleUserDetailsRequirement(this).isSatisfied;
}
