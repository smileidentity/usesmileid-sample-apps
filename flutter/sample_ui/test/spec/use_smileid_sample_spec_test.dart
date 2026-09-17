import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'spec_file.dart';

void main() {
  late Map<String, Object?> scenarios;

  setUpAll(() => scenarios = spec('scenarios.json'));

  List<String> idsOf(String kind) => objects(scenarios['scenarios'])
      .where((Map<String, Object?> it) => it['kind'] == kind)
      .map((Map<String, Object?> it) => it['id']! as String)
      .toList();

  List<Map<String, Object?>> products() {
    final Map<String, Object?> grid =
        scenarios['products']! as Map<String, Object?>;
    return objects(grid['sections'])
        .expand((Map<String, Object?> section) => objects(section['items']))
        .toList();
  }

  test('flow scenarios match the spec', () {
    final List<String> expected = idsOf('flow');
    expect(expected, isNotEmpty, reason: 'extracted no flow scenarios');
    expect(
      UseSmileIDSampleScenario.values.map(
        (UseSmileIDSampleScenario it) => it.id,
      ),
      expected,
    );
  });

  test('theme scenarios match the spec', () {
    final List<String> expected = idsOf('theme');
    expect(expected, isNotEmpty, reason: 'extracted no theme scenarios');
    expect(
      UseSmileIDSampleThemeScenario.values.map(
        (UseSmileIDSampleThemeScenario it) => it.id,
      ),
      expected,
    );
  });

  test('products match the spec in design order', () {
    final List<String> expected = products()
        .map((Map<String, Object?> it) => it['id']! as String)
        .toList();
    expect(expected, isNotEmpty, reason: 'extracted no products');
    expect(
      UseSmileIDSampleProduct.values.map((UseSmileIDSampleProduct it) => it.id),
      expected,
    );
  });

  test('labels, card titles and card families match the spec', () {
    // Four platforms must abbreviate identically: "Enhanced Doc." and "Enh. Doc" are both reasonable.
    expect(
      UseSmileIDSampleProduct.values
          .map(
            (UseSmileIDSampleProduct it) => <String>[
              it.label,
              it.cardTitle,
              it.cardFamily,
            ],
          )
          .toList(),
      products()
          .map(
            (Map<String, Object?> it) => <String>[
              it['label']! as String,
              it['cardTitle']! as String,
              it['cardFamily']! as String,
            ],
          )
          .toList(),
    );
  });

  test('the capture and ID-details flags match the spec', () {
    expect(
      UseSmileIDSampleProduct.values
          .map(
            (UseSmileIDSampleProduct it) => <bool>[
              it.capture,
              it.needsIdDetails,
              it.needsUserDetails,
            ],
          )
          .toList(),
      products()
          .map(
            (Map<String, Object?> it) => <bool>[
              it['capture']! as bool,
              it['needsIdDetails']! as bool,
              it['needsUserDetails']! as bool,
            ],
          )
          .toList(),
    );
  });

  test('the SmartSelfie products carry the mark', () {
    expect(
      UseSmileIDSampleProduct.values
          .where(
            (UseSmileIDSampleProduct it) =>
                it.cardFamily == UseSmileIDSampleMarks.smartSelfie,
          )
          .map((UseSmileIDSampleProduct it) => it.id),
      <String>['smartSelfieEnrollment', 'smartSelfieAuth'],
    );
  });

  test('the captureless product is the one the spec names', () {
    expect(
      UseSmileIDSampleProduct.values
          .where((UseSmileIDSampleProduct it) => !it.capture)
          .map((UseSmileIDSampleProduct it) => it.id),
      <String>['enhancedKyc'],
    );
  });

  test('the two section headings are the ones the ruling settled', () {
    expect(
      UseSmileIDSampleProductSection.values.map(
        (UseSmileIDSampleProductSection it) => it.label,
      ),
      <String>['Authentication', 'Onboarding'],
    );
  });

  test('the four statuses are Title case, not upper-cased', () {
    expect(
      UseSmileIDSampleStatus.values.map(
        (UseSmileIDSampleStatus it) => it.label,
      ),
      <String>['Clear', 'Attention', 'Blocked', 'Processing'],
    );
  });

  test('each status maps onto the feedback role the spec names', () {
    expect(
      UseSmileIDSampleStatus.values.map((UseSmileIDSampleStatus it) => it.role),
      <String>['success', 'warning', 'error', 'info'],
    );
  });
}
