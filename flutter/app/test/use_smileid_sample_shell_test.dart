import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_routes.dart';

/// The shell's job is that all three tabs are reachable and the bar says which one you are on.
void main() {
  Future<void> pumpShell(WidgetTester tester, {String? at}) async {
    await tester.pumpWidget(
      MaterialApp.router(
        theme: UseSmileIDSampleTheme.light(),
        routerConfig: useSmileIDSampleRouter(initialLocation: at),
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

  // The bar insets nothing, so a tab screen wired without this has its last row under the pill.
  // It is invisible until the content is long enough to reach the bottom, which a golden of a
  // short page never is — so it is asserted on the value the shell passes, not on a picture.
  testWidgets('every tab root reserves room for the bar it floats under', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);
    expect(
      tester
          .widget<UseSmileIDSampleProductsScreen>(
            find.byType(UseSmileIDSampleProductsScreen),
          )
          .bottomInset,
      greaterThanOrEqualTo(_barHeight),
    );

    await tester.tap(byId(UseSmileIDSampleTestIds.navSettings));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<UseSmileIDSampleSettingsScreen>(
            find.byType(UseSmileIDSampleSettingsScreen),
          )
          .bottomInset,
      greaterThanOrEqualTo(_barHeight),
    );
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
}

/// The token affordance's 58, which is the tallest thing in the bar and so the floor a page clears.
const double _barHeight = 58;
