/// The seven countries the picker offers, in the order it draws them.
///
/// Hardcoded here rather than taken from the SDK or `spec/`: no spec file carries the table, and
/// declaration order IS display order, so it is not alphabetical by accident.
enum UseSmileIDSampleCountry {
  /// Nigeria.
  ng('NG', 'Nigeria', '🇳🇬'),

  /// Kenya.
  ke('KE', 'Kenya', '🇰🇪'),

  /// Ghana.
  gh('GH', 'Ghana', '🇬🇭'),

  /// South Africa.
  za('ZA', 'South Africa', '🇿🇦'),

  /// Uganda.
  ug('UG', 'Uganda', '🇺🇬'),

  /// Tanzania.
  tz('TZ', 'Tanzania', '🇹🇿'),

  /// Rwanda.
  rw('RW', 'Rwanda', '🇷🇼');

  const UseSmileIDSampleCountry(this.code, this.label, this.flag);

  /// The ISO code, which also suffixes this row's test id.
  final String code;

  /// The country's name, which is the only thing the search filters on.
  final String label;

  /// The flag emoji the row and the trigger lead with.
  final String flag;
}

/// The four ID types, each offered by the countries that issue it.
enum UseSmileIDSampleIdType {
  /// Issued by every country in the table.
  nationalId('NATIONAL_ID', 'National ID', UseSmileIDSampleCountry.values),

  /// Issued by every country in the table.
  passport('PASSPORT', 'Passport', UseSmileIDSampleCountry.values),

  /// British spelling, as the design sets it.
  driversLicense(
    'DRIVERS_LICENSE',
    "Driver's licence",
    <UseSmileIDSampleCountry>[
      UseSmileIDSampleCountry.ng,
      UseSmileIDSampleCountry.ke,
      UseSmileIDSampleCountry.za,
    ],
  ),

  /// Only two countries issue one.
  voterId('VOTER_ID', 'Voter ID', <UseSmileIDSampleCountry>[
    UseSmileIDSampleCountry.ng,
    UseSmileIDSampleCountry.gh,
  ]);

  const UseSmileIDSampleIdType(this.id, this.label, this.countries);

  /// The id that suffixes this row's test id.
  final String id;

  /// The type's name, which is what the search filters on.
  final String label;

  /// The countries that issue it.
  final List<UseSmileIDSampleCountry> countries;

  /// The types [country] issues, empty when no country is chosen yet.
  static List<UseSmileIDSampleIdType> of(UseSmileIDSampleCountry? country) =>
      country == null
      ? const <UseSmileIDSampleIdType>[]
      : UseSmileIDSampleIdType.values
            .where(
              (UseSmileIDSampleIdType type) => type.countries.contains(country),
            )
            .toList();
}

/// What the ID-details form has collected.
class UseSmileIDSampleIdDetails {
  /// Every field starts empty; nothing is prefilled, not even from the active profile.
  const UseSmileIDSampleIdDetails({
    this.country,
    this.idType,
    this.idNumber = '',
  });

  /// The chosen country.
  final UseSmileIDSampleCountry? country;

  /// The chosen ID type, which a country change clears.
  final UseSmileIDSampleIdType? idType;

  /// The typed number; the only rule on it is an IME capitalisation hint.
  final String idNumber;

  /// Whether Continue is offered: all three, and a blank-only number does not count.
  bool get isComplete =>
      country != null && idType != null && idNumber.trim().isNotEmpty;

  /// A copy with [country] chosen, which CLEARS the type: the old country's types may not apply.
  UseSmileIDSampleIdDetails withCountry(UseSmileIDSampleCountry country) =>
      UseSmileIDSampleIdDetails(country: country, idNumber: idNumber);

  /// A copy with [idType] chosen.
  UseSmileIDSampleIdDetails withIdType(UseSmileIDSampleIdType idType) =>
      UseSmileIDSampleIdDetails(
        country: country,
        idType: idType,
        idNumber: idNumber,
      );

  /// A copy with [idNumber] typed.
  UseSmileIDSampleIdDetails withIdNumber(String idNumber) =>
      UseSmileIDSampleIdDetails(
        country: country,
        idType: idType,
        idNumber: idNumber,
      );
}
