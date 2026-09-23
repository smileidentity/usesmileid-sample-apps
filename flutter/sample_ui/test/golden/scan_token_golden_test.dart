import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'golden_harness.dart';

/// Scan token without a camera, and the scanner's pills.
void main() {
  setUpAll(loadSampleFonts);

  // Ahead of the goldens: a failed match leaves a debug flag set for the next test.
  testWidgets('scan token survives max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(
      tester,
      _screen(),
      ownsScrolling: true,
      hostHeight: goldenScreenHeight * 2,
      knownEllipsised: const <String>{'Or enter token manually'},
    );
  });

  testWidgets('scan status survives max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(tester, _statuses());
  });

  testWidgets('scan token', (WidgetTester tester) async {
    await goldens(
      tester,
      'screen_scan_token',
      _screen,
      hostHeight: goldenScreenHeight,
      fillsHost: true,
    );
  });

  /// Sent here by the expiry gate.
  testWidgets('scan token redirected', (WidgetTester tester) async {
    await goldens(
      tester,
      'screen_scan_token_redirected',
      () => _screen(reason: UseSmileIDSampleScanReason.sessionEnded),
      hostHeight: goldenScreenHeight,
      fillsHost: true,
    );
  });

  testWidgets('scan status', (WidgetTester tester) async {
    await goldens(tester, 'scan_status', _statuses);
  });
}

Widget _screen({UseSmileIDSampleScanReason? reason}) =>
    UseSmileIDSampleScanTokenScreen(
      reason: reason,
      onBack: () {},
      onLink: (_) {},
      onSimulate: (_, _, _) {},
      onPaste: () async => null,
    );

/// Every pill state: found, linked and rejected.
Widget _statuses() => Column(
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    for (final UseSmileIDSampleScanState state in <UseSmileIDSampleScanState>[
      const UseSmileIDSampleScanFound(),
      const UseSmileIDSampleScanLinked(
        handle: '7d2f01aa',
        remaining: '7:59:12',
      ),
      const UseSmileIDSampleScanRejected(
        "The token's api_url names api.example.test, which is not a Smile ID environment.",
      ),
    ]) ...<Widget>[
      UseSmileIDSampleScanStatus(state: state, onRetry: () {}),
      const SizedBox(height: SmileDimens.spacingSm),
    ],
  ],
);
