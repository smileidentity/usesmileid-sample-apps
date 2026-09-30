import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import '../support/catalogue_fixtures.dart';

/// A simulated session's unsigned token reads the fixture; a signed one asks the server.
void main() {
  final UseSmileIDSampleFixtureCatalogueSource fixture =
      UseSmileIDSampleFixtureCatalogueSource(CatalogueFixtures.json);
  final UseSmileIDSampleSessionAwareCatalogueSource source =
      UseSmileIDSampleSessionAwareCatalogueSource(
        const UseSmileIDSampleUnreachableCatalogueSource(),
        fixture,
      );
  const UseSmileIDSampleEnvironment sandbox =
      UseSmileIDSampleEnvironment.sandbox;

  test('an unsigned token reads the fixture', () async {
    const String unsigned =
        'eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.e30.c2lnbmF0dXJl';
    expect(
      await source.servicesConfig(sandbox, unsigned, 'en-GB'),
      await fixture.servicesConfig(sandbox, unsigned, 'en-GB'),
    );
  });

  test('a signed token asks the server', () {
    expect(
      source.servicesConfig(
        sandbox,
        'eyJhbGciOiJIUzI1NiJ9.e30.c2lnbmF0dXJl',
        'en-GB',
      ),
      throwsStateError,
    );
  });
}
