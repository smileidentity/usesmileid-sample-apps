import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import '../support/catalogue_fixtures.dart';
import 'spec_file.dart';

/// spec/catalogue-rules.json: the pure rules that turn the two responses into picker rows.
void main() {
  final Map<String, Object?> rules = spec('catalogue-rules.json');
  List<Map<String, Object?>> cases(String section) =>
      objects((rules[section]! as Map<String, Object?>)['cases']);

  test('the allowed required fields are the spec\'s', () {
    expect(
      UseSmileIDSampleCatalogueRules.allowedRequiredFields,
      ((rules['idTypes']! as Map<String, Object?>)['allowedRequiredFields']!
              as List<Object?>)
          .toSet(),
    );
  });

  test('every section has cases', () {
    for (final String section in <String>[
      'idTypes',
      'documents',
      'countries',
      'enabledDocuments',
      'enabledCountries',
      'failures',
      'captureAs',
    ]) {
      expect(cases(section), isNotEmpty, reason: section);
    }
  });

  test('id type cases', () {
    for (final Map<String, Object?> c in cases('idTypes')) {
      final List<UseSmileIDSampleApiIdType> all =
          UseSmileIDSampleCatalogueJson.idTypes(
            jsonEncode(<String, Object?>{'id_types': c['input']}),
          )!;
      final List<UseSmileIDSampleKycIdType> got =
          UseSmileIDSampleCatalogueRules.idTypes(all, c['country']! as String);
      expect(
        <Map<String, String>>[
          for (final UseSmileIDSampleKycIdType it in got)
            <String, String>{'id': it.id, 'type': it.type, 'label': it.label},
        ],
        c['expected'],
        reason: c['name']! as String,
      );
    }
  });

  test('document cases', () {
    for (final Map<String, Object?> c in cases('documents')) {
      final List<UseSmileIDSampleApiCountryDocuments> all =
          UseSmileIDSampleCatalogueJson.documents(
            jsonEncode(<String, Object?>{'valid_documents': c['input']}),
          )!;
      final List<UseSmileIDSampleDocument> got =
          UseSmileIDSampleCatalogueRules.documents(
            all,
            c['country']! as String,
            product: UseSmileIDSampleProduct.values.byName(
              c['product'] as String? ?? 'documentVerification',
            ),
          );
      expect(
        <Map<String, Object?>>[
          for (final UseSmileIDSampleDocument it in got)
            <String, Object?>{
              'id': it.id,
              'code': it.code,
              'subType': it.subType,
              'name': it.name,
              'hasBack': it.hasBack,
              'format': it.format,
            },
        ],
        c['expected'],
        reason: c['name']! as String,
      );
    }
  });

  test('country cases', () {
    for (final Map<String, Object?> c in cases('countries')) {
      final Object? input = c['input'];
      final UseSmileIDSampleCatalogueData data =
          input == 'catalogue-fixture.json'
          ? CatalogueFixtures.data
          : UseSmileIDSampleCatalogueData(
              UseSmileIDSampleCatalogueJson.idTypes(
                jsonEncode(
                  (input! as Map<String, Object?>)['supported_id_types'],
                ),
              )!,
              UseSmileIDSampleCatalogueJson.documents(
                jsonEncode(
                  (input as Map<String, Object?>)['supported_documents'],
                ),
              )!,
            );
      final UseSmileIDSampleCatalogueFamily family =
          UseSmileIDSampleCatalogueFamily.values.byName(c['family']! as String);
      expect(
        <Map<String, String>>[
          for (final UseSmileIDSampleCountry it
              in UseSmileIDSampleCatalogueRules.countries(data, family))
            <String, String>{'code': it.code, 'name': it.name},
        ],
        c['expected'],
        reason: c['name']! as String,
      );
    }
  });

  (
    List<UseSmileIDSampleApiCountryDocuments>,
    List<UseSmileIDSampleApiEnabledCountry>,
  )
  enabledInput(Map<String, Object?> c) {
    final Object? input = c['input'];
    if (input == 'catalogue-fixture.json') {
      return (CatalogueFixtures.data.documents, CatalogueFixtures.enabled);
    }
    final Map<String, Object?> both = input! as Map<String, Object?>;
    return (
      UseSmileIDSampleCatalogueJson.documents(
        jsonEncode(both['supported_documents']),
      )!,
      UseSmileIDSampleCatalogueJson.enabledCountries(
        jsonEncode(both['services_config']),
      )!,
    );
  }

  test('enabled document cases', () {
    for (final Map<String, Object?> c in cases('enabledDocuments')) {
      final (
        List<UseSmileIDSampleApiCountryDocuments> all,
        List<UseSmileIDSampleApiEnabledCountry> enabled,
      ) = enabledInput(
        c,
      );
      expect(
        <Map<String, Object?>>[
          for (final UseSmileIDSampleDocument it
              in UseSmileIDSampleCatalogueRules.enabledDocuments(
                all,
                enabled,
                c['country']! as String,
              ))
            <String, Object?>{
              'id': it.id,
              'code': it.code,
              'subType': it.subType,
              'name': it.name,
              'hasBack': it.hasBack,
              'format': it.format,
            },
        ],
        c['expected'],
        reason: c['name']! as String,
      );
    }
  });

  test('enabled country cases', () {
    for (final Map<String, Object?> c in cases('enabledCountries')) {
      final (
        List<UseSmileIDSampleApiCountryDocuments> all,
        List<UseSmileIDSampleApiEnabledCountry> enabled,
      ) = enabledInput(
        c,
      );
      expect(
        <Map<String, String>>[
          for (final UseSmileIDSampleCountry it
              in UseSmileIDSampleCatalogueRules.enabledCountries(all, enabled))
            <String, String>{'code': it.code, 'name': it.name},
        ],
        c['expected'],
        reason: c['name']! as String,
      );
    }
  });

  test('failure cases', () {
    final Map<String, Object?> failures =
        rules['failures']! as Map<String, Object?>;
    expect(
      UseSmileIDSampleCatalogueRules.defaultAdvice.message(_en),
      failures['default'],
    );
    for (final Map<String, Object?> c in cases('failures')) {
      expect(
        UseSmileIDSampleCatalogueRules.advice(c['status'] as int?).message(_en),
        c['supportingText'],
        reason: '${c['status']}',
      );
    }
  });

  final Map<String, Object?> captureAs =
      rules['captureAs']! as Map<String, Object?>;

  test('capture as cases', () {
    for (final Map<String, Object?> c in cases('captureAs')) {
      final String name = c['name']! as String;
      final Map<String, Object?> expected =
          c['expected']! as Map<String, Object?>;
      final UseSmileIDSampleDocument document = _document(c['document']);
      final Map<String, Object?>? sheet =
          c['genericDocument'] as Map<String, Object?>?;
      final UseSmileIDSampleResolvedCaptureAs resolved =
          useSmileIDSampleResolvedCaptureAs(
            document,
            _captureAs(c['captureAs']! as String),
            sheet == null
                ? const UseSmileIDSampleGenericDocument()
                : UseSmileIDSampleGenericDocument(
                    displayName: sheet['displayName']! as String,
                    hasBackSide: sheet['hasBackSide']! as bool,
                    orientation: UseSmileIDSampleDocumentOrientation.values
                        .byName(sheet['orientation']! as String),
                    aspectRatio: UseSmileIDSampleAspectRatio.values.byName(
                      sheet['aspectRatio']! as String,
                    ),
                  ),
          );
      final bool generic =
          resolved.captureAs == UseSmileIDSampleCaptureAs.genericDocument;
      expect(
        generic ? 'generic' : resolved.captureAs.id,
        expected['documentType'],
        reason: name,
      );
      if (generic) {
        expect(
          resolved.genericDocument.displayName,
          expected['displayName'],
          reason: name,
        );
        expect(
          resolved.genericDocument.hasBackSide,
          expected['hasBackSide'],
          reason: name,
        );
        expect(
          resolved.genericDocument.orientation.id,
          expected['orientation'],
          reason: name,
        );
      }
      expect(resolved.matched, expected['matched'], reason: name);
      expect(
        resolved.captureBothSides,
        expected['captureBothSides'],
        reason: name,
      );
      expect(resolved.triggerText(_en), expected['triggerText'], reason: name);
      expect(
        useSmileIDSampleResolvedCaptureAs(
          document,
          null,
          const UseSmileIDSampleGenericDocument(),
        ).matchRowLabel(_en),
        expected['matchRowLabel'],
        reason: name,
      );
    }
  });

  test('capture as reset cases', () {
    for (final Map<String, Object?> c in objects(
      (captureAs['resets']! as Map<String, Object?>)['cases'],
    )) {
      UseSmileIDSampleIdDetails details = const UseSmileIDSampleIdDetails()
          .withCountry(const UseSmileIDSampleCountry('ZA', 'South Africa'))
          .withDocument(_document(c['document']))
          .withCaptureAsOverride(_captureAs(c['captureAs']! as String));
      final Map<String, Object?> change = c['change']! as Map<String, Object?>;
      if (change['document'] case final Object next) {
        details = details.withDocument(_document(next));
      }
      if (change['country'] case final Map<String, Object?> country) {
        details = details.withCountry(
          UseSmileIDSampleCountry(
            country['code']! as String,
            country['name']! as String,
          ),
        );
      }
      expect(
        details.captureAsOverride,
        _captureAs(c['expected']! as String),
        reason: c['name']! as String,
      );
    }
  });

  test('a row the product does not list is dropped with its override', () {
    const UseSmileIDSampleDocument greenBook = UseSmileIDSampleDocument(
      code: 'IDENTITY_CARD',
      subType: 'green_book',
      name: 'Green Book',
      hasBack: false,
      format: 7,
    );
    const UseSmileIDSampleIdDetails details = UseSmileIDSampleIdDetails(
      document: greenBook,
      captureAsOverride: UseSmileIDSampleCaptureAs.passport,
    );
    expect(
      details
          .withDocumentListedOn(UseSmileIDSampleProduct.documentVerification)
          .document,
      greenBook,
    );
    final UseSmileIDSampleIdDetails dropped = details.withDocumentListedOn(
      UseSmileIDSampleProduct.enhancedDocumentVerification,
    );
    expect(dropped.document, isNull);
    expect(dropped.captureAsOverride, isNull);
  });

  test('the trigger placeholder is the spec\'s', () {
    expect(captureAs['triggerPlaceholder'], _en.captureAsMatchDocument);
  });
}

UseSmileIDSampleCaptureAs? _captureAs(String id) => UseSmileIDSampleCaptureAs
    .values
    .where((UseSmileIDSampleCaptureAs it) => it.id == id)
    .firstOrNull;

UseSmileIDSampleDocument _document(Object? raw) {
  final Map<String, Object?> row = raw! as Map<String, Object?>;
  return UseSmileIDSampleDocument(
    code: row['code']! as String,
    subType: row['subType'] as String?,
    name: row['name']! as String,
    hasBack: row['hasBack']! as bool,
    format: row['format']! as int,
  );
}

final UseSmileIDSampleStrings _en = UseSmileIDSampleStrings.forLanguage('en');
