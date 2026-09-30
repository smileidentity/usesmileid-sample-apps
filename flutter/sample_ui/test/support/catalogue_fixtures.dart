import 'dart:convert';
import 'dart:io';

import 'package:sample_ui/sample_ui.dart';

/// The rows spec/catalogue-fixture.json yields, read through the same decoder and rules the app runs.
abstract final class CatalogueFixtures {
  /// The fixture file's text.
  static final String json = File(
    '../../spec/catalogue-fixture.json',
  ).readAsStringSync();

  static final Map<String, Object?> _root =
      jsonDecode(json) as Map<String, Object?>;

  /// Both responses, decoded as the store decodes them.
  static final UseSmileIDSampleCatalogueData data =
      UseSmileIDSampleCatalogueData(
        UseSmileIDSampleCatalogueJson.idTypes(
          jsonEncode(_root['supported_id_types']),
        )!,
        UseSmileIDSampleCatalogueJson.documents(
          jsonEncode(_root['supported_documents']),
        )!,
      );

  /// The partner configuration's Enhanced Document Verification list, decoded as the store decodes it.
  static final List<UseSmileIDSampleApiEnabledCountry> enabled =
      UseSmileIDSampleCatalogueJson.enabledCountries(
        jsonEncode(_root['services_config']),
      )!;

  /// Kenya, as the fixture names it.
  static const UseSmileIDSampleCountry kenya = UseSmileIDSampleCountry(
    'KE',
    'Kenya',
  );

  /// South Africa, as the fixture names it.
  static const UseSmileIDSampleCountry southAfrica = UseSmileIDSampleCountry(
    'ZA',
    'South Africa',
  );

  /// The countries [family] offers.
  static List<UseSmileIDSampleCountry> countries(
    UseSmileIDSampleCatalogueFamily family,
  ) => UseSmileIDSampleCatalogueRules.countries(data, family);

  /// The ID types [country] offers.
  static List<UseSmileIDSampleKycIdType> idTypes(String country) =>
      UseSmileIDSampleCatalogueRules.idTypes(data.idTypes, country);

  /// The documents [country] offers.
  static List<UseSmileIDSampleDocument> documents(
    String country, {
    UseSmileIDSampleProduct product =
        UseSmileIDSampleProduct.documentVerification,
  }) => UseSmileIDSampleCatalogueRules.documents(
    data.documents,
    country,
    product: product,
  );
}
