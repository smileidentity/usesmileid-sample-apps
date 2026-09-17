import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'spec_file.dart';

/// A result with every optional field set, so the comparison sees the whole shape.
const UseSmileIDSampleResult _filled = UseSmileIDSampleResult(
  activeScenario: UseSmileIDSampleScenario.normal,
  activeTheme: UseSmileIDSampleThemeScenario.brandDefault,
  route: UseSmileIDSampleFlowRoute.fullscreen,
  environment: UseSmileIDSampleEnvironment.sandbox,
  jobStatus: UseSmileIDSampleFlowStatus.succeeded,
  resultCallbackCount: 1,
  refreshCallbackCount: 0,
  jobId: 'job-1',
  userId: 'user-1',
  lastError: null,
  sdkVersion: null,
);

void main() {
  late Map<String, Object?> schema;

  setUpAll(() => schema = spec('result-card.schema.json'));

  List<String> schemaProperties() =>
      (schema['properties']! as Map<String, Object?>).keys.toList();

  test('the card renders exactly the schema fields', () {
    // `toMap` is what reaches the accessibility tree, so a field missing here is a field a flow
    // cannot read — which is stronger than checking the class declares it.
    final List<String> expected = schemaProperties();
    expect(expected, isNotEmpty, reason: 'extracted no properties from the schema');
    expect(_filled.toMap().keys.toList()..sort(), expected.toList()..sort());
  });

  test('every field the schema requires is present', () {
    final List<String> required = (schema['required']! as List<Object?>).cast<String>();
    expect(required, isNotEmpty, reason: 'extracted no required fields');
    expect(required.where((String it) => !_filled.toMap().containsKey(it)), isEmpty);
  });

  test('the required fields are never null', () {
    final List<String> required = (schema['required']! as List<Object?>).cast<String>();
    final Map<String, Object?> rendered = _filled.toMap();
    expect(required.where((String it) => rendered[it] == null), isEmpty);
  });

  test('the callback counts are integers', () {
    expect(_filled.toMap()['resultCallbackCount'], isA<int>());
    expect(_filled.toMap()['refreshCallbackCount'], isA<int>());
  });

  test('the route values are the ones the schema enumerates', () {
    final Map<String, Object?> route =
        (schema['properties']! as Map<String, Object?>)['route']! as Map<String, Object?>;
    expect(
      UseSmileIDSampleFlowRoute.values.map((UseSmileIDSampleFlowRoute it) => it.id),
      (route['enum']! as List<Object?>).cast<String>(),
    );
  });

  test('the environment values are the ones the schema enumerates', () {
    final Map<String, Object?> environment =
        (schema['properties']! as Map<String, Object?>)['environment']! as Map<String, Object?>;
    expect(
      UseSmileIDSampleEnvironment.values.map((UseSmileIDSampleEnvironment it) => it.id),
      (environment['enum']! as List<Object?>).cast<String>(),
    );
  });

  test('a tokenless run reads sandbox, and the host decides from the parsed claim', () {
    expect(environmentFor(null), isNull);
    expect(environmentFor('https://testapi.smileidentity.com/v3'), UseSmileIDSampleEnvironment.sandbox);
    expect(environmentFor('https://api.smileidentity.com/v3'), UseSmileIDSampleEnvironment.production);
    expect(environmentFor('testapi.smileidentity.com'), isNull);
  });

  test('cancelled and failed stay separate terminal statuses', () {
    expect(
      UseSmileIDSampleFlowStatus.values.map((UseSmileIDSampleFlowStatus it) => it.id),
      <String>['idle', 'running', 'succeeded', 'cancelled', 'failed'],
    );
  });
}
