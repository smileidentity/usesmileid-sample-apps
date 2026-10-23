import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_sample_flutter/src/navigation/use_smileid_sample_navigation.dart';
import 'package:usesmileid_sample_flutter/src/navigation/use_smileid_sample_njia.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_providers.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_component_gallery.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_launch.dart';
import 'support/use_smileid_sample_test_njia.dart';

/// A link into a LIVE app, which is the entry `spec/routes.json` documents for a mid-run flow.
void main() {
  late RouterConfig<Uri> router;

  Future<void> pumpApp(WidgetTester tester, {String? at}) async {
    router = useSmileIDSampleTestRouter(at);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...useSmileIDSampleTestNjia(),
          useSmileIDSampleLaunchArgsProvider.overrideWithValue(
            UseSmileIDSampleLaunchArgs.fromUri(
              at == null ? null : Uri.parse(at),
            ),
          ),
        ],
        child: MaterialApp.router(
          theme: UseSmileIDSampleTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// What the platform delivers to a running app: the raw URI, scheme and all.
  Future<void> deliver(WidgetTester tester, String link) async {
    await (router.routeInformationProvider! as PlatformRouteInformationProvider)
        .didPushRouteInformation(RouteInformation(uri: Uri.parse(link)));
    await tester.pumpAndSettle();
  }

  Finder byId(String id) => find.bySemanticsIdentifier(id);

  testWidgets('a mid-run link reaches the step its path names', (
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
    expect(
      useSmileIDSampleTestTop(tester),
      UseSmileIDSampleStep.scenarioDrawer,
    );
  });

  // Measured on a device: without the hand-back the second delivery reopened nothing.
  testWidgets('the drawer link can be delivered twice in one session', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await deliver(tester, 'usesmileid-sample-flutter://debug/scenarios');
    expect(byId(UseSmileIDSampleTestIds.scenarioDrawer), findsOne);

    await Navigator.of(
      tester.element(byId(UseSmileIDSampleTestIds.scenarioDrawer)),
    ).maybePop();
    await tester.pumpAndSettle();
    expect(useSmileIDSampleTestTop(tester), UseSmileIDSampleStep.settings);

    await deliver(tester, 'usesmileid-sample-flutter://debug/scenarios');

    expect(byId(UseSmileIDSampleTestIds.scenarioDrawer), findsOne);
  });

  testWidgets('a mid-run link lands on its tab', (WidgetTester tester) async {
    await pumpApp(tester);

    await deliver(tester, 'usesmileid-sample-flutter://verifications');

    expect(useSmileIDSampleTestTop(tester), UseSmileIDSampleStep.verifications);
    expect(byId(UseSmileIDSampleTestIds.verificationsScreen), findsOne);
  });

  testWidgets('a link with no path leaves the app where it was', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await deliver(tester, 'usesmileid-sample-flutter://settings');
    final UseSmileIDSampleEngine before = useSmileIDSampleTestEngine(tester);

    await deliver(tester, 'usesmileid-sample-flutter://');

    expect(identical(useSmileIDSampleTestEngine(tester), before), isTrue);
    expect(useSmileIDSampleTestTop(tester), UseSmileIDSampleStep.settings);
  });

  testWidgets('a link outside the graph leaves the app where it was', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await deliver(tester, 'usesmileid-sample-flutter://nowhere/at/all');

    expect(useSmileIDSampleTestTop(tester), UseSmileIDSampleStep.products);
  });

  testWidgets('the cold link pushed again keeps the flow it opened', (
    WidgetTester tester,
  ) async {
    const String link = 'usesmileid-sample-flutter://settings/licenses';
    await pumpApp(tester, at: link);
    final UseSmileIDSampleEngine opened = useSmileIDSampleTestEngine(tester);

    await deliver(tester, link);

    expect(identical(useSmileIDSampleTestEngine(tester), opened), isTrue);
    expect(byId(UseSmileIDSampleTestIds.licensesScreen), findsOne);
  });

  testWidgets('the cold link opened after the cold-link window is a new link', (
    WidgetTester tester,
  ) async {
    const String link = 'usesmileid-sample-flutter://settings/licenses';
    await pumpApp(tester, at: link);
    final UseSmileIDSampleEngine opened = useSmileIDSampleTestEngine(tester);
    await tester.pump(useSmileIDSampleColdLinkWindow);

    await deliver(tester, link);

    expect(identical(useSmileIDSampleTestEngine(tester), opened), isFalse);
    expect(byId(UseSmileIDSampleTestIds.licensesScreen), findsOne);
  });

  testWidgets('the dev gallery link opens the gallery, and back closes it', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await deliver(tester, 'usesmileid-sample-flutter://debug/components');
    expect(find.byType(UseSmileIDSampleComponentGallery), findsOne);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(UseSmileIDSampleComponentGallery), findsNothing);
    expect(byId(UseSmileIDSampleTestIds.productsScreen), findsOne);
  });
}
