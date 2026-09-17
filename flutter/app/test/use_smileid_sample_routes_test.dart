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

  // R13's defect in one assertion: testing a tab's BRANCH instead of its destination put a bar on
  // pushed screens the design draws without one. Verification details is the case that found it —
  // it lives in the verifications branch and still has no bar.
  test('the nav bar is drawn on nothing else the spec routes to', () {
    final List<String> elsewhere = pathsWhere(
      (Map<String, Object?> route) => route['presentation'] != 'tab',
    );
    expect(elsewhere, isNotEmpty);
    for (final String path in elsewhere) {
      expect(useSmileIDSampleShowsNavBar(path), isFalse, reason: path);
    }
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

/// The shell reads `UseSmileIDSampleNavItem.values[shell.currentIndex]` and navigates with
/// `item.index`, so the enum's order and the branch order are one contract with nothing holding
/// them together. Reordering either silently highlights or opens the wrong tab: it compiles, and
/// the three symmetric cases still pass. This is the assertion that fails instead.
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
