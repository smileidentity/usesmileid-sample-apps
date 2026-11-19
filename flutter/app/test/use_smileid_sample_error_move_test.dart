import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_error_move.dart';

/// Where each failure action takes the user, per the `does` lines of spec/error-handling.json.
void main() {
  const UseSmileIDSampleProduct product = UseSmileIDSampleProduct.biometricKyc;

  test('a retry a later retry and a recapture run the verification again', () {
    for (final UseSmileIDSampleErrorAction action
        in <UseSmileIDSampleErrorAction>[
          UseSmileIDSampleErrorAction.retry,
          UseSmileIDSampleErrorAction.retryLater,
          UseSmileIDSampleErrorAction.recapture,
        ]) {
      expect(
        useSmileIDSampleErrorMove(action, product),
        isA<UseSmileIDSampleRunAgain>().having(
          (UseSmileIDSampleRunAgain it) => it.product,
          'product',
          product,
        ),
        reason: action.name,
      );
    }
  });

  test('fixing the input returns to the id form', () {
    expect(
      useSmileIDSampleErrorMove(UseSmileIDSampleErrorAction.fixInput, product),
      isA<UseSmileIDSampleEditIdDetails>().having(
        (UseSmileIDSampleEditIdDetails it) => it.product,
        'product',
        product,
      ),
    );
  });

  test('starting again takes a new token first', () {
    expect(
      useSmileIDSampleErrorMove(
        UseSmileIDSampleErrorAction.newSession,
        product,
      ),
      isA<UseSmileIDSampleNewToken>().having(
        (UseSmileIDSampleNewToken it) => it.product,
        'product',
        product,
      ),
    );
  });

  test('close leaves the run', () {
    expect(
      useSmileIDSampleErrorMove(UseSmileIDSampleErrorAction.exit, product),
      isA<UseSmileIDSampleLeave>(),
    );
  });

  test('a run whose product was not kept can only leave', () {
    for (final UseSmileIDSampleErrorAction action
        in UseSmileIDSampleErrorAction.values) {
      expect(
        useSmileIDSampleErrorMove(action, null),
        isA<UseSmileIDSampleLeave>(),
        reason: action.name,
      );
    }
  });
}
