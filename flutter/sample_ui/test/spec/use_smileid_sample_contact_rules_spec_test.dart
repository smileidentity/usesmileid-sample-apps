import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'spec_file.dart';

/// spec/contact-rules.json: which emails and phone numbers pass, what each submits, and the error it shows.
void main() {
  final Map<String, Object?> file = spec('contact-rules.json');
  final List<Map<String, Object?>> cases = objects(file['cases']);

  UseSmileIDSampleUserField field(Object? name) => name == 'email'
      ? UseSmileIDSampleUserField.email
      : UseSmileIDSampleUserField.phone;

  test('every case matches the spec', () {
    expect(cases, isNotEmpty);
    for (final Map<String, Object?> c in cases) {
      final String value = c['value']! as String;
      final bool valid = c['valid']! as bool;
      expect(
        UseSmileIDSampleContactRules.problem(field(c['field']), value) == null,
        valid,
        reason: '${c['field']} "$value"',
      );
      if (valid) {
        expect(
          UseSmileIDSampleContactRules.submitted(field(c['field']), value),
          c['submits'],
          reason: '${c['field']} "$value"',
        );
      }
    }
  });

  test('the errors are the spec sentences', () {
    expect(
      UseSmileIDSampleContactRules.problem(
        UseSmileIDSampleUserField.email,
        'ada',
      ),
      (file['email']! as Map<String, Object?>)['error'],
    );
    expect(
      UseSmileIDSampleContactRules.problem(
        UseSmileIDSampleUserField.phone,
        '0700',
      ),
      (file['phone']! as Map<String, Object?>)['error'],
    );
  });

  test(
    'a bad contact keeps the form from continuing, a blank one does not',
    () {
      const UseSmileIDSampleUserDetailsRequirement requirement =
          UseSmileIDSampleUserDetailsRequirement();
      const UseSmileIDSampleUserDetails named = UseSmileIDSampleUserDetails(
        firstName: 'Ada',
        lastName: 'Okafor',
        email: 'ada@example.com',
      );
      expect(requirement.isSatisfiedBy(named), isTrue);
      expect(
        requirement.isSatisfiedBy(
          const UseSmileIDSampleUserDetails(
            firstName: 'Ada',
            lastName: 'Okafor',
            email: 'ada@example.com',
            phone: '0700000000',
          ),
        ),
        isFalse,
      );
    },
  );

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
