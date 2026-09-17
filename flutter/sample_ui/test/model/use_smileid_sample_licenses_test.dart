import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

void main() {
  test('one entry naming several packages becomes one notice each', () {
    final UseSmileIDSampleLicenses licenses = UseSmileIDSampleLicenses.from(
      <LicenseEntry>[
        LicenseEntryWithLineBreaks(const <String>['alpha', 'beta'], _mit),
      ],
    );
    expect(
      licenses.components.map((UseSmileIDSampleNotice it) => it.component),
      <String>['alpha', 'beta'],
    );
  });

  test('a package named by several entries carries both texts', () {
    final UseSmileIDSampleLicenses licenses = UseSmileIDSampleLicenses.from(
      <LicenseEntry>[
        LicenseEntryWithLineBreaks(const <String>['alpha'], _mit),
        LicenseEntryWithLineBreaks(const <String>['alpha'], 'A second notice.'),
      ],
    );
    expect(licenses.components, hasLength(1));
    expect(licenses.components.single.text, contains('free of charge'));
    expect(licenses.components.single.text, contains('A second notice.'));
  });

  /// The SDK is licensed from Smile ID, so its own terms are not a third-party notice.
  test('first-party packages are not listed', () {
    final UseSmileIDSampleLicenses licenses = UseSmileIDSampleLicenses.from(
      <LicenseEntry>[
        LicenseEntryWithLineBreaks(const <String>[
          'usesmileid',
          'usesmileid_bridge',
          'sample_ui',
          'go_router',
        ], _mit),
      ],
    );
    expect(
      licenses.components.map((UseSmileIDSampleNotice it) => it.component),
      <String>['go_router'],
    );
  });

  test('components are sorted', () {
    final UseSmileIDSampleLicenses licenses = UseSmileIDSampleLicenses.from(
      <LicenseEntry>[
        LicenseEntryWithLineBreaks(const <String>['zeta'], _mit),
        LicenseEntryWithLineBreaks(const <String>['alpha'], _mit),
      ],
    );
    expect(
      licenses.components.map((UseSmileIDSampleNotice it) => it.component),
      <String>['alpha', 'zeta'],
    );
  });

  test('an entry with no text is not a component', () {
    expect(
      UseSmileIDSampleLicenses.from(<LicenseEntry>[
        LicenseEntryWithLineBreaks(const <String>['alpha'], '   '),
      ]).isEmpty,
      isTrue,
    );
  });

  group('identification', () {
    /// The third clause is all that separates the two BSD licences, so it is asserted both ways.
    test('BSD-3 is not read as BSD-2', () {
      expect(_idOf(_bsd3), 'BSD-3-Clause');
      expect(_idOf(_bsd2), 'BSD-2-Clause');
    });

    test('each known licence is recognised from its own wording', () {
      expect(_idOf(_mit), 'MIT');
      expect(_idOf(_apache), 'Apache-2.0');
      expect(_idOf(_mpl), 'MPL-2.0');
    });

    /// A licence nobody recognised is shown verbatim with no label, never guessed at.
    test('an unknown licence carries no id and no name', () {
      final UseSmileIDSampleNotice notice = _noticeFor('Some bespoke terms.');
      expect(notice.licenseId, isNull);
      expect(notice.licenseName, isNull);
      expect(notice.text, 'Some bespoke terms.');
    });

    /// Paragraphs are joined with a blank line, so a signature spanning that join needs the
    /// whitespace collapsed before it can match. Registered entries choose their own paragraphs.
    test('a signature matches across a paragraph join', () {
      final UseSmileIDSampleLicenses licenses = UseSmileIDSampleLicenses.from(
        <LicenseEntry>[
          _SplitEntry(<String>[
            'Permission is hereby granted,',
            'free of charge',
          ]),
        ],
      );
      expect(licenses.components.single.licenseId, 'MIT');
    });
  });

  /// The registry is empty under `flutter test`, so these pass fixtures; a red here means real content became assertable.
  testWidgets('the license registry is empty in a widget test', (
    WidgetTester tester,
  ) async {
    expect(await LicenseRegistry.licenses.toList(), isEmpty);
  });

  group('the screen', () {
    testWidgets('a row reveals its licence text and hides it again', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host());
      expect(find.text(_mit), findsNothing);

      await tester.tap(find.text('alpha'));
      await tester.pump();
      expect(find.text(_mit), findsOneWidget);

      await tester.tap(find.text('alpha'));
      await tester.pump();
      expect(find.text(_mit), findsNothing);
    });

    /// Two copies of the Apache text at once is a screen nobody can read.
    testWidgets('only one row is expanded at a time', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host());
      await tester.tap(find.text('alpha'));
      await tester.pump();
      await tester.tap(find.text('beta'));
      await tester.pump();

      expect(find.text(_mit), findsNothing);
      expect(find.text(_apache), findsOneWidget);
    });
  });
}

Widget _host() => MaterialApp(
  theme: UseSmileIDSampleTheme.light(),
  home: UseSmileIDSampleLicensesScreen(
    licenses: UseSmileIDSampleLicenses.from(<LicenseEntry>[
      LicenseEntryWithLineBreaks(const <String>['alpha'], _mit),
      LicenseEntryWithLineBreaks(const <String>['beta'], _apache),
    ]),
    onBack: () {},
  ),
);

String? _idOf(String text) => _noticeFor(text).licenseId;

UseSmileIDSampleNotice _noticeFor(String text) =>
    UseSmileIDSampleLicenses.from(<LicenseEntry>[
      LicenseEntryWithLineBreaks(const <String>['alpha'], text),
    ]).components.single;

const String _mit =
    'Permission is hereby granted, free of charge, to any person obtaining a copy.';

const String _apache = 'Apache License Version 2.0, January 2004';

const String _mpl = 'Mozilla Public License Version 2.0';

const String _bsd3 =
    'Redistributions in binary form must reproduce the above copyright notice. '
    'Neither the name of the copyright holder nor the names of its contributors '
    'may be used to endorse or promote products derived from this software.';

const String _bsd2 =
    'Redistributions in binary form must reproduce the above copyright notice.';

/// An entry that chooses its own paragraph boundaries, which LicenseEntryWithLineBreaks cannot.
class _SplitEntry extends LicenseEntry {
  const _SplitEntry(this.lines);

  final List<String> lines;

  @override
  Iterable<String> get packages => const <String>['alpha'];

  @override
  Iterable<LicenseParagraph> get paragraphs => <LicenseParagraph>[
    for (final String line in lines) LicenseParagraph(line, 0),
  ];
}
