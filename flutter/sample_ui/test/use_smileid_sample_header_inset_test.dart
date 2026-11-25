import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

final TargetPlatformVariant _android = TargetPlatformVariant.only(
  TargetPlatform.android,
);

/// A header keeps a small gap below the status bar on an Android phone with a top camera cutout, as the host reads it.
void main() {
  Future<void> pumpTopAppBar(
    WidgetTester tester, {
    required double statusBar,
    required bool underTopCutout,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..viewPadding = FakeViewPadding(top: statusBar)
      ..padding = FakeViewPadding(top: statusBar);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: UseSmileIDSampleTheme.light(),
        builder: (BuildContext context, Widget? child) =>
            UseSmileIDSampleTopCutout(present: underTopCutout, child: child!),
        // The shell's own SafeArea, which hides the inset from everything below it.
        home: Scaffold(
          body: SafeArea(
            bottom: false,
            child: UseSmileIDSampleTopAppBar(
              title: 'Open-source licenses',
              onBack: () {},
              backSemanticLabel: 'Back',
            ),
          ),
        ),
      ),
    );
  }

  Future<double> gapIn(
    WidgetTester tester, {
    bool? hostReads,
    bool framed = false,
  }) async {
    late double gap;
    Widget probe = Builder(
      builder: (BuildContext context) {
        gap = useSmileIDSampleHeaderTopGap(context);
        return const SizedBox();
      },
    );
    probe = UseSmileIDSampleLargeScreenFramed(framed: framed, child: probe);
    if (hostReads != null) {
      probe = UseSmileIDSampleTopCutout(present: hostReads, child: probe);
    }
    await tester.pumpWidget(probe);
    return gap;
  }

  double backTop(WidgetTester tester) =>
      tester.getRect(find.byType(UseSmileIDSampleTopAppBarButton).first).top;

  testWidgets(
    'on an Android phone with a top cutout the back button sits a small gap below the status bar',
    (WidgetTester tester) async {
      await pumpTopAppBar(tester, statusBar: 37, underTopCutout: true);

      expect(backTop(tester), 37 + SmileDimens.spacingSm);
    },
    variant: _android,
  );

  testWidgets(
    'on an Android phone without a cutout the back button stays against the status bar',
    (WidgetTester tester) async {
      await pumpTopAppBar(tester, statusBar: 24, underTopCutout: false);

      expect(backTop(tester), 24);
    },
    variant: _android,
  );

  testWidgets(
    'on iOS the safe area already leaves the room, so nothing is added',
    (WidgetTester tester) async {
      await pumpTopAppBar(tester, statusBar: 59, underTopCutout: true);

      expect(backTop(tester), 59);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets("a tab header follows the host's reading", (
    WidgetTester tester,
  ) async {
    expect(await gapIn(tester, hostReads: true), SmileDimens.spacingSm);
    expect(await gapIn(tester, hostReads: false), 0);
  }, variant: _android);

  testWidgets('without a host there is no reading, so no gap is added', (
    WidgetTester tester,
  ) async {
    expect(await gapIn(tester), 0);
  }, variant: _android);

  testWidgets(
    'inside the large-screen frame the status bar is outside, so no gap is added',
    (WidgetTester tester) async {
      expect(await gapIn(tester, framed: true), 0);
      expect(await gapIn(tester, hostReads: true, framed: true), 0);
    },
    variant: _android,
  );
}
