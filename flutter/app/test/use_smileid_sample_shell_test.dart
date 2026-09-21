import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_routes.dart';

/// The shell's job is that all three tabs are reachable and the bar says which one you are on.
void main() {
  Future<void> pumpShell(WidgetTester tester, {String? at}) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: UseSmileIDSampleTheme.light(),
          routerConfig: useSmileIDSampleRouter(initialLocation: at),
        ),
      ),
    );
    await tester.pump();
  }

  Finder byId(String id) => find.bySemanticsIdentifier(id);

  testWidgets('the app opens on products, which is the start destination', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);

    expect(byId(UseSmileIDSampleTestIds.productsScreen), findsOne);
    expect(byId(UseSmileIDSampleTestIds.navProducts), findsOne);
  });

  testWidgets('the verifications tab is empty on a launch with no arguments', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);
    await tester.tap(byId(UseSmileIDSampleTestIds.navVerifications));
    await tester.pumpAndSettle();

    expect(byId(UseSmileIDSampleTestIds.verificationsScreen), findsOne);
    expect(byId(UseSmileIDSampleTestIds.verificationsEmpty), findsOne);
  });

  testWidgets('the settings tab reaches settings', (WidgetTester tester) async {
    await pumpShell(tester);
    await tester.tap(byId(UseSmileIDSampleTestIds.navSettings));
    await tester.pumpAndSettle();

    expect(byId(UseSmileIDSampleTestIds.settingsScreen), findsOne);
  });

  testWidgets('a tab keeps its own state while another is shown', (
    WidgetTester tester,
  ) async {
    // The row's semantics node spans the whole row, so its centre is the label, not the control:
    // tapping the id toggles nothing and the round trip below would compare a default with itself.
    Finder agentModeSwitch() => find.descendant(
      of: byId(UseSmileIDSampleTestIds.settingAgentMode),
      matching: find.byType(Switch),
    );
    bool agentMode() => tester.widget<Switch>(agentModeSwitch()).value;

    await pumpShell(tester);
    await tester.tap(byId(UseSmileIDSampleTestIds.navSettings));
    await tester.pumpAndSettle();
    expect(agentMode(), isFalse, reason: 'agent mode is off by default');

    await tester.tap(agentModeSwitch());
    await tester.pumpAndSettle();
    expect(
      agentMode(),
      isTrue,
      reason: 'the tap has to land, or nothing below means anything',
    );

    await tester.tap(byId(UseSmileIDSampleTestIds.navProducts));
    await tester.pumpAndSettle();
    await tester.tap(byId(UseSmileIDSampleTestIds.navSettings));
    await tester.pumpAndSettle();

    expect(agentMode(), isTrue);
  });

  // The MEASURED height, not 58: the real bar clears that floor by 30dp, so a formula still passes.
  testWidgets('every tab root reserves room for the bar it floats under', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);
    final double barHeight = tester
        .getSize(find.byType(UseSmileIDSampleNavBar))
        .height;

    expect(
      tester
          .widget<UseSmileIDSampleProductsScreen>(
            find.byType(UseSmileIDSampleProductsScreen),
          )
          .bottomInset,
      greaterThanOrEqualTo(barHeight),
    );

    await tester.tap(byId(UseSmileIDSampleTestIds.navVerifications));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<UseSmileIDSampleVerificationsScreen>(
            find.byType(UseSmileIDSampleVerificationsScreen),
          )
          .bottomInset,
      greaterThanOrEqualTo(barHeight),
    );

    await tester.tap(byId(UseSmileIDSampleTestIds.navSettings));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<UseSmileIDSampleSettingsScreen>(
            find.byType(UseSmileIDSampleSettingsScreen),
          )
          .bottomInset,
      greaterThanOrEqualTo(barHeight),
    );
  });

  // Found on a device, not here: system back from a non-first tab left the app entirely.
  testWidgets('system back from another tab returns to products', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);
    await tester.tap(byId(UseSmileIDSampleTestIds.navVerifications));
    await tester.pumpAndSettle();
    expect(byId(UseSmileIDSampleTestIds.verificationsScreen), findsOne);

    final bool leftTheApp = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(leftTheApp, isTrue, reason: 'the app handled the pop itself');
    expect(byId(UseSmileIDSampleTestIds.productsScreen), findsOne);
  });

  // R13 on a real destination rather than on the predicate alone: the gallery sits outside the
  // shell, so it is the one route today that proves the bar is absent where it should be.
  testWidgets('a route outside the shell carries no nav bar', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester, at: UseSmileIDSampleRoutes.components);

    expect(byId(UseSmileIDSampleTestIds.navProducts), findsNothing);
    expect(byId(UseSmileIDSampleTestIds.navToken), findsNothing);
  });

  // Measured on a device: the sheet was pushed on the TAB's navigator, inside the body the bar is
  // painted over, so this tap landed on the bar and switched tab instead of choosing the row.
  testWidgets('a sheet row under the bar takes its own tap', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpShell(tester, at: UseSmileIDSampleRoutes.scenarioDrawer);
    await tester.pumpAndSettle();

    final Finder lastRow = byId(
      UseSmileIDSampleTestIds.themeItem(
        UseSmileIDSampleThemeScenario.values.last.id,
      ),
    );
    final Rect row = tester.getRect(lastRow);
    final Rect bar = tester.getRect(find.byType(UseSmileIDSampleNavBar));
    // Asserted, not assumed: on a geometry where they miss, the tap below proves nothing.
    expect(
      row.overlaps(bar),
      isTrue,
      reason: 'row $row does not meet the bar at $bar',
    );

    await tester.tapAt(row.center);
    await tester.pumpAndSettle();

    expect(
      lastRow,
      findsOne,
      reason: 'the tap reached the bar and switched tab',
    );
    expect(
      tester.widget<Semantics>(lastRow).properties.selected,
      isTrue,
      reason: 'the tap landed on the sheet but not on the row',
    );
  });

  // The bar FLOATS over the page, so a screen that reserved no room ends with its last control under it.
  testWidgets('the last control of settings clears the floating bar', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester, at: UseSmileIDSampleRoutes.settings);
    for (int i = 0; i < 15; i++) {
      await tester.drag(find.byType(Scrollable), const Offset(0, -400));
      await tester.pumpAndSettle();
    }

    final double lastControl = tester
        .getRect(byId(UseSmileIDSampleTestIds.signOut))
        .bottom;
    final double barTop = tester
        .getRect(find.byType(UseSmileIDSampleNavBar))
        .top;
    expect(
      lastControl,
      lessThanOrEqualTo(barTop),
      reason: 'sign out is $lastControl, the bar starts at $barTop',
    );
  });
}
