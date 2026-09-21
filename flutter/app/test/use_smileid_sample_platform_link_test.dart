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

  /// What the platform does with a link delivered to a running app: the raw URI, scheme and all.
  Future<void> deliver(WidgetTester tester, String link) async {
    await router.routeInformationProvider.didPushRouteInformation(
      RouteInformation(uri: Uri.parse(link)),
    );
    await tester.pumpAndSettle();
  }

  Finder byId(String id) => find.bySemanticsIdentifier(id);

  testWidgets('a mid-run link reaches the route its path names', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    expect(byId(UseSmileIDSampleTestIds.productsScreen), findsOne);

    await deliver(tester, 'usesmileid-sample-flutter://settings/licenses');

    expect(byId(UseSmileIDSampleTestIds.licensesScreen), findsOne);
  });

  // The automation entry itself: `spec/routes.json` says a flow deep-links mid-run to the drawer.
  testWidgets('a mid-run link opens the scenario drawer over settings', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await deliver(tester, 'usesmileid-sample-flutter://debug/scenarios');

    expect(byId(UseSmileIDSampleTestIds.scenarioDrawer), findsOne);
  });

  // Where the defect showed: go_router matched the whole URI against a path table and served its
  // error page, so a mid-run link stranded the app on Page Not Found.
  testWidgets('a mid-run link never lands on the router error page', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await deliver(tester, 'usesmileid-sample-flutter://verifications');

    expect(find.textContaining('Page Not Found'), findsNothing);
    expect(byId(UseSmileIDSampleTestIds.verificationsScreen), findsOne);
  });

  // The query is arguments, not a destination, and arguments are read once before the first frame.
  testWidgets('a mid-run link carrying arguments still seeds nothing', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await deliver(
      tester,
      'usesmileid-sample-flutter://verifications?seedJobs=true',
    );

    expect(byId(UseSmileIDSampleTestIds.verificationsEmpty), findsOne);
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
