import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// Which earlier runs offer a user ID to authenticate: those that enrolled one and were not refused or failed.
void main() {
  UseSmileIDSampleJob job(
    String userId,
    UseSmileIDSampleProduct product,
    UseSmileIDSampleStatus status,
    int at, {
    String? partnerId = _partner,
    bool sandbox = true,
  }) => UseSmileIDSampleJob(
    id: 'job_$at',
    userId: userId,
    product: product,
    status: status,
    createdAtMillis: at,
    sandbox: sandbox,
    partnerId: partnerId,
  );

  test('newest first and once each, from every product that enrols a user', () {
    expect(
      useSmileIDSamplePreviousAuthUserIds(
        <UseSmileIDSampleJob>[
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
        ],
        partnerId: _partner,
        sandbox: true,
      ),
      <String>['user_a', 'user_b', 'user_c'],
    );
  });

  test('refused, failed, authentication and Enhanced KYC runs offer none', () {
    expect(
      useSmileIDSamplePreviousAuthUserIds(
        <UseSmileIDSampleJob>[
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
        ],
        partnerId: _partner,
        sandbox: true,
      ),
      isEmpty,
    );
  });

  test(
    'another partner\'s users, or this partner\'s in the other environment, are not offered',
    () {
      final List<UseSmileIDSampleJob> jobs = <UseSmileIDSampleJob>[
        job(
          'user_mine',
          UseSmileIDSampleProduct.smartSelfieEnrollment,
          UseSmileIDSampleStatus.clear,
          1,
        ),
        job(
          'user_theirs',
          UseSmileIDSampleProduct.smartSelfieEnrollment,
          UseSmileIDSampleStatus.clear,
          2,
          partnerId: 'partner-b',
        ),
        job(
          'user_production',
          UseSmileIDSampleProduct.smartSelfieEnrollment,
          UseSmileIDSampleStatus.clear,
          3,
          sandbox: false,
        ),
        job(
          'user_fixture',
          UseSmileIDSampleProduct.smartSelfieEnrollment,
          UseSmileIDSampleStatus.clear,
          4,
          partnerId: null,
        ),
      ];
      expect(
        useSmileIDSamplePreviousAuthUserIds(
          jobs,
          partnerId: _partner,
          sandbox: true,
        ),
        <String>['user_mine'],
      );
      expect(
        useSmileIDSamplePreviousAuthUserIds(
          jobs,
          partnerId: null,
          sandbox: true,
        ),
        isEmpty,
      );
    },
  );
}

const String _partner = 'partner-a';
