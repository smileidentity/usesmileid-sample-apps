import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

void main() {
  testWidgets('each row keeps its own keyboard once the names are hidden', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: UseSmileIDSampleTheme.light(),
        home: Material(
          child: UseSmileIDSampleUserDetailsScreen(
            title: 'Enhanced KYC',
            details: const UseSmileIDSampleUserDetails(),
            onBack: () {},
            onFieldChanged: (UseSmileIDSampleUserField _, String _) {},
            onContinue: () {},
            requirement: const UseSmileIDSampleUserDetailsRequirement(
              firstName: false,
              lastName: false,
              hidden: <UseSmileIDSampleUserField>{
                UseSmileIDSampleUserField.firstName,
                UseSmileIDSampleUserField.lastName,
              },
            ),
            profile: null,
            onProfileTap: () {},
            onSaveToProfileChanged: (bool _) {},
            organisation: '',
            onOrganisationChanged: (String _) {},
          ),
        ),
      ),
    );

    for (final UseSmileIDSampleUserField field in <UseSmileIDSampleUserField>[
      UseSmileIDSampleUserField.email,
      UseSmileIDSampleUserField.phone,
    ]) {
      final UseSmileIDSampleKeyValueEditRow row = tester
          .widget<UseSmileIDSampleKeyValueEditRow>(
            find.byWidgetPredicate(
              (Widget widget) =>
                  widget is UseSmileIDSampleKeyValueEditRow &&
                  widget.testId ==
                      UseSmileIDSampleTestIds.userDetailsField(field.id),
            ),
          );
      expect(row.keyboardType, field.keyboardType, reason: field.id);
    }
  });
}
