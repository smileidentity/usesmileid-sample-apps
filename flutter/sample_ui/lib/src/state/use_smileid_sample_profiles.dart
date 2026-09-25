import 'dart:convert';

import 'use_smileid_sample_launch_args.dart';
import 'use_smileid_sample_user_details_requirement.dart';

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
enum UseSmileIDSampleUserField {
  /// Given name; required.
  firstName('firstName', 'First name', 'Add first name', true),

  /// Family name; required.
  lastName('lastName', 'Last name', 'Add last name', true),

  /// Email; never gates anything.
  email('email', 'Email', 'name@company.com', false),

  /// Phone; never gates anything.
  phone('phone', 'Phone', '+254 700 000 000', false);

  const UseSmileIDSampleUserField(
    this.id,
    this.title,
    this.placeholder,
    this.isRequired,
  );

  /// The id that suffixes this field's test id.
  final String id;

  /// The field's title, the one source every screen's label is built from.
  final String title;

  /// The row's label: the title, marked optional where the design does; the row appends any asterisk.
  String get label => isRequired ? title : '$title (optional)';

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

/// One persona a job runs as: the organisation the SDK's consent screen names, and the details its jobs carry.
class UseSmileIDSampleProfile {
  /// [organisation] may be blank, when consent names the app itself rather than the person being verified.
  const UseSmileIDSampleProfile({
    required this.id,
    required this.organisation,
    this.defaults = const UseSmileIDSampleUserDetails(),
    this.callbackUrl = '',
  });

  /// The stable id, which also suffixes this profile's test ids.
  final String id;

  /// The partner organisation, possibly blank.
  final String organisation;

  /// What the forms pre-fill from.
  final UseSmileIDSampleUserDetails defaults;

  /// The webhook URL this profile's jobs report to; empty means the partner's portal default.
  final String callbackUrl;

  /// The person the details name, so it can never disagree with them.
  String get person => '${defaults.firstName} ${defaults.lastName}'.trim();

  /// What a row calls it: the organisation, or the person when it names none.
  String get title => organisation.trim().isNotEmpty
      ? organisation
      : person.isNotEmpty
      ? person
      : _unnamedProfile;

  /// The person's initials, as the design has them, falling back to the organisation.
  String get initials {
    final List<String> words = (person.isEmpty ? organisation : person)
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
  String get caption => person.isEmpty ? _noUserDetailsCaption : person;

  /// A copy with the given parts replaced.
  UseSmileIDSampleProfile copyWith({
    String? organisation,
    UseSmileIDSampleUserDetails? defaults,
    String? callbackUrl,
  }) => UseSmileIDSampleProfile(
    id: id,
    organisation: organisation ?? this.organisation,
    defaults: defaults ?? this.defaults,
    callbackUrl: callbackUrl ?? this.callbackUrl,
  );

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleProfile &&
      other.id == id &&
      other.organisation == organisation &&
      other.defaults == defaults &&
      other.callbackUrl == callbackUrl;

  @override
  int get hashCode => Object.hash(id, organisation, defaults, callbackUrl);
}

/// The profiles the app can act as, and which is active; a plain first launch has none.
class UseSmileIDSampleProfiles {
  /// A stored [activeId] that names no profile falls back to the first; repeated ids keep the first.
  UseSmileIDSampleProfiles([
    List<UseSmileIDSampleProfile> profiles = const <UseSmileIDSampleProfile>[],
    String? activeId,
  ]) : _items = _distinct(profiles) {
    _activeId = _items.any((UseSmileIDSampleProfile p) => p.id == activeId)
        ? activeId
        : (_items.isEmpty ? null : _items.first.id);
  }

  /// The fixtures only when `seedProfiles` asks; never stored.
  factory UseSmileIDSampleProfiles.forLaunch(
    UseSmileIDSampleLaunchArgs args, {
    required UseSmileIDSampleProfiles stored,
  }) => args.seedProfiles ? UseSmileIDSampleProfiles(fixtures()) : stored;

