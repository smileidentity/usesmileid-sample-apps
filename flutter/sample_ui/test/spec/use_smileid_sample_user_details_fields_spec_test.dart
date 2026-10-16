import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'spec_file.dart';

/// spec/user-details-fields.json: which user-details rows the form shows for a product.
void main() {
  final Map<String, Object?> file = spec('user-details-fields.json');
  final List<Map<String, Object?>> cases = objects(file['cases']);

  String outcome(
    UseSmileIDSampleUserDetailsRequirement requirement,
    UseSmileIDSampleUserField field,
  ) => !requirement.shows(field)
      ? 'hidden'
      : requirement.supplies(field)
      ? 'provided'
      : 'ask';

  test('every product reads the spec key', () {
    final Map<String, Object?> keys =
        file['productKeys']! as Map<String, Object?>;
    expect(
      keys.keys.toSet(),
      UseSmileIDSampleProduct.values
          .map((UseSmileIDSampleProduct it) => it.id)
          .toSet(),
    );
    for (final UseSmileIDSampleProduct product
        in UseSmileIDSampleProduct.values) {
      expect(product.fieldsToCollectKey, keys[product.id], reason: product.id);
    }
  });

  test('only the spec products read ID-type entries', () {
    expect(
      UseSmileIDSampleProduct.values
          .where((UseSmileIDSampleProduct it) => it.readsIdTypes)
          .map((UseSmileIDSampleProduct it) => it.id)
          .toSet(),
      (file['idTypeProducts']! as List<Object?>).cast<String>().toSet(),
    );
  });

  test('every case matches the spec', () {
    expect(cases, isNotEmpty);
    for (final Map<String, Object?> c in cases) {
      final String name = c['name']! as String;
      final UseSmileIDSampleProduct product = UseSmileIDSampleProduct.values
          .singleWhere((UseSmileIDSampleProduct it) => it.id == c['product']);
      final Object? section = c['fieldsToCollect'];
      final Map<String, List<UseSmileIDSampleApiField>>? fields =
          section is Map<String, Object?>
          ? UseSmileIDSampleCatalogueJson.fieldsToCollectSection(section)
          : null;
      final Object? products = c['products'];
      final UseSmileIDSampleIdTypeFields? idTypeFields =
          products is Map<String, Object?>
          ? UseSmileIDSampleCatalogueJson.idTypeFieldsSection(products)
          : null;
      final Map<String, Object?> bound = c['bindings']! as Map<String, Object?>;
      final UseSmileIDSampleTokenBindings bindings =
          UseSmileIDSampleTokenBindings(
            givenNames: bound['givenNames'] == true,
            lastName: bound['lastName'] == true,
            email: bound['email'] == true,
            phoneNumber: bound['phoneNumber'] == true,
          );
      final UseSmileIDSampleUserDetailsRequirement requirement =
          useSmileIDSampleUserDetailsRequirementFor(
            bindings,
            product,
            fields,
            idTypeFields,
          );
      final Map<String, Object?> expected =
          c['expect']! as Map<String, Object?>;
      expect(
        outcome(requirement, UseSmileIDSampleUserField.firstName),
        expected['firstName'],
        reason: '$name: firstName',
      );
      expect(
        outcome(requirement, UseSmileIDSampleUserField.lastName),
        expected['lastName'],
        reason: '$name: lastName',
      );
      expect(
        requirement.contact ? 'ask' : 'provided',
        expected['contact'],
        reason: '$name: contact',
      );
      const UseSmileIDSampleUserDetails typed = UseSmileIDSampleUserDetails(
        firstName: 'Ada',
        lastName: 'Okafor',
        email: 'ada@example.com',
      );
      for (final Map<String, Object?> pick in objects(
        c['submit'] ?? <Object?>[],
      )) {
        final List<UseSmileIDSampleApiField>? entry = idTypeFields.entryFor(
          product,
          pick['country'] as String?,
          pick['idType'] as String?,
        );
        final UseSmileIDSampleUserDetails sent = typed.withoutHiddenNames(
          const UseSmileIDSampleUserDetailsRequirement(),
          entry: entry,
        );
        final String at = '$name: ${pick['country']} ${pick['idType']}';
        expect(
          sent.firstName.isEmpty ? 'dropped' : 'sent',
          pick['firstName'],
          reason: '$at firstName',
        );
        expect(
          sent.lastName.isEmpty ? 'dropped' : 'sent',
          pick['lastName'],
          reason: '$at lastName',
        );
      }
    }
  });

  test('a config that does not parse keeps the token rule', () {
    expect(UseSmileIDSampleCatalogueJson.fieldsToCollect('not json'), isNull);
    expect(
      UseSmileIDSampleCatalogueJson.fieldsToCollect('{"products": {}}'),
      isEmpty,
    );
    expect(UseSmileIDSampleCatalogueJson.idTypeFields('not json'), isNull);
    expect(
      UseSmileIDSampleCatalogueJson.idTypeFields('{"fields_to_collect": {}}'),
      isEmpty,
    );
  });

  test('an ID-type entry it cannot read is skipped', () {
    expect(
      UseSmileIDSampleCatalogueJson.idTypeFieldsSection(<String, Object?>{
        'enhanced_kyc': <String, Object?>{
          'KE': <Object?>[
            <String, Object?>{'label': 'No key'},
            <String, Object?>{
              'key_name': 'NATIONAL_ID',
              'fields': <Object?>[
                <String, Object?>{'key_name': 'given_names', 'required': true},
                <String, Object?>{'label': 'no key'},
              ],
            },
          ],
          'GH': 'not a list',
        },
        'biometric_kyc': 'not an object',
      }),
      <String, Object?>{
        'enhanced_kyc': <String, Object?>{
          'KE': <String, Object?>{
            'NATIONAL_ID': <UseSmileIDSampleApiField>[
              const UseSmileIDSampleApiField('given_names', required: true),
            ],
          },
          'GH': <String, Object?>{},
        },
        'biometric_kyc': <String, Object?>{},
      },
    );
  });

  test('hidden names never hold the form back and submit nothing', () {
    const UseSmileIDSampleUserDetailsRequirement requirement =
        UseSmileIDSampleUserDetailsRequirement(
          firstName: false,
          lastName: false,
          hidden: <UseSmileIDSampleUserField>{
            UseSmileIDSampleUserField.firstName,
            UseSmileIDSampleUserField.lastName,
          },
        );
    const UseSmileIDSampleUserDetails typed = UseSmileIDSampleUserDetails(
      firstName: 'Ada',
      lastName: 'Okafor',
      email: 'ada@example.com',
    );
    expect(
      requirement.isSatisfiedBy(
        const UseSmileIDSampleUserDetails(email: 'ada@example.com'),
      ),
      isTrue,
    );
    expect(requirement.supplies(UseSmileIDSampleUserField.firstName), isFalse);
    expect(
      typed.withoutHiddenNames(requirement),
      const UseSmileIDSampleUserDetails(email: 'ada@example.com'),
    );
    expect(
      typed.withoutHiddenNames(const UseSmileIDSampleUserDetailsRequirement()),
      typed,
    );
  });
}
