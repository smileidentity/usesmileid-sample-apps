import 'package:flutter/foundation.dart';

/// One component a partner ships, and the licence text it carries.
@immutable
class UseSmileIDSampleNotice {
  /// [licenseName] is null when no known signature matched, which is a label the screen omits
  /// rather than a licence it guesses at.
  const UseSmileIDSampleNotice({
    required this.component,
    required this.text,
    this.licenseId,
    this.licenseName,
  });

  /// The package or engine dependency the notice belongs to.
  final String component;

  /// The component's own licence text, verbatim.
  final String text;

  /// The SPDX id where a signature matched.
  final String? licenseId;

  /// The licence's display name, shown beneath the component.
  final String? licenseName;
}

/// The third-party notices, as the screen renders them.
@immutable
class UseSmileIDSampleLicenses {
  /// [components] is already sorted and carries no first-party entry.
  const UseSmileIDSampleLicenses({
    this.components = const <UseSmileIDSampleNotice>[],
  });

  /// Every notice the app ships.
  final List<UseSmileIDSampleNotice> components;

  /// Whether the notices reached this build at all.
  bool get isEmpty => components.isEmpty;

  /// Reads the notices Flutter's own build step collected into the bundle.
  ///
  /// The toolchain regenerates them from the resolved graph on every build, so unlike a committed
  /// asset they cannot go stale, and they already cover the engine's C++ dependencies.
  static Future<UseSmileIDSampleLicenses> bundled({
    Stream<LicenseEntry>? licenses,
  }) async => from(await (licenses ?? LicenseRegistry.licenses).toList());

  /// Groups entries by component, because one entry can name several packages and one package can
  /// appear in several entries.
  static UseSmileIDSampleLicenses from(Iterable<LicenseEntry> entries) {
    final Map<String, StringBuffer> byComponent = <String, StringBuffer>{};
    for (final LicenseEntry entry in entries) {
      final String text = entry.paragraphs
          .map((LicenseParagraph paragraph) => paragraph.text.trim())
          .where((String it) => it.isNotEmpty)
          .join('\n\n');
      if (text.isEmpty) {
        continue;
      }
      for (final String package in entry.packages) {
        if (_isFirstParty(package)) {
          continue;
        }
        final StringBuffer buffer = byComponent.putIfAbsent(
          package,
          StringBuffer.new,
        );
        if (buffer.isNotEmpty) {
          buffer.write('\n\n');
        }
        buffer.write(text);
      }
    }
    final List<String> names = byComponent.keys.toList()..sort();
    return UseSmileIDSampleLicenses(
      components: <UseSmileIDSampleNotice>[
        for (final String name in names)
          _notice(name, byComponent[name]!.toString()),
      ],
    );
  }
}

/// Licensed from Smile ID rather than a third party; `sample_ui`'s own identity is the same case.
bool _isFirstParty(String package) =>
    package.startsWith('usesmileid') || package == 'sample_ui';

UseSmileIDSampleNotice _notice(String component, String text) {
  final String lowered = text.toLowerCase().split(RegExp(r'\s+')).join(' ');
  for (final _Signature signature in _signatures) {
    if (signature.needles.every(lowered.contains)) {
      return UseSmileIDSampleNotice(
        component: component,
        text: text,
        licenseId: signature.id,
        licenseName: signature.name,
      );
    }
  }
  return UseSmileIDSampleNotice(component: component, text: text);
}

/// A licence recognisable from its own wording.
@immutable
class _Signature {
  const _Signature(this.id, this.name, this.needles);

  final String id;
  final String name;
  final List<String> needles;
}

/// Ordered: the first match wins, so a licence naming another inside its text cannot claim it.
const List<_Signature> _signatures = <_Signature>[
  _Signature('MPL-2.0', 'Mozilla Public License 2.0', <String>[
    'mozilla public license version 2.0',
  ]),
  _Signature('Apache-2.0', 'Apache License, Version 2.0', <String>[
    'apache license',
    'version 2.0',
  ]),
  _Signature('APSL-2.0', 'Apple Public Source License 2.0', <String>[
    'apple public source license',
  ]),
  // The third clause is the only thing separating these two, so it is what the match keys on.
  _Signature('BSD-3-Clause', 'BSD 3-Clause License', <String>[
    'redistributions in binary form',
    'endorse or promote products derived',
  ]),
  _Signature('BSD-2-Clause', 'BSD 2-Clause License', <String>[
    'redistributions in binary form',
  ]),
  _Signature('MIT', 'MIT License', <String>[
    'permission is hereby granted, free of charge',
  ]),
];
