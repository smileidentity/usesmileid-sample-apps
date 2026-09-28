import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'spec_file.dart';

/// spec/id-number-hints.json: the example each regex yields, and the check the field runs.
void main() {
  final List<Map<String, Object?>> cases = objects(
    spec('id-number-hints.json')['cases'],
  );

  test('the file has cases inside and outside the subset', () {
    expect(
      cases.where((Map<String, Object?> c) => c['hint'] != null),
      isNotEmpty,
    );
    expect(
      cases.where((Map<String, Object?> c) => c['hint'] == null),
      isNotEmpty,
    );
  });

  test('every hint matches the spec', () {
    for (final Map<String, Object?> c in cases) {
      expect(
        UseSmileIDSampleIdNumberHint.example(c['regex']! as String),
        c['hint'],
        reason: c['regex']! as String,
      );
    }
  });

  test('every example matches its own regex', () {
    for (final Map<String, Object?> c in cases) {
      if (c['hint'] case final String hint) {
        expect(
          UseSmileIDSampleIdNumberHint.accepts(c['regex']! as String, hint),
          isTrue,
          reason: c['regex']! as String,
        );
      }
    }
  });

  test('every regex compiles here', () {
    for (final Map<String, Object?> c in cases) {
      expect(
        UseSmileIDSampleIdNumberHint.compiled(c['regex']! as String),
        isNotNull,
        reason: c['regex']! as String,
      );
    }
  });

  test('the number is trimmed and must match the whole regex', () {
    expect(
      UseSmileIDSampleIdNumberHint.accepts(r'^[0-9]{1,9}$', ' 12345678 '),
      isTrue,
    );
    expect(
      UseSmileIDSampleIdNumberHint.accepts(r'^[0-9]{1,9}$', 'AO12345678'),
      isFalse,
    );
    expect(UseSmileIDSampleIdNumberHint.accepts(r'^[0-9]{1,9}$', ''), isFalse);
  });

  test('a regex this engine cannot compile checks nothing', () {
    expect(UseSmileIDSampleIdNumberHint.accepts('^[0-9', 'anything'), isTrue);
    const UseSmileIDSampleKycIdType type = UseSmileIDSampleKycIdType(
      id: 'X',
      type: 'X',
      label: 'Tax number',
      regex: '^[0-9',
    );
    expect(
      UseSmileIDSampleIdNumberHint.placeholder(type),
      'Enter your Tax number',
    );
    expect(UseSmileIDSampleIdNumberHint.error(type, 'anything'), isNull);
  });

  test('the field waits for a type, then shows the example', () {
    expect(
      UseSmileIDSampleIdNumberHint.placeholder(null),
      'Choose an ID type first',
    );
    const UseSmileIDSampleKycIdType type = UseSmileIDSampleKycIdType(
      id: 'NIN',
      type: 'NIN',
      label: 'National ID',
      regex: r'^[0-9]{11}$',
    );
    expect(UseSmileIDSampleIdNumberHint.placeholder(type), 'e.g. 00000000000');
    expect(
      UseSmileIDSampleIdNumberHint.error(type, '123'),
      "Doesn't match the National ID format, e.g. 00000000000",
    );
  });
}
