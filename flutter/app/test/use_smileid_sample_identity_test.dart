import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The shell is where identity lives, so the shell is where it is asserted against `spec/`.
void main() {
  late Map<String, Object?> flutterApp;

  setUpAll(() {
    final Map<String, Object?> identity =
        jsonDecode(File('../../spec/app-identity.json').readAsStringSync())
            as Map<String, Object?>;
    flutterApp = (identity['apps']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .firstWhere((Map<String, Object?> app) => app['platform'] == 'flutter');
  });

  String gradle() => File('android/app/build.gradle.kts').readAsStringSync();

  String manifest() =>
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

  String pbxproj() =>
      File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

  String plist() => File('ios/Runner/Info.plist').readAsStringSync();

  test('the Android application id is the one the spec assigns', () {
    expect(
      gradle(),
      contains('applicationId = "${flutterApp['applicationId']}"'),
    );
  });

  test(
    'the debug build carries the spec suffix so both variants can be installed',
    () {
      expect(
        gradle(),
        contains('applicationIdSuffix = "${flutterApp['debugSuffix']}"'),
      );
    },
  );

  test('the iOS bundle identifier is the one the spec assigns', () {
    expect(
      pbxproj(),
      contains(
        'PRODUCT_BUNDLE_IDENTIFIER = ${flutterApp['bundleIdentifier']};',
      ),
    );
  });

  test('both platforms carry the display name the spec assigns', () {
    expect(
      manifest(),
      contains('android:label="${flutterApp['displayName']}"'),
    );
    expect(plist(), contains('<string>${flutterApp['displayName']}</string>'));
  });

  test(
    'both platforms declare the URL scheme the spec assigns, and only that one',
    () {
      expect(
        manifest(),
        contains('android:scheme="${flutterApp['urlScheme']}"'),
      );
      expect(plist(), contains('<string>${flutterApp['urlScheme']}</string>'));
      expect(
        RegExp(
          r'android:scheme="([^"]+)"',
        ).allMatches(manifest()).map((Match m) => m[1]).toSet(),
        <String?>{flutterApp['urlScheme'] as String?},
      );
      final RegExp schemes = RegExp(
        r'<key>CFBundleURLSchemes</key>\s*<array>([\s\S]*?)</array>',
      );
      expect(
        schemes
            .allMatches(plist())
            .expand(
              (Match m) => RegExp(
                r'<string>([^<]+)</string>',
              ).allMatches(m[1]!).map((Match s) => s[1]),
            )
            .toList(),
        <String?>[flutterApp['urlScheme'] as String?],
      );
    },
  );

  test('no id reserved by an SDK repo sample is claimed', () {
    // The flutter entry is the contested one the ruling releases, so it is excluded by name.
    final Map<String, Object?> identity =
        jsonDecode(File('../../spec/app-identity.json').readAsStringSync())
            as Map<String, Object?>;
    final Map<String, Object?> reserved =
        identity['reserved']! as Map<String, Object?>;
    final Iterable<String> others = reserved.keys.where(
      (String key) =>
          key != 'comment' &&
          key != flutterApp['applicationId'] &&
          !key.startsWith('usesmileid-sample'),
    );
    expect(others, isNotEmpty, reason: 'parsed no reserved ids');
    for (final String id in others) {
      expect(gradle(), isNot(contains('applicationId = "$id"')));
      expect(pbxproj(), isNot(contains('PRODUCT_BUNDLE_IDENTIFIER = $id;')));
    }
  });

  test(
    'the release lane is minified and resource-shrunk with no app-side keep rules',
    () {
      final String build = gradle();
      expect(build, contains('isMinifyEnabled = true'));
      expect(build, contains('isShrinkResources = true'));
      expect(build, isNot(contains('proguard-rules.pro')));
      expect(File('android/app/proguard-rules.pro').existsSync(), isFalse);
    },
  );

  test('the SDK is resolved from the registry, never by path or override', () {
    // Declarations, not substrings: the manifest's own pin rationale names the thing it forbids.
    final List<String> lines = File('pubspec.yaml')
        .readAsLinesSync()
        .map((String line) => line.trim())
        .where((String line) => !line.startsWith('#'))
        .toList();
    // Exact, not a caret. A bump arrives as a PR, which is what makes every bump a free
    // consumption test; a caret lets a fresh resolve move to a release no PR ever exercised.
    final Iterable<String> sdk = lines.where(
      (String line) => line.startsWith('usesmileid:'),
    );
    expect(sdk, hasLength(1));
    expect(sdk.single, matches(RegExp(r'^usesmileid: \d+\.\d+\.\d+$')));
    expect(
      lines.where((String line) => line.startsWith('dependency_overrides:')),
      isEmpty,
    );
    expect(File('pubspec_overrides.yaml').existsSync(), isFalse);

    final String lock = File('pubspec.lock').readAsStringSync();
    final int sdkEntry = lock.indexOf('\n  usesmileid:\n');
    expect(
      sdkEntry,
      greaterThan(-1),
      reason: 'usesmileid is absent from the lock',
    );
    expect(
      lock.substring(sdkEntry, sdkEntry + 400),
      contains('source: hosted'),
    );
  });
}
