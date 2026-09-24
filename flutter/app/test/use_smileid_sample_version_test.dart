import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_version.dart';

/// The footer the app ships, against the spec and the build's own version, never a copy of either.
void main() {
  test(
    'the settings footer is the spec copy, carrying the pubspec version',
    () {
      final List<Object?> screens =
          (jsonDecode(File('../../spec/screens.json').readAsStringSync())
                  as Map<String, Object?>)['screens']!
              as List<Object?>;
      final Map<String, Object?> settings = screens
          .cast<Map<String, Object?>>()
          .firstWhere((Map<String, Object?> it) => it['id'] == 'settings');
      final String footer =
          (settings['copy']! as Map<String, Object?>)['footer']! as String;
      final String version = RegExp(
        r'^version:\s*([0-9.]+)',
        multiLine: true,
      ).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1)!;

      expect(
        useSmileIDSampleVersionLabel,
        footer.replaceFirst('1.0.0', version),
      );
      expect(useSmileIDSampleVersionLabel, endsWith(' · $version'));
    },
  );
}
