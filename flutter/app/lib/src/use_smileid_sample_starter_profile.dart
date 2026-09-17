/// The profile the app acts as before any profile has been created.
///
/// Read by both the products header and the settings profile row, so they cannot disagree. The
/// persistence branch replaces this with the stored active profile; the values are the same ones
/// the Android twin derives, so the screens do not change when the store arrives.
abstract final class UseSmileIDSampleStarterProfile {
  /// Shown on the consent screen as the partner until a profile is created, so it reads as a placeholder.
  static const String organisation = 'Default profile';

  /// The organisation's initials, because the starter names no person.
  ///
  /// The twin's rule is person, else organisation, first letter of the first two words, uppercased.
  static const String initials = 'DP';
}
