import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_error_move.dart';

/// Where each failure action takes the user, per the `does` lines of spec/error-handling.json, under the gate a product tap passes.
void main() {
  const UseSmileIDSampleProduct product = UseSmileIDSampleProduct.biometricKyc;
  const List<UseSmileIDSampleErrorAction> reruns =
      <UseSmileIDSampleErrorAction>[
        UseSmileIDSampleErrorAction.retry,
        UseSmileIDSampleErrorAction.retryLater,
        UseSmileIDSampleErrorAction.recapture,
      ];

  UseSmileIDSampleErrorMove move(
    UseSmileIDSampleErrorAction action, {
    bool sessionLive = true,
    String? livePartnerId = 'partner_1',
    String? runPartnerId = 'partner_1',
    UseSmileIDSampleIdDetailsSource idDetails =
        UseSmileIDSampleIdDetailsSource.form,
    bool formsHoldRun = true,
  }) => useSmileIDSampleErrorMove(
    action,
    product,
    sessionLive: sessionLive,
    livePartnerId: livePartnerId,
    runPartnerId: runPartnerId,
    idDetails: idDetails,
    formsHoldRun: formsHoldRun,
  );

  Matcher newToken(UseSmileIDSampleResumePoint resumeAt) =>
      isA<UseSmileIDSampleNewToken>()
          .having(
            (UseSmileIDSampleNewToken it) => it.product,
            'product',
            product,
          )
          .having(
            (UseSmileIDSampleNewToken it) => it.resumeAt,
            'resumeAt',
            resumeAt,
          );

  test(
    "a retry a later retry and a recapture run the verification again on the run's own partner",
    () {
      for (final UseSmileIDSampleErrorAction action in reruns) {
        expect(
          move(action),
          isA<UseSmileIDSampleRunAgain>().having(
            (UseSmileIDSampleRunAgain it) => it.product,
            'product',
            product,
          ),
          reason: action.name,
        );
      }
    },
  );

  test(
    'a rerun on another or an unknown partner starts from the first step',
    () {
      for (final UseSmileIDSampleErrorAction action in reruns) {
        expect(
          move(action, livePartnerId: 'partner_2'),
          isA<UseSmileIDSampleRunFromStart>(),
          reason: action.name,
        );
        expect(
          move(action, livePartnerId: 'partner_2', runPartnerId: null),
          isA<UseSmileIDSampleRunFromStart>(),
          reason: action.name,
        );
      }
    },
  );

  test('a rerun with no live session scans first and resumes in the flow', () {
    for (final UseSmileIDSampleErrorAction action in reruns) {
      expect(
        move(action, sessionLive: false),
        newToken(UseSmileIDSampleResumePoint.flow),
        reason: action.name,
      );
    }
  });

  test(
    'fixing the input returns to the id form or scans first with no live session',
    () {
      expect(
        move(UseSmileIDSampleErrorAction.fixInput),
        isA<UseSmileIDSampleEditIdDetails>(),
      );
      expect(
        move(UseSmileIDSampleErrorAction.fixInput, sessionLive: false),
        newToken(UseSmileIDSampleResumePoint.firstStep),
      );
    },
  );

  test(
    'fixing the input on another partner starts from the first step with fresh forms',
    () {
      expect(
        move(UseSmileIDSampleErrorAction.fixInput, livePartnerId: 'partner_2'),
        isA<UseSmileIDSampleRunFromStart>(),
      );
    },
  );

  test(
    'fixing input the token carries takes a new token and a product with no id form starts again',
    () {
      expect(
        move(
          UseSmileIDSampleErrorAction.fixInput,
          idDetails: UseSmileIDSampleIdDetailsSource.token,
        ),
        newToken(UseSmileIDSampleResumePoint.firstStep),
      );
      expect(
        move(
          UseSmileIDSampleErrorAction.fixInput,
          idDetails: UseSmileIDSampleIdDetailsSource.none,
        ),
        isA<UseSmileIDSampleRunFromStart>(),
      );
    },
  );

  test('starting again takes a new token first', () {
    expect(
      move(UseSmileIDSampleErrorAction.newSession),
      newToken(UseSmileIDSampleResumePoint.flow),
    );
  });

  test('close leaves the run', () {
    expect(
      move(UseSmileIDSampleErrorAction.exit),
      isA<UseSmileIDSampleLeave>(),
    );
  });

  test(
    'once another product tap has reset the forms every move starts the product afresh',
    () {
      for (final UseSmileIDSampleErrorAction action in reruns) {
        expect(
          move(action, formsHoldRun: false),
          isA<UseSmileIDSampleRunFromStart>(),
          reason: action.name,
        );
        expect(
          move(action, sessionLive: false, formsHoldRun: false),
          newToken(UseSmileIDSampleResumePoint.firstStep),
          reason: action.name,
        );
      }
      expect(
        move(UseSmileIDSampleErrorAction.fixInput, formsHoldRun: false),
        isA<UseSmileIDSampleRunFromStart>(),
      );
      expect(
        move(UseSmileIDSampleErrorAction.newSession, formsHoldRun: false),
        newToken(UseSmileIDSampleResumePoint.firstStep),
      );
    },
  );

  test('a run whose product was not kept can only leave', () {
    for (final UseSmileIDSampleErrorAction action
        in UseSmileIDSampleErrorAction.values) {
      expect(
        useSmileIDSampleErrorMove(
          action,
          null,
          sessionLive: true,
          livePartnerId: 'p',
          runPartnerId: 'p',
          idDetails: UseSmileIDSampleIdDetailsSource.form,
          formsHoldRun: true,
        ),
        isA<UseSmileIDSampleLeave>(),
        reason: action.name,
      );
    }
  });
}
