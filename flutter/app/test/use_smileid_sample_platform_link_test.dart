import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_routes.dart';

/// A link into a LIVE app, which is the entry `spec/routes.json` documents for a mid-run flow.
void main() {
  late GoRouter router;

  Future<void> pumpApp(WidgetTester tester) async {
    router = useSmileIDSampleRouter();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: UseSmileIDSampleTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
  }

  /// What the platform delivers to a running app: the raw URI, scheme and all.
  Future<void> deliver(WidgetTester tester, String link) async {
    await router.routeInformationProvider.didPushRouteInformation(
      RouteInformation(uri: Uri.parse(link)),
    );
    await tester.pumpAndSettle();
  }

  Uri landedOn() => router.routerDelegate.currentConfiguration.uri;

  Finder byId(String id) => find.bySemanticsIdentifier(id);

  testWidgets('a mid-run link reaches the route its path names', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    expect(byId(UseSmileIDSampleTestIds.productsScreen), findsOne);

    await deliver(tester, 'usesmileid-sample-flutter://settings/licenses');

    expect(byId(UseSmileIDSampleTestIds.licensesScreen), findsOne);
  });

  testWidgets('a mid-run link opens the scenario drawer over settings', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await deliver(tester, 'usesmileid-sample-flutter://debug/scenarios');

    expect(byId(UseSmileIDSampleTestIds.scenarioDrawer), findsOne);
  });

  // Measured on a device: without the hand-back the second delivery reopened nothing.
  testWidgets('the drawer link can be delivered twice in one session', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await deliver(tester, 'usesmileid-sample-flutter://debug/scenarios');
    expect(byId(UseSmileIDSampleTestIds.scenarioDrawer), findsOne);

    Navigator.of(
      tester.element(byId(UseSmileIDSampleTestIds.scenarioDrawer)),
    ).pop();
    await tester.pumpAndSettle();
    expect(landedOn().path, UseSmileIDSampleRoutes.settings);

    await deliver(tester, 'usesmileid-sample-flutter://debug/scenarios');

    expect(byId(UseSmileIDSampleTestIds.scenarioDrawer), findsOne);
  });

  testWidgets('a mid-run link lands on the route rather than the error page', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await deliver(tester, 'usesmileid-sample-flutter://verifications');

    expect(landedOn().path, UseSmileIDSampleRoutes.verifications);
    expect(byId(UseSmileIDSampleTestIds.verificationsScreen), findsOne);
  });

  testWidgets('a mid-run link keeps the query its route was given', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await deliver(
      tester,
      'usesmileid-sample-flutter://verifications?seedJobs=true',
    );

    expect(landedOn().path, UseSmileIDSampleRoutes.verifications);
    expect(landedOn().queryParameters['seedJobs'], 'true');
  });

  testWidgets('an in-app route keeps its own query', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    router.go('${UseSmileIDSampleRoutes.verifications}?filter=blocked');
    await tester.pumpAndSettle();

    expect(landedOn().path, UseSmileIDSampleRoutes.verifications);
    expect(landedOn().queryParameters['filter'], 'blocked');
  });

  testWidgets('an in-app route is left exactly as it was', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    router.go(UseSmileIDSampleRoutes.settings);
    await tester.pumpAndSettle();

    expect(byId(UseSmileIDSampleTestIds.settingsScreen), findsOne);
  });
}