  final List<UseSmileIDSampleProfile> _items;

  String? _activeId;

  String? _lastCreatedId;

  /// Every profile, in the order that decides their avatar hues.
  List<UseSmileIDSampleProfile> get all =>
      List<UseSmileIDSampleProfile>.unmodifiable(_items);

  /// The active profile's id; null exactly when there are no profiles.
  String? get activeId => _activeId;

  /// The active profile, or null while there is none.
  UseSmileIDSampleProfile? get active =>
      _activeId == null ? null : find(_activeId!);

  /// Position in the list, which is what picks a profile's avatar hue.
  int get activeIndex {
    final int index = _items.indexWhere(
      (UseSmileIDSampleProfile p) => p.id == _activeId,
    );
    return index < 0 ? 0 : index;
  }

  /// What the consent screen names as the partner: the app's own name when no profile names one.
  String get partnerName {
    final String organisation = active?.organisation.trim() ?? '';
    return organisation.isEmpty ? noProfilePartnerName : organisation;
  }

  /// The id a job runs under without a token: the first profile's own id when there is none yet.
  String get partnerId => active?.id ?? firstProfileId;

  /// The last profile [add] created without activating, until the list that offers "Make active" consumes it.
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

  /// Adds a profile and returns it; the first ever made becomes active, so a list with profiles always has one.
  UseSmileIDSampleProfile add({
    required String organisation,
    UseSmileIDSampleUserDetails defaults = const UseSmileIDSampleUserDetails(),
    bool activate = false,
  }) {
    // First free id, not one derived from the count: a duplicate key doubles a test id.
    int candidate = _items.length + 1;
    while (_items.any((UseSmileIDSampleProfile p) => p.id == 'p-$candidate')) {
      candidate++;
    }
    final UseSmileIDSampleProfile profile = UseSmileIDSampleProfile(
      id: 'p-$candidate',
      organisation: organisation.trim(),
      defaults: defaults,
    );
    _items.add(profile);
    if (activate || _activeId == null) {
      _activeId = profile.id;
    } else {
      _lastCreatedId = profile.id;
    }
    return profile;
  }

  /// Replaces the given parts of a profile, ignoring an id this store does not hold.
  void update(
    String id, {
    String? organisation,
    UseSmileIDSampleUserDetails? defaults,
    String? callbackUrl,
  }) {
    final int index = _items.indexWhere(
      (UseSmileIDSampleProfile p) => p.id == id,
    );
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        organisation: organisation?.trim(),
        defaults: defaults,
        callbackUrl: callbackUrl?.trim(),
      );
    }
  }

  /// Deleting the active profile hands over to the first one left, so a list with profiles always has one active.
  void delete(String id) {
    _items.removeWhere((UseSmileIDSampleProfile p) => p.id == id);
    if (_activeId == id) {
      _activeId = _items.isEmpty ? null : _items.first.id;
    }
    if (_lastCreatedId == id) {
      _lastCreatedId = null;
    }
  }

  /// Sign out: every profile goes, which is how a phone is handed to the next person.
  void clear() {
    _items.clear();
    _activeId = null;
    _lastCreatedId = null;
  }

  /// Continue's write-back into the active profile, or a new active one; a token-supplied field is never stored.
  void keep(
    UseSmileIDSampleUserDetails details, {
    required String organisation,
    UseSmileIDSampleUserDetailsRequirement requirement =
        const UseSmileIDSampleUserDetailsRequirement(),
  }) {
    final UseSmileIDSampleProfile? current = active;
    UseSmileIDSampleUserDetails kept =
        current?.defaults ?? const UseSmileIDSampleUserDetails();
    for (final UseSmileIDSampleUserField field
        in UseSmileIDSampleUserField.values) {
      if (!requirement.supplies(field)) {
        kept = field.apply(kept, field.valueOf(details));
      }
    }
    if (current != null) {
      update(current.id, defaults: kept);
    } else {
      add(organisation: organisation, defaults: kept, activate: true);
    }
  }

