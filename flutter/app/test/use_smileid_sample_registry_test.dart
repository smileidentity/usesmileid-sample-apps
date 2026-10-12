@Tags(<String>['registry'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Asserts the app consumes the published SDK; an SDK repo's source build of this app excludes the tag.
void main() {
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
