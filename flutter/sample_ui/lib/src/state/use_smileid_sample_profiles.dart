import 'use_smileid_sample_launch_args.dart';

/// The fields the design labels "attached to every job", which is why every product collects them.
class UseSmileIDSampleUserDetails {
  /// Every field starts empty; the forms fill them and the profile keeps them.
  const UseSmileIDSampleUserDetails({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phone = '',
  });

  /// Given name.
  final String firstName;

  /// Family name.
  final String lastName;

  /// Email address.
  final String email;

  /// Phone number.
  final String phone;

  /// The design's own rule: "First and last name are required."
  bool get isComplete =>
      firstName.trim().isNotEmpty && lastName.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleUserDetails &&
      other.firstName == firstName &&
      other.lastName == lastName &&
      other.email == email &&
      other.phone == phone;

  @override
  int get hashCode => Object.hash(firstName, lastName, email, phone);
}

/// The four fields a profile carries, in the order the design lists them.
///
/// The ids are camelCase because they suffix the test ids, and a device flow keys off those.
enum UseSmileIDSampleUserField {
  /// Given name; required.
  firstName('firstName', 'First name', 'Add first name', true),

  /// Family name; required.
  lastName('lastName', 'Last name', 'Add last name', true),

  /// Email; never gates anything.
  email('email', 'Email (optional)', 'name@company.com', false),

  /// Phone; never gates anything.
  phone('phone', 'Phone (optional)', '+254 700 000 000', false);

  const UseSmileIDSampleUserField(
    this.id,
    this.label,
    this.placeholder,
    this.isRequired,
  );

  /// The id that suffixes this field's test id.
  final String id;

  /// The row's label; the asterisk is appended by the row, not written here.
  final String label;

  /// Shown while the value is empty.
  final String placeholder;

  /// Whether the design marks it required.
  final bool isRequired;

  /// This field's value on [details].
  String valueOf(UseSmileIDSampleUserDetails details) => switch (this) {
    UseSmileIDSampleUserField.firstName => details.firstName,
    UseSmileIDSampleUserField.lastName => details.lastName,
    UseSmileIDSampleUserField.email => details.email,
    UseSmileIDSampleUserField.phone => details.phone,
  };

  /// A copy of [details] with this field set to [value].
  UseSmileIDSampleUserDetails apply(
    UseSmileIDSampleUserDetails details,
    String value,
  ) => switch (this) {
    UseSmileIDSampleUserField.firstName => UseSmileIDSampleUserDetails(
      firstName: value,
      lastName: details.lastName,
      email: details.email,
      phone: details.phone,
    ),
    UseSmileIDSampleUserField.lastName => UseSmileIDSampleUserDetails(
      firstName: details.firstName,
      lastName: value,
      email: details.email,
      phone: details.phone,
    ),
    UseSmileIDSampleUserField.email => UseSmileIDSampleUserDetails(
      firstName: details.firstName,
      lastName: details.lastName,
      email: value,
      phone: details.phone,
    ),
    UseSmileIDSampleUserField.phone => UseSmileIDSampleUserDetails(
      firstName: details.firstName,
      lastName: details.lastName,
      email: details.email,
      phone: value,
    ),
  };
}

/// One partner identity the app can act as; its organisation is what the SDK names as the partner.
class UseSmileIDSampleProfile {
  /// [person] may be blank, which is what the starter is until its details are saved.
  const UseSmileIDSampleProfile({
    required this.id,
    required this.organisation,
    required this.person,
    this.defaults = const UseSmileIDSampleUserDetails(),
  });

  /// The stable id, which also suffixes this profile's test ids.
  final String id;

  /// The partner organisation.
  final String organisation;

  /// The person acting for it, blank until details are saved.
  final String person;

  /// What the forms pre-fill from.
  final UseSmileIDSampleUserDetails defaults;

  /// The person's initials, as the design has them, falling back to the organisation.
  String get initials {
    final List<String> words = (person.trim().isEmpty ? organisation : person)
        .split(' ')
        .where((String word) => word.trim().isNotEmpty)
        .take(2)
        .toList();
    final String letters = words
        .map((String word) => word[0].toUpperCase())
        .join();
    return letters.isEmpty ? '?' : letters;
  }

  /// What a row says under the organisation: the person, or a placeholder until details are saved.
  String get caption => person.trim().isEmpty ? _noUserDetailsCaption : person;

  /// A copy with [defaults] replaced, naming the person from them where none was given.
  UseSmileIDSampleProfile withDefaults(
    UseSmileIDSampleUserDetails details,
  ) => UseSmileIDSampleProfile(
    id: id,
    organisation: organisation,
    // The starter names nobody until its details are saved; a created profile keeps its own name.
    person: person.trim().isEmpty
        ? '${details.firstName} ${details.lastName}'.trim()
        : person,
    defaults: details,
  );
}

