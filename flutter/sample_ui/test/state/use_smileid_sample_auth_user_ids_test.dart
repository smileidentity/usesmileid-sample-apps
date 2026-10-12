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

  List<String> previousIds(
    List<UseSmileIDSampleJob> jobs, {
    required String? partnerId,
    required bool sandbox,
  }) => useSmileIDSamplePreviousAuthUsers(
    jobs,
    partnerId: partnerId,
    sandbox: sandbox,
  ).map((UseSmileIDSampleJob found) => found.userId).toList();

  test('each user is offered with the newest run that enrolled it', () {
    expect(
      useSmileIDSamplePreviousAuthUsers(
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
            UseSmileIDSampleStatus.clear,
            2,
          ),
          job(
            'user_a',
            UseSmileIDSampleProduct.documentVerification,
            UseSmileIDSampleStatus.clear,
            3,
          ),
        ],
        partnerId: _partner,
        sandbox: true,
      ).map((UseSmileIDSampleJob found) => found.id),
      <String>['job_3', 'job_2'],
    );
  });

  test('a long user ID keeps its head and tail', () {
    expect(
      job(
        'user_01m4gahg4ceceatsw25mc5dd1h',
        UseSmileIDSampleProduct.smartSelfieEnrollment,
        UseSmileIDSampleStatus.clear,
        1,
      ).middleUserId,
      'user_01m4…mc5dd1h',
    );
    expect(
      job(
        'user_short',
        UseSmileIDSampleProduct.smartSelfieEnrollment,
        UseSmileIDSampleStatus.clear,
        1,
      ).middleUserId,
      'user_short',
    );
  });

  test('newest first and once each, from every product that enrols a user', () {
    expect(
      previousIds(
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
      previousIds(
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
      expect(previousIds(jobs, partnerId: _partner, sandbox: true), <String>[
        'user_mine',
      ]);
      expect(previousIds(jobs, partnerId: null, sandbox: true), isEmpty);
    },
  );
}

const String _partner = 'partner-a';
