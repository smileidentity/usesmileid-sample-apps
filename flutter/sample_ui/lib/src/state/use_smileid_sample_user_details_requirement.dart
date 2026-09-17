import 'use_smileid_sample_profiles.dart';

/// What the consent form still has to collect, which a token can narrow.
///
/// The default asks for everything, and that is the only shape reachable until a token session
/// exists: a token that binds a field lifts its clause and disables its row.
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
  ///
  /// This cannot answer that on its own: a requirement asking for three fields says so whether or
  /// not they have been typed, and only the screen holds what was typed.
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
