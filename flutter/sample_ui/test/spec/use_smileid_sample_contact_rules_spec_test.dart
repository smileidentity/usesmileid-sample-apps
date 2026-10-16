import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'spec_file.dart';

/// spec/contact-rules.json: what each email and phone number submits, and that no form checks either.
void main() {
  final Map<String, Object?> file = spec('contact-rules.json');
  final List<Map<String, Object?>> cases = objects(file['cases']);

  UseSmileIDSampleUserField field(Object? name) => name == 'email'
      ? UseSmileIDSampleUserField.email
      : UseSmileIDSampleUserField.phone;

  test('every case submits as the spec says', () {
    expect(cases, isNotEmpty);
    for (final Map<String, Object?> c in cases) {
      final String value = c['value']! as String;
      expect(
        UseSmileIDSampleContactRules.submitted(field(c['field']), value),
        c['submits'],
        reason: '${c['field']} "$value"',
      );
    }
  });

  test('no contact holds the form back', () {
    const UseSmileIDSampleUserDetailsRequirement requirement =
        UseSmileIDSampleUserDetailsRequirement();
    for (final Map<String, Object?> c in cases.where(
      (Map<String, Object?> c) => (c['submits']! as String).isNotEmpty,
    )) {
      final String value = c['value']! as String;
      final UseSmileIDSampleUserDetails details = field(c['field']).apply(
        const UseSmileIDSampleUserDetails(firstName: 'Ada', lastName: 'Okafor'),
        value,
      );
      expect(
        requirement.isSatisfiedBy(details),
        isTrue,
        reason: '${c['field']} "$value"',
      );
    }
  });

  test('the submitted phone has no separators', () {
    expect(
      const UseSmileIDSampleUserDetails(
        phone: '+254 700 000 000',
      ).submittedPhone,
      '+254700000000',
    );
    expect(
      const UseSmileIDSampleUserDetails(phone: '  ').submittedPhone,
      isNull,
    );
  });
}