  /// The design's three, which only `seedProfiles` reaches.
  static List<UseSmileIDSampleProfile> fixtures() => <UseSmileIDSampleProfile>[
    const UseSmileIDSampleProfile(
      id: 'p-1',
      organisation: 'UpTech Finance',
      defaults: UseSmileIDSampleUserDetails(
        firstName: 'Kwame',
        lastName: 'Asante',
      ),
    ),
    const UseSmileIDSampleProfile(
      id: 'p-2',
      organisation: 'Kazi Microlending',
      defaults: UseSmileIDSampleUserDetails(
        firstName: 'Amina',
        lastName: 'Diallo',
      ),
    ),
    const UseSmileIDSampleProfile(
      id: 'p-3',
      organisation: 'PesaLink',
      defaults: UseSmileIDSampleUserDetails(
        firstName: 'Tunde',
        lastName: 'Okafor',
      ),
    ),
  ];

  /// The partner the consent screen names when no profile does.
  static const String noProfilePartnerName = 'Smile ID';

  /// What a plain launch has always sent as the partner id, so no profile changes nothing on the wire.
  static const String firstProfileId = 'p-1';

  /// What the header, settings card and form say while there is no profile.
  static const String noProfileLabel = 'No profile yet';

  static List<UseSmileIDSampleProfile> _distinct(
    List<UseSmileIDSampleProfile> profiles,
  ) {
    final Set<String> seen = <String>{};
    return <UseSmileIDSampleProfile>[
      for (final UseSmileIDSampleProfile profile in profiles)
        if (seen.add(profile.id)) profile,
    ];
  }
}

/// The stored form of the profiles, one JSON value shared by all four apps so a record reads the same in each.
abstract final class UseSmileIDSampleProfilesCodec {
  /// The record's version; any other reads as no profiles.
  static const int version = 1;

  /// The whole record as one string.
  static String encode(UseSmileIDSampleProfiles profiles) =>
      jsonEncode(<String, Object?>{
        'version': version,
        'activeId': profiles.activeId,
        'profiles': <Map<String, String>>[
          for (final UseSmileIDSampleProfile p in profiles.all)
            <String, String>{
              'id': p.id,
              'organisation': p.organisation,
              'firstName': p.defaults.firstName,
              'lastName': p.defaults.lastName,
              'email': p.defaults.email,
              'phone': p.defaults.phone,
              'callbackUrl': p.callbackUrl,
            },
        ],
      });

  /// Anything unreadable, including a version this build does not know, is no profiles: never a crash.
  static UseSmileIDSampleProfiles decode(String? text) {
    if (text == null) {
      return UseSmileIDSampleProfiles();
    }
    try {
      final Object? root = jsonDecode(text);
      if (root is! Map<String, Object?> || root['version'] != version) {
        return UseSmileIDSampleProfiles();
      }
      final Object? entries = root['profiles'];
      final Object? activeId = root['activeId'];
      return UseSmileIDSampleProfiles(<UseSmileIDSampleProfile>[
        if (entries is List<Object?>)
          for (final Object? entry in entries)
            if (entry is Map<String, Object?> && _text(entry['id']).isNotEmpty)
              UseSmileIDSampleProfile(
                id: _text(entry['id']),
                organisation: _text(entry['organisation']),
                defaults: UseSmileIDSampleUserDetails(
                  firstName: _text(entry['firstName']),
                  lastName: _text(entry['lastName']),
                  email: _text(entry['email']),
                  phone: _text(entry['phone']),
                ),
                callbackUrl: _text(entry['callbackUrl']),
              ),
      ], activeId is String ? activeId : null);
    } on FormatException {
      return UseSmileIDSampleProfiles();
    }
  }

  static String _text(Object? value) => value is String ? value : '';
}

/// What a profile row says when no details have been saved.
const String _noUserDetailsCaption = 'No user details yet';

/// A profile naming neither an organisation nor a person, which only a token binding both names allows.
const String _unnamedProfile = 'Unnamed profile';
