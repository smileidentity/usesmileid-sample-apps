import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// The SDK's rule minus what the token binds, which is what every form row and the skip read from.
void main() {
  test('no token asks for everything', () {
    expect(
      useSmileIDSampleUserDetailsRequirement(null),
      const UseSmileIDSampleUserDetailsRequirement(),
    );
  });

  test(
    'bound names are supplied rows, and one bound contact lifts the contact rule',
    () {
      final UseSmileIDSampleUserDetailsRequirement requirement =
          useSmileIDSampleUserDetailsRequirement(
            const UseSmileIDSampleTokenBindings(
              givenNames: true,
              lastName: true,
              email: true,
            ),
          );
      expect(requirement.isSatisfied, isTrue);
      expect(requirement.supplies(UseSmileIDSampleUserField.firstName), isTrue);
      expect(requirement.supplies(UseSmileIDSampleUserField.lastName), isTrue);
      // "One of", so neither contact row is individually supplied.
      expect(requirement.supplies(UseSmileIDSampleUserField.email), isFalse);
      expect(requirement.supplies(UseSmileIDSampleUserField.phone), isFalse);
    },
  );

  test(
    'names without a contact still ask for one, so the form cannot call itself complete',
    () {
      final UseSmileIDSampleUserDetailsRequirement requirement =
          useSmileIDSampleUserDetailsRequirement(
            const UseSmileIDSampleTokenBindings(
              givenNames: true,
              lastName: true,
            ),
          );
      expect(requirement.isSatisfied, isFalse);
      expect(requirement.prompt, 'An email or phone number is required.');
      expect(
        requirement.isSatisfiedBy(const UseSmileIDSampleUserDetails()),
        isFalse,
      );
      expect(
        requirement.isSatisfiedBy(
          const UseSmileIDSampleUserDetails(phone: '1'),
        ),
        isTrue,
      );
    },
  );

  test('a contact alone still asks for both names', () {
    final UseSmileIDSampleUserDetailsRequirement requirement =
        useSmileIDSampleUserDetailsRequirement(
          const UseSmileIDSampleTokenBindings(phoneNumber: true),
        );
    expect(requirement.firstName, isTrue);
    expect(requirement.lastName, isTrue);
    expect(requirement.contact, isFalse);
  });
}
