import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// Which earlier runs offer a user ID to authenticate: those that enrolled one and were not refused or failed.
void main() {
  UseSmileIDSampleJob job(
    String userId,
    UseSmileIDSampleProduct product,
    UseSmileIDSampleStatus status,
    int at,
  ) => UseSmileIDSampleJob(
    id: 'job_$at',
    userId: userId,
    product: product,
    status: status,
    createdAtMillis: at,
  );

  test('newest first and once each, from every product that enrols a user', () {
    expect(
      useSmileIDSamplePreviousAuthUserIds(<UseSmileIDSampleJob>[
        job(
          'user_a',
          UseSmileIDSampleProduct.smartSelfieEnrollment,
          UseSmileIDSampleStatus.clear,
          1,
        ),
        job(
          'user_b',
          UseSmileIDSampleProduct.biometricKyc,
          UseSmileIDSampleStatus.attention,
          3,
        ),
        job(
          'user_c',
          UseSmileIDSampleProduct.documentVerification,
          UseSmileIDSampleStatus.processing,
          2,
        ),
        job(
          'user_a',
          UseSmileIDSampleProduct.enhancedDocumentVerification,
          UseSmileIDSampleStatus.clear,
          4,
        ),
      ]),
      <String>['user_a', 'user_b', 'user_c'],
    );
  });

  test('refused, failed, authentication and Enhanced KYC runs offer none', () {
    expect(
      useSmileIDSamplePreviousAuthUserIds(<UseSmileIDSampleJob>[
        job(
          'user_blocked',
          UseSmileIDSampleProduct.smartSelfieEnrollment,
          UseSmileIDSampleStatus.blocked,
          1,
        ),
        job(
          'user_error',
          UseSmileIDSampleProduct.biometricKyc,
          UseSmileIDSampleStatus.error,
          2,
        ),
        job(
          'user_auth',
          UseSmileIDSampleProduct.smartSelfieAuth,
          UseSmileIDSampleStatus.clear,
          3,
        ),
        job(
          'user_ekyc',
          UseSmileIDSampleProduct.enhancedKyc,
          UseSmileIDSampleStatus.clear,
          4,
        ),
        job(
          ' ',
          UseSmileIDSampleProduct.smartSelfieEnrollment,
          UseSmileIDSampleStatus.clear,
          5,
        ),
      ]),
      isEmpty,
    );
  });
}
