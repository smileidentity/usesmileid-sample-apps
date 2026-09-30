import 'dart:convert';

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

  String token(String header) => <String>[header, '{}', 'not-a-signature']
      .map(
        (String part) =>
            base64Url.encode(utf8.encode(part)).replaceAll('=', ''),
      )
      .join('.');

  test('an unsigned token reads the fixture', () async {
    final String unsigned = token('{"alg":"none","typ":"JWT"}');
    expect(
      await source.servicesConfig(sandbox, unsigned, 'en-GB'),
      await fixture.servicesConfig(sandbox, unsigned, 'en-GB'),
    );
  });

  test('a signed token asks the server', () {
    expect(
      source.servicesConfig(
        sandbox,
        token('{"alg":"HS256","typ":"JWT"}'),
        'en-GB',
      ),
      throwsStateError,
    );
  });
}
