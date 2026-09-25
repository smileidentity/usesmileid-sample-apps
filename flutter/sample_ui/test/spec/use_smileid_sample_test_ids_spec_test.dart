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

  test('every spec id is declared, or excused with its reason', () {
    const Map<String, String> excused = <String, String>{
      'sample_env_chip': 'the chip is hidden on every shipped screen',
      'sample_license_link':
          'every Flutter licence ships its text in NOTICES, so none opens a page',
    };
    final Set<String> declared = <String>{
      ...UseSmileIDSampleTestIds.all,
      for (final String built in <String>[
        UseSmileIDSampleTestIds.tokenEnvironment('x'),
        UseSmileIDSampleTestIds.productCard('x'),
        UseSmileIDSampleTestIds.filterChip('x'),
        UseSmileIDSampleTestIds.filterCount('x'),
        UseSmileIDSampleTestIds.jobRow(0).replaceFirst('_0', '_x'),
        UseSmileIDSampleTestIds.selectionCheckbox(0).replaceFirst('_0', '_x'),
        UseSmileIDSampleTestIds.detailField('x'),
        UseSmileIDSampleTestIds.detailCopy('x'),
        UseSmileIDSampleTestIds.profileRow('x'),
        UseSmileIDSampleTestIds.profileConfigField('x'),
        UseSmileIDSampleTestIds.userDetailsField('x'),
        UseSmileIDSampleTestIds.countryOption('x'),
        UseSmileIDSampleTestIds.idTypeOption('x'),
        UseSmileIDSampleTestIds.scenarioItem('x'),
        UseSmileIDSampleTestIds.themeItem('x'),
        UseSmileIDSampleTestIds.licenseRow('x'),
        UseSmileIDSampleTestIds.licenseText('x'),
      ])
        built.substring(0, built.length - 2),
    };
    expect(
      specIds.where(
        (String it) => !declared.contains(it) && !excused.containsKey(it),
      ),
      isEmpty,
    );
    expect(excused.keys.where(declared.contains), isEmpty);
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
