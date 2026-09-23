import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usesmileid_sample_flutter/src/screens/use_smileid_sample_products_tab.dart';
import 'package:usesmileid_sample_flutter/src/screens/use_smileid_sample_settings_tab.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_providers.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_routes.dart';

/// The two surfaces the design does not draw: reaching them, and the act each performs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  late ProviderContainer container;

  Future<void> pumpAt(
    WidgetTester tester,
    String location, {
    UseSmileIDSampleLaunchArgs args = const UseSmileIDSampleLaunchArgs(),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          useSmileIDSampleLaunchArgsProvider.overrideWithValue(args),
          // The registry is empty under `flutter test` whatever the build bundles, so the screen's
          // content is supplied here rather than asserted against a stream that yields nothing.
          useSmileIDSampleLicensesProvider.overrideWith(
            (Ref ref) async => UseSmileIDSampleLicenses.from(<LicenseEntry>[
              LicenseEntryWithLineBreaks(const <String>[
                'go_router',
              ], 'Permission is hereby granted, free of charge'),
            ]),
          ),
        ],
        child: MaterialApp.router(
          theme: UseSmileIDSampleTheme.light(),
          routerConfig: useSmileIDSampleRouter(initialLocation: location),
        ),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
  }

  Finder byId(String id) => find.bySemanticsIdentifier(id);

  /// Both rows sit below the fold of settings, so the list is scrolled to the row before a tap.
  Future<void> tapRow(WidgetTester tester, Finder row) async {
    await tester.scrollUntilVisible(
      row,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
  }

  group('the notices screen', () {
    testWidgets('the settings row reaches it', (WidgetTester tester) async {
      await pumpAt(tester, UseSmileIDSampleRoutes.settings);
      expect(byId(UseSmileIDSampleTestIds.licensesScreen), findsNothing);

      await tapRow(tester, find.text('Open-source licenses'));

      expect(byId(UseSmileIDSampleTestIds.licensesScreen), findsOneWidget);
      expect(find.text('go_router'), findsOneWidget);
    });

    testWidgets('the deep link lands on it', (WidgetTester tester) async {
      await pumpAt(tester, UseSmileIDSampleRoutes.licenses);
      expect(byId(UseSmileIDSampleTestIds.licensesScreen), findsOneWidget);
    });

    /// It is pushed inside the settings tab, so back returns to settings rather than to products.
    testWidgets('back returns to settings', (WidgetTester tester) async {
      await pumpAt(tester, UseSmileIDSampleRoutes.licenses);
      await tester.tap(find.byType(UseSmileIDSampleTopAppBarButton));
      await tester.pumpAndSettle();

      expect(byId(UseSmileIDSampleTestIds.licensesScreen), findsNothing);
      expect(find.byType(UseSmileIDSampleSettingsScreen), findsOneWidget);
    });

    /// A pushed page carries no nav bar, which is the predicate R13 exists for.
    testWidgets('it carries no nav bar', (WidgetTester tester) async {
      await pumpAt(tester, UseSmileIDSampleRoutes.licenses);
      expect(find.byType(UseSmileIDSampleNavBar), findsNothing);
    });
  });

  group('the scenario drawer', () {
    testWidgets('the settings row opens it', (WidgetTester tester) async {
      await pumpAt(tester, UseSmileIDSampleRoutes.settings);
      expect(byId(UseSmileIDSampleTestIds.scenarioDrawer), findsNothing);

      await tapRow(tester, byId(UseSmileIDSampleTestIds.scenarioDrawerButton));

      expect(byId(UseSmileIDSampleTestIds.scenarioDrawer), findsOneWidget);
    });

    /// The link opens settings with the drawer up, rather than a sheet over nothing (R12).
    testWidgets('the deep link opens it over settings', (
      WidgetTester tester,
    ) async {
      await pumpAt(tester, UseSmileIDSampleRoutes.scenarioDrawer);
      expect(byId(UseSmileIDSampleTestIds.scenarioDrawer), findsOneWidget);
      expect(find.byType(UseSmileIDSampleSettingsScreen), findsOneWidget);
    });

    /// Dismissing it leaves settings intact, bar included — the reason the bar follows the page
    /// behind the scrim rather than the sheet's own path.
    testWidgets('dismissing it leaves settings with its nav bar', (
      WidgetTester tester,
    ) async {
      await pumpAt(tester, UseSmileIDSampleRoutes.scenarioDrawer);
      expect(find.byType(UseSmileIDSampleNavBar), findsOneWidget);

      Navigator.of(
        tester.element(byId(UseSmileIDSampleTestIds.scenarioDrawer)),
      ).pop();
      await tester.pumpAndSettle();

      expect(byId(UseSmileIDSampleTestIds.scenarioDrawer), findsNothing);
      expect(find.byType(UseSmileIDSampleSettingsScreen), findsOneWidget);
      expect(find.byType(UseSmileIDSampleNavBar), findsOneWidget);
    });

    testWidgets('a choice is kept', (WidgetTester tester) async {
      await pumpAt(tester, UseSmileIDSampleRoutes.scenarioDrawer);
      expect(
        container.read(useSmileIDSampleScenarioProvider).scenario,
        UseSmileIDSampleScenario.normal,
      );

      await tester.tap(
        byId(
          UseSmileIDSampleTestIds.scenarioItem(
            UseSmileIDSampleScenario.expiredToken.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(useSmileIDSampleScenarioProvider).scenario,
        UseSmileIDSampleScenario.expiredToken,
      );
    });

    /// A flow says which scenario to run rather than reproducing a hidden gesture.
    testWidgets('the launch argument seeds it', (WidgetTester tester) async {
      await pumpAt(
        tester,
        UseSmileIDSampleRoutes.settings,
        args: const UseSmileIDSampleLaunchArgs(
          scenario: UseSmileIDSampleScenario.badRefresh,
          theme: UseSmileIDSampleThemeScenario.clashingHost,
        ),
      );
      final UseSmileIDSampleScenarioSelection selection = container.read(
        useSmileIDSampleScenarioProvider,
      );
      expect(selection.scenario, UseSmileIDSampleScenario.badRefresh);
      expect(selection.theme, UseSmileIDSampleThemeScenario.clashingHost);
    });
  });

  /// Dismissing a sheet link hands the route to its owner, which must update in place, not rebuild.
  group('a sheet link and its owner are one page', () {
    Future<void> dismissKeepsOwner(
      WidgetTester tester, {
      required String link,
      required String sheetId,
      required Finder owner,
      required String ownerPath,
    }) async {
      await pumpAt(tester, link);
      final State<StatefulWidget> before = tester.state(owner);

      Navigator.of(tester.element(byId(sheetId))).pop();
      await tester.pumpAndSettle();

      final GoRouter router = GoRouter.of(tester.element(owner));
      expect(router.routerDelegate.currentConfiguration.uri.path, ownerPath);
      expect(identical(tester.state(owner), before), isTrue);
    }

    testWidgets(
      'the profile switch hands back to the same products page',
      (WidgetTester tester) => dismissKeepsOwner(
        tester,
        link: UseSmileIDSampleRoutes.profileSwitch,
        sheetId: UseSmileIDSampleTestIds.profileSwitchSheet,
        owner: find.byType(UseSmileIDSampleProductsTab),
        ownerPath: UseSmileIDSampleRoutes.products,
      ),
    );

    testWidgets(
      'the scenario drawer hands back to the same settings page',
      (WidgetTester tester) => dismissKeepsOwner(
        tester,
        link: UseSmileIDSampleRoutes.scenarioDrawer,
        sheetId: UseSmileIDSampleTestIds.scenarioDrawer,
        owner: find.byType(UseSmileIDSampleSettingsTab),
        ownerPath: UseSmileIDSampleRoutes.settings,
      ),
    );

    /// The shared page is updated rather than recreated, so a link arriving warm still opens the sheet.
    testWidgets('a warm profile-switch link still opens the sheet', (
      WidgetTester tester,
    ) async {
      await pumpAt(tester, UseSmileIDSampleRoutes.products);
      GoRouter.of(
        tester.element(find.byType(UseSmileIDSampleProductsTab)),
      ).go(UseSmileIDSampleRoutes.profileSwitch);
      await tester.pumpAndSettle();

      expect(byId(UseSmileIDSampleTestIds.profileSwitchSheet), findsOneWidget);
    });
  });
}
