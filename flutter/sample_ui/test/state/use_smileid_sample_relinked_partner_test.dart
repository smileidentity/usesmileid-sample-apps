import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// A relinked partner may not enable what was picked for the last one.
void main() {
  const UseSmileIDSampleCountry kenya = UseSmileIDSampleCountry('KE', 'Kenya');
  const UseSmileIDSampleDocument passport = UseSmileIDSampleDocument(
    code: 'PASSPORT',
    name: 'Passport',
    hasBack: false,
    format: 3,
  );
  const UseSmileIDSampleIdDetails picked = UseSmileIDSampleIdDetails(
    country: kenya,
    document: passport,
  );

  test('a partner that lacks the country drops every pick', () {
    final UseSmileIDSampleIdDetails kept = picked.withEnabledOnly(
      <UseSmileIDSampleCountry>[const UseSmileIDSampleCountry('NG', 'Nigeria')],
      null,
    );
    expect(kept.country, isNull);
    expect(kept.document, isNull);
  });

  test('a partner that lacks only the document keeps the country', () {
    final UseSmileIDSampleIdDetails kept = picked.withEnabledOnly(
      <UseSmileIDSampleCountry>[kenya],
      <UseSmileIDSampleDocument>[
        const UseSmileIDSampleDocument(
          code: 'NATIONAL_ID',
          name: 'National ID',
          hasBack: true,
          format: 1,
        ),
      ],
    );
    expect(kept.country, kenya);
    expect(kept.document, isNull);
  });

  test('a list still loading keeps the picks, unchanged', () {
    expect(identical(picked.withEnabledOnly(null, null), picked), isTrue);
  });

  test('only the same partner resumes straight into the SDK', () {
    const UseSmileIDSampleRunIntent expired = UseSmileIDSampleRunIntent(
      productId: 'enhancedDocumentVerification',
      route: UseSmileIDSampleFlowRoute.shell,
    );
    expect(
      expired.resumesInFlow(runPartnerId: 'p-1', linkedPartnerId: 'p-1'),
      isTrue,
    );
    expect(
      expired.resumesInFlow(runPartnerId: 'p-1', linkedPartnerId: 'p-2'),
      isFalse,
    );
    expect(expired.resumesInFlow(linkedPartnerId: 'p-1'), isFalse);
    const UseSmileIDSampleRunIntent tapped = UseSmileIDSampleRunIntent(
      productId: 'enhancedDocumentVerification',
      route: UseSmileIDSampleFlowRoute.shell,
      resumeAt: UseSmileIDSampleResumePoint.firstStep,
    );
    expect(
      tapped.resumesInFlow(runPartnerId: 'p-1', linkedPartnerId: 'p-1'),
      isFalse,
    );
  });
}
