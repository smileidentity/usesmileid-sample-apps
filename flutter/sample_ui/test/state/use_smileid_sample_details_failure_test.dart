import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// Which failure verification details states, and how its banner reads.
void main() {
  final UseSmileIDSampleErrorResolution serverError =
      UseSmileIDSampleErrorHandling.forStatus(503);

  UseSmileIDSampleJob job(UseSmileIDSampleStatus status) => UseSmileIDSampleJob(
    id: 'job_1',
    userId: 'user_1',
    product: UseSmileIDSampleProduct.biometricKyc,
    status: status,
    createdAtMillis: 0,
    message: 'Rejected',
    httpStatus: 200,
  );

  test('a run that failed before any job states its own row', () {
    expect(
      useSmileIDSampleDetailsFailure(job: null, landedRun: serverError),
      serverError,
    );
  });

  test(
    'a failed run no submission explains states the submission fallback',
    () {
      expect(
        useSmileIDSampleLandedFailure(
          status: UseSmileIDSampleFlowStatus.failed,
          row: null,
        )?.id,
        'requestInvalid',
      );
    },
  );

  test('a run that did not fail lands with no failure', () {
    for (final UseSmileIDSampleFlowStatus status
        in <UseSmileIDSampleFlowStatus>[
          UseSmileIDSampleFlowStatus.captured,
          UseSmileIDSampleFlowStatus.succeeded,
          UseSmileIDSampleFlowStatus.cancelled,
        ]) {
      expect(
        useSmileIDSampleLandedFailure(status: status, row: serverError),
        isNull,
        reason: status.name,
      );
    }
    expect(
      useSmileIDSampleLandedFailure(
        status: UseSmileIDSampleFlowStatus.failed,
        row: serverError,
      ),
      serverError,
    );
  });

  test('a missing job with no failed run states nothing', () {
    expect(useSmileIDSampleDetailsFailure(job: null, landedRun: null), isNull);
  });

  test(
    'a job that ended in error or block states the fallback until the status carries a reason',
    () {
      for (final UseSmileIDSampleStatus status in <UseSmileIDSampleStatus>[
        UseSmileIDSampleStatus.error,
        UseSmileIDSampleStatus.blocked,
      ]) {
        expect(
          useSmileIDSampleDetailsFailure(
            job: job(status),
            landedRun: serverError,
          )?.id,
          'notVerified',
          reason: status.name,
        );
      }
    },
  );

  test(
    'a job with any other status states nothing even after a failed run',
    () {
      for (final UseSmileIDSampleStatus status in <UseSmileIDSampleStatus>[
        UseSmileIDSampleStatus.clear,
        UseSmileIDSampleStatus.attention,
        UseSmileIDSampleStatus.processing,
      ]) {
        expect(
          useSmileIDSampleDetailsFailure(
            job: job(status),
            landedRun: serverError,
          ),
          isNull,
          reason: status.name,
        );
      }
    },
  );

  test(
    'a failure the user can act on is a warning and a final one an error',
    () {
      expect(serverError.bannerTone, UseSmileIDSampleBannerTone.warning);
      expect(
        UseSmileIDSampleErrorHandling.forReason(null).bannerTone,
        UseSmileIDSampleBannerTone.error,
      );
    },
  );

  test(
    'a stored job leaves close to the back button but a failed run offers it',
    () {
      final UseSmileIDSampleErrorResolution finalRow =
          UseSmileIDSampleErrorHandling.forReason(null);
      expect(finalRow.action, UseSmileIDSampleErrorAction.exit);
      expect(finalRow.offersAction(onStoredJob: true), isFalse);
      expect(finalRow.offersAction(onStoredJob: false), isTrue);
      expect(serverError.offersAction(onStoredJob: true), isTrue);
    },
  );
}
