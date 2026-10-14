import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_routes.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_version.dart';

/// The route table is spec data, so it is asserted against `spec/`, not against itself.
void main() {
  late List<Map<String, Object?>> routes;

  setUpAll(() {
    final Map<String, Object?> table =
        jsonDecode(File('../../spec/routes.json').readAsStringSync())
            as Map<String, Object?>;
    routes = (table['routes']! as List<Object?>).cast<Map<String, Object?>>();
  });

  List<String> pathsWhere(bool Function(Map<String, Object?>) predicate) =>
      routes
          .where(predicate)
          .map((Map<String, Object?> route) => route['path']! as String)
          .toList();

  test('the three tab roots are the three the spec calls tabs', () {
    expect(
      UseSmileIDSampleRoutes.tabRoots,
      pathsWhere(
        (Map<String, Object?> route) => route['presentation'] == 'tab',
      ),
    );
  });

  test('every path this app names is the path the spec gives it', () {
    String specPath(String id) =>
        routes.firstWhere(
              (Map<String, Object?> route) => route['id'] == id,
            )['path']!
            as String;

    expect(UseSmileIDSampleRoutes.products, specPath('products'));
    expect(UseSmileIDSampleRoutes.verifications, specPath('verifications'));
    expect(UseSmileIDSampleRoutes.settings, specPath('settings'));
    expect(UseSmileIDSampleRoutes.licenses, specPath('licenses'));
    expect(
      UseSmileIDSampleRoutes.verificationDetails('job-1'),
      specPath('verificationDetails').replaceAll(':jobId', 'job-1'),
    );
  });

  test('the nav bar is drawn on the tab roots', () {
    for (final String root in UseSmileIDSampleRoutes.tabRoots) {
      expect(useSmileIDSampleShowsNavBar(root), isTrue, reason: root);
    }
  });

  // R13's defect: testing a tab's BRANCH rather than its destination put a bar on pushed screens.
  test('the nav bar is drawn on no pushed route', () {
    // Matched on a prefix, not equality: `push | fullScreen` is a pushed route too, and an
    // equality test silently dropped it — the one route the flow opens.
    final List<String> pushed = pathsWhere(
      (Map<String, Object?> route) =>
          (route['presentation']! as String).startsWith('push'),
    );
    // Named, not merely non-empty: the flow route is the one an equality match dropped, so a
    // future narrowing fails here rather than passing on the seven that still matched.
    expect(pushed, contains('/flow/:productId/run'));
    for (final String path in pushed) {
      expect(useSmileIDSampleShowsNavBar(path), isFalse, reason: path);
    }
  });

  // A sheet is a layer over its owner, so the bar belongs to the page behind the scrim rather than to the sheet.
  test('a sheet takes the bar of the page it is layered over', () {
    // Every sheet, not just the modal ones: the pickers are `fullSheet`, so matching `modalSheet`
    // alone left the two routes this test's own comment claims to cover unasserted.
    final List<String> sheets = pathsWhere(
      (Map<String, Object?> route) =>
          (route['presentation']! as String).endsWith('Sheet'),
    );
    // Named for the same reason: both pickers are `fullSheet` and were the routes this test
    // claimed to cover while matching only `modalSheet`.
    expect(
      sheets,
      containsAll(<String>[
        '/flow/:productId/id-details/country',
        '/flow/:productId/id-details/id-type',
        '/debug/scenarios',
      ]),
    );
    for (final String path in sheets) {
      expect(
        useSmileIDSampleShowsNavBar(path),
        UseSmileIDSampleRoutes.tabRoots.contains(
          useSmileIDSamplePageBehind(path),
        ),
        reason: path,
      );
    }
    expect(
      useSmileIDSampleShowsNavBar(UseSmileIDSampleRoutes.scenarioDrawer),
      isTrue,
    );
    expect(
      useSmileIDSampleShowsNavBar(
        UseSmileIDSampleRoutes.countryPicker('biometric_kyc'),
      ),
      isFalse,
    );
  });

  // The three rules above partition the table, so a presentation value none of them matches would
  // otherwise escape unasserted — which is exactly how `push | fullScreen` and `fullSheet` did.
  test('every route the spec lists is covered by one of the bar rules', () {
    final List<String> uncovered = pathsWhere((Map<String, Object?> route) {
      final String presentation = route['presentation']! as String;
      return presentation != 'tab' &&
          !presentation.startsWith('push') &&
          !presentation.endsWith('Sheet');
    });
    expect(uncovered, isEmpty, reason: 'unclassified presentation');
  });

  test('the component gallery is a dev route the spec deliberately omits', () {
    expect(
      pathsWhere((_) => true),
      isNot(contains(UseSmileIDSampleRoutes.components)),
    );
    expect(
      useSmileIDSampleShowsNavBar(UseSmileIDSampleRoutes.components),
      isFalse,
    );
  });

  test('the settings footer names the version the pubspec declares', () {
    // Read with a pattern rather than a YAML parser, which would be a dependency for one line.
    final RegExpMatch? declared = RegExp(
      r'^version:\s*(\d+\.\d+\.\d+)',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync());
    final String version = declared!.group(1)!;
    expect(useSmileIDSampleVersionLabel, endsWith(version));
  });
  _tabOrderIsOneContract();
}

/// The shell reads `UseSmileIDSampleNavItem.values[shell.currentIndex]` and navigates with `item.index`.
void _tabOrderIsOneContract() {
  test('the nav items are in the same order as the tab roots', () {
    expect(
      UseSmileIDSampleNavItem.values.length,
      UseSmileIDSampleRoutes.tabRoots.length,
    );
    final List<String> expected = <String>[
      UseSmileIDSampleTestIds.navProducts,
      UseSmileIDSampleTestIds.navVerifications,
      UseSmileIDSampleTestIds.navSettings,
    ];
    for (int i = 0; i < expected.length; i++) {
      expect(
        UseSmileIDSampleNavItem.values[i].testId,
        expected[i],
        reason: 'nav item $i',
      );
      expect(
        UseSmileIDSampleRoutes.tabRoots[i],
        <String>[
          UseSmileIDSampleRoutes.products,
          UseSmileIDSampleRoutes.verifications,
          UseSmileIDSampleRoutes.settings,
        ][i],
        reason: 'tab root $i',
      );
    }
  });
}
