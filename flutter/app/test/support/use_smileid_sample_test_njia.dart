import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:usesmileid_njia/usesmileid_njia.dart';
import 'package:usesmileid_njia_testing/usesmileid_njia_testing.dart';
import 'package:usesmileid_sample_flutter/src/navigation/use_smileid_sample_navigation.dart';
import 'package:usesmileid_sample_flutter/src/navigation/use_smileid_sample_njia.dart';
import 'package:usesmileid_sample_flutter/src/navigation/use_smileid_sample_router.dart';

/// The spec's graph, read from the repository rather than the asset, so a stale copy can't pass.
UseSmileIDSampleGraph useSmileIDSampleSpecGraph() => useSmileIDSampleNjiaCodec
    .decodeGraph(File('../../spec/njia-graph.json').readAsStringSync());

/// njia's Dart reference engine behind the shell's engine source, so a test routes as the app does.
final class UseSmileIDSampleReferenceNjia
    implements UseSmileIDSampleNjiaEngines {
  /// The reference engines a test's flows run on.
  final ReferenceNjiaNative<UseSmileIDSampleStep, UseSmileIDSampleFact> native =
      ReferenceNjiaNative<UseSmileIDSampleStep, UseSmileIDSampleFact>(
        useSmileIDSampleNjiaCodec,
      );

  @override
  Future<UseSmileIDSampleEngine> start(UseSmileIDSampleGraph graph) =>
      native.start(graph);

  @override
  Future<UseSmileIDSampleEngine> restore(
    UseSmileIDSampleGraph graph,
    NjiaState<UseSmileIDSampleFact> state,
  ) => native.restore(graph, state);

  @override
  Future<UseSmileIDSampleEngine?> openLink(
    UseSmileIDSampleGraph graph,
    String link,
    Set<UseSmileIDSampleFact> facts,
  ) => native.openLink(graph, link, facts: facts);
}

/// The overrides that run the shell on njia's Dart reference engine and the spec's graph.
List<Override> useSmileIDSampleTestNjia() {
  final UseSmileIDSampleGraph graph = useSmileIDSampleSpecGraph();
  return <Override>[
    useSmileIDSampleNjiaEnginesProvider.overrideWithValue(
      UseSmileIDSampleReferenceNjia(),
    ),
    useSmileIDSampleNjiaGraphProvider.overrideWith((Ref ref) async => graph),
  ];
}

/// The app's router, launched at [at] (a path such as `/settings`), or from the icon when it is null.
RouterConfig<Uri> useSmileIDSampleTestRouter([String? at]) =>
    useSmileIDSampleRouterConfig(launchLink: at == null ? null : Uri.parse(at));

/// The flow on screen.
UseSmileIDSampleEngine useSmileIDSampleTestEngine(WidgetTester tester) =>
    UseSmileIDSampleNavigationScope.engineOf(
      tester.element(
        find.byType(NjiaHost<UseSmileIDSampleStep, UseSmileIDSampleFact>).first,
      ),
    );

/// The step on top of the flow on screen.
UseSmileIDSampleStep useSmileIDSampleTestTop(WidgetTester tester) {
  final UseSmileIDSampleEngine engine = useSmileIDSampleTestEngine(tester);
  return engine.graph.stepOf(engine.state.top!).kind;
}

/// What the platform hands the running app: [link], as a warm deep link.
Future<void> useSmileIDSampleTestDeliver(
  WidgetTester tester,
  String link,
) async {
  final Router<Object?> router = Router.of(
    tester.element(
      find.byType(NjiaHost<UseSmileIDSampleStep, UseSmileIDSampleFact>).first,
    ),
  );
  await (router.routeInformationProvider! as PlatformRouteInformationProvider)
      .didPushRouteInformation(RouteInformation(uri: Uri.parse(link)));
  await tester.pumpAndSettle();
}

/// The app's link paths, as `spec/routes.json` names them, for a test to launch or link to.
abstract final class UseSmileIDSampleRoutes {
  /// The products grid.
  static const String products = '/products';

  /// The verifications list.
  static const String verifications = '/verifications';

  /// Settings.
  static const String settings = '/settings';

  /// The licences page inside settings.
  static const String licenses = '/settings/licenses';

  /// The profiles list.
  static const String profiles = '/profiles';

  /// The profile-switch sheet over products.
  static const String profileSwitch = '/profiles/switch';

  /// The scenario drawer over settings.
  static const String scenarioDrawer = '/debug/scenarios';

  /// The capture-mode sheet over settings.
  static const String captureMode = '/settings/capture-mode';

  /// The API submission sheet over settings.
  static const String submission = '/settings/submission';

  /// The appearance sheet over settings.
  static const String appearance = '/settings/appearance';

  /// The language sheet over settings.
  static const String language = '/settings/language';

  /// The token scanner.
  static const String scanToken = '/token/scan';

  /// The dev-only component gallery.
  static const String components = '/debug/components';

  /// One verification's details.
  static String verificationDetails(String jobId) => '/verifications/$jobId';

  /// One profile's page.
  static String profileConfig(String profileId) => '/profiles/$profileId';

  /// A run's consent details form.
  static String consentDetailsForm(String productId) =>
      '/flow/$productId/details';

  /// A run's ID-details form.
  static String idDetailsForm(String productId) =>
      '/flow/$productId/id-details';

  /// The country picker over the ID-details form.
  static String countryPicker(String productId) =>
      '/flow/$productId/id-details/country';

  /// The ID type picker over the ID-details form.
  static String idTypePicker(String productId) =>
      '/flow/$productId/id-details/id-type';

  /// The document picker over the ID-details form.
  static String documentPicker(String productId) =>
      '/flow/$productId/id-details/document';

  /// The capture-as sheet over the ID-details form.
  static String captureAs(String productId) =>
      '/flow/$productId/id-details/capture-as';

  /// The generic-document sheet over the ID-details form.
  static String genericDocument(String productId) =>
      '/flow/$productId/id-details/generic-document';

  /// SmartSelfie Authentication's user ID form.
  static String authUserId(String productId) => '/flow/$productId/user-id';

  /// The SDK flow, full screen unless the link asks for the shell.
  static String sdkFlow(String productId) => '/flow/$productId/run';

  /// The tab roots, the only steps that carry the nav bar.
  static const List<String> tabRoots = <String>[
    products,
    verifications,
    settings,
  ];
}
