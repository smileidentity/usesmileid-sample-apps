import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'spec_file.dart';

void main() {
  late Set<String> specIds;

  setUpAll(() {
    final Map<String, Object?> ids =
        spec('test-ids.json')['ids']! as Map<String, Object?>;
    specIds = ids.values
        .expand(objects)
        .map((Map<String, Object?> it) => it['id']! as String)
        .toSet();
  });

  test('the spec file is readable', () {
    expect(
      specIds.length,
      greaterThan(40),
      reason: 'extracted only ${specIds.length} ids',
    );
  });

  test('every declared id exists in the spec', () {
    expect(
      UseSmileIDSampleTestIds.all.where((String it) => !specIds.contains(it)),
      isEmpty,
    );
  });

  test('every declared id carries the sample prefix', () {
    expect(
      UseSmileIDSampleTestIds.all.where(
        (String it) => !it.startsWith('sample_'),
      ),
      isEmpty,
    );
  });

  test('the declared set has no duplicates', () {
    expect(
      UseSmileIDSampleTestIds.all.toSet().length,
      UseSmileIDSampleTestIds.all.length,
    );
  });
}
