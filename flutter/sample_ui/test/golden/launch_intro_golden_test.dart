import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'golden_harness.dart';

/// The intro stopped on its two named frames; it draws on the dark scheme whatever the app's, so both baselines match.
void main() {
  setUpAll(loadSampleFonts);

  testWidgets('launch intro locked', (WidgetTester tester) async {
    await goldens(
      tester,
      'screen_launch_intro_locked',
      () => _frame(UseSmileIDSampleLaunchIntroTimeline.locked),
      hostHeight: _windowHeight,
      fillsHost: true,
    );
  });

  testWidgets('launch intro logo', (WidgetTester tester) async {
    await goldens(
      tester,
      'screen_launch_intro_logo',
      () => _frame(1),
      hostHeight: _windowHeight,
      fillsHost: true,
    );
  });
}

Widget _frame(double progress) => UseSmileIDSampleLaunchIntroFrame(
  progress: AlwaysStoppedAnimation<double>(progress),
);

/// Android's golden window, so the logo lands at the same height on every platform.
const double _windowHeight = 891;
