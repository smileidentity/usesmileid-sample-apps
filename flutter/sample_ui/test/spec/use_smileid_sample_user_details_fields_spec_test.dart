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
      final Map<String, Object?> bound = c['bindings']! as Map<String, Object?>;
      final UseSmileIDSampleTokenBindings bindings =
          UseSmileIDSampleTokenBindings(
            givenNames: bound['givenNames'] == true,
            lastName: bound['lastName'] == true,
            email: bound['email'] == true,
            phoneNumber: bound['phoneNumber'] == true,
          );
      final UseSmileIDSampleUserDetailsRequirement requirement =
          useSmileIDSampleUserDetailsRequirementFor(bindings, product, fields);
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
    }
  });

  test('a config that does not parse keeps the token rule', () {
    expect(UseSmileIDSampleCatalogueJson.fieldsToCollect('not json'), isNull);
    expect(
      UseSmileIDSampleCatalogueJson.fieldsToCollect('{"products": {}}'),
      isEmpty,
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
