import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// A punch-hole phone's top cutout, the 35 its 37 status bar clears.
const DisplayFeature _topCutout = DisplayFeature(
  bounds: Rect.fromLTWH(20, 0, 30, 35),
  type: DisplayFeatureType.cutout,
  state: DisplayFeatureState.unknown,
);

/// The same cutout in landscape, where it sits on the side and the status bar stays on top.
const DisplayFeature _sideCutout = DisplayFeature(
  bounds: Rect.fromLTWH(0, 20, 35, 30),
  type: DisplayFeatureType.cutout,
  state: DisplayFeatureState.unknown,
);

final TargetPlatformVariant _android = TargetPlatformVariant.only(
  TargetPlatform.android,
);

/// A header keeps a small gap below the status bar on an Android phone with a top camera cutout, which the bar ends flush with.
void main() {
  void setView(
    WidgetTester tester, {
    required double statusBar,
    List<DisplayFeature> cutouts = const <DisplayFeature>[],
  }) {
    tester.view
      ..devicePixelRatio = 1
      ..viewPadding = FakeViewPadding(top: statusBar)
      ..padding = FakeViewPadding(top: statusBar)
      ..displayFeatures = cutouts;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpTopAppBar(
    WidgetTester tester, {
    required double statusBar,
    List<DisplayFeature> cutouts = const <DisplayFeature>[],
  }) async {
    setView(tester, statusBar: statusBar, cutouts: cutouts);
    await tester.pumpWidget(
      MaterialApp(
        theme: UseSmileIDSampleTheme.light(),
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
    bool framed = false,
    bool? hostReads,
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
    await tester.pumpWidget(SafeArea(child: probe));
    return gap;
  }

  double backTop(WidgetTester tester) =>
      tester.getRect(find.byType(UseSmileIDSampleTopAppBarButton).first).top;

  testWidgets(
    'on an Android phone with a top cutout the back button sits a small gap below the status bar',
    (WidgetTester tester) async {
      await pumpTopAppBar(
        tester,
        statusBar: 37,
        cutouts: <DisplayFeature>[_topCutout],
      );

      expect(backTop(tester), 37 + SmileDimens.spacingSm);
    },
    variant: _android,
  );

  testWidgets(
    'on an Android phone without a cutout the back button stays against the status bar',
    (WidgetTester tester) async {
      await pumpTopAppBar(tester, statusBar: 24);

      expect(backTop(tester), 24);
    },
    variant: _android,
  );

  testWidgets(
    'on iOS the safe area already leaves the room, so nothing is added',
    (WidgetTester tester) async {
      await pumpTopAppBar(
        tester,
        statusBar: 59,
        cutouts: <DisplayFeature>[_topCutout],
      );

      expect(backTop(tester), 59);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('without a status bar the back button keeps its place', (
    WidgetTester tester,
  ) async {
    await pumpTopAppBar(tester, statusBar: 0);

    expect(backTop(tester), 0);
  }, variant: _android);

  testWidgets('a tab header gets the gap only under a top cutout', (
    WidgetTester tester,
  ) async {
    setView(tester, statusBar: 37, cutouts: <DisplayFeature>[_topCutout]);
    expect(await gapIn(tester), SmileDimens.spacingSm);

    setView(tester, statusBar: 24);
    expect(await gapIn(tester), 0);

    setView(tester, statusBar: 37, cutouts: <DisplayFeature>[_sideCutout]);
    expect(await gapIn(tester), 0);
  }, variant: _android);

  testWidgets(
    "a host's native reading decides, even where the engine reports none",
    (WidgetTester tester) async {
      setView(tester, statusBar: 37);
      expect(await gapIn(tester, hostReads: true), SmileDimens.spacingSm);

      setView(tester, statusBar: 37, cutouts: <DisplayFeature>[_topCutout]);
      expect(await gapIn(tester, hostReads: false), 0);
    },
    variant: _android,
  );

  testWidgets(
    'inside the large-screen frame the status bar is outside, so no gap is added',
    (WidgetTester tester) async {
      setView(tester, statusBar: 37, cutouts: <DisplayFeature>[_topCutout]);

      expect(await gapIn(tester, framed: true), 0);
      expect(await gapIn(tester, framed: true, hostReads: true), 0);
    },
    variant: _android,
  );
}