/// The profiles the app can act as, and which one is active.
///
/// In memory, like the twin: profiles are not an account concern yet, so nothing here is persisted
/// and a launch with no arguments starts from one empty starter.
class UseSmileIDSampleProfiles {
  /// [seed] must not be empty; an empty list would surface far from here, as the products screen
  /// throwing on its first read of the active profile.
  UseSmileIDSampleProfiles([List<UseSmileIDSampleProfile>? seed])
    : _items = List<UseSmileIDSampleProfile>.of(seed ?? starter()) {
    if (_items.isEmpty) {
      throw ArgumentError.value(seed, 'seed', 'needs at least one profile');
    }
    _activeId = _items.first.id;
  }

  /// The fixtures only when `seedProfiles` asks, so the shell holds no choice a test cannot reach.
  factory UseSmileIDSampleProfiles.forLaunch(UseSmileIDSampleLaunchArgs args) =>
      UseSmileIDSampleProfiles(args.seedProfiles ? fixtures() : starter());

  final List<UseSmileIDSampleProfile> _items;

  late String _activeId;

  String? _lastCreatedId;

  /// Every profile, in the order that decides their avatar hues.
  List<UseSmileIDSampleProfile> get all =>
      List<UseSmileIDSampleProfile>.unmodifiable(_items);

  /// The active profile's id.
  String get activeId => _activeId;

  /// The active profile.
  UseSmileIDSampleProfile get active =>
      _items.firstWhere((UseSmileIDSampleProfile p) => p.id == _activeId);

  /// Position in the list, which is what picks a profile's avatar hue.
  int get activeIndex =>
      _items.indexWhere((UseSmileIDSampleProfile p) => p.id == _activeId);

  /// The last profile [add] created, until whoever confirmed it calls [clearLastCreated].
  String? get lastCreatedId => _lastCreatedId;

  /// Switches the active profile, ignoring an id this store does not hold.
  void setActive(String id) {
    if (_items.any((UseSmileIDSampleProfile p) => p.id == id)) {
      _activeId = id;
    }
  }

  /// Forgets the just-created marker.
  void clearLastCreated() => _lastCreatedId = null;

  /// The profile with [id], or null.
  UseSmileIDSampleProfile? find(String id) {
    for (final UseSmileIDSampleProfile profile in _items) {
      if (profile.id == id) {
        return profile;
      }
    }
    return null;
  }

  /// Adds a profile and returns it.
  UseSmileIDSampleProfile add({
    required String organisation,
    required String person,
    UseSmileIDSampleUserDetails defaults = const UseSmileIDSampleUserDetails(),
  }) {
    // First free id, not one derived from the count: a duplicate key doubles a test id.
    int candidate = _items.length + 1;
    while (_items.any((UseSmileIDSampleProfile p) => p.id == 'p-$candidate')) {
      candidate++;
    }
    final UseSmileIDSampleProfile profile = UseSmileIDSampleProfile(
      id: 'p-$candidate',
      organisation: organisation,
      person: person,
      defaults: defaults,
    );
    _items.add(profile);
    _lastCreatedId = profile.id;
    return profile;
  }

  /// Saves a profile's form defaults, ignoring an id this store does not hold.
  void setDefaults(String id, UseSmileIDSampleUserDetails defaults) {
    final int index = _items.indexWhere(
      (UseSmileIDSampleProfile p) => p.id == id,
    );
    if (index >= 0) {
      _items[index] = _items[index].withDefaults(defaults);
    }
  }

  /// The one empty profile a launch with no arguments starts from.
  static List<UseSmileIDSampleProfile> starter() => <UseSmileIDSampleProfile>[
    const UseSmileIDSampleProfile(
      id: 'p-1',
      organisation: starterOrganisation,
      person: '',
    ),
  ];

  /// The design's three, which only `seedProfiles` reaches.
  static List<UseSmileIDSampleProfile> fixtures() => <UseSmileIDSampleProfile>[
    const UseSmileIDSampleProfile(
      id: 'p-1',
      organisation: 'UpTech Finance',
      person: 'Kwame Asante',
      defaults: UseSmileIDSampleUserDetails(
        firstName: 'Kwame',
        lastName: 'Asante',
      ),
    ),
    const UseSmileIDSampleProfile(
      id: 'p-2',
      organisation: 'Kazi Microlending',
      person: 'Amina Diallo',
      defaults: UseSmileIDSampleUserDetails(
        firstName: 'Amina',
        lastName: 'Diallo',
      ),
    ),
    const UseSmileIDSampleProfile(
      id: 'p-3',
      organisation: 'PesaLink',
      person: 'Tunde Okafor',
      defaults: UseSmileIDSampleUserDetails(
        firstName: 'Tunde',
        lastName: 'Okafor',
      ),
    ),
  ];

  /// Named on the consent screen as the partner until a profile is created, so it reads as a placeholder.
  static const String starterOrganisation = 'Default profile';
}

/// What a profile row says when no details have been saved.
const String _noUserDetailsCaption = 'No user details yet';
