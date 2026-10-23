import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_njia/usesmileid_njia.dart';
import 'package:usesmileid_sample_flutter/src/navigation/use_smileid_sample_deep_links.dart';
import 'package:usesmileid_sample_flutter/src/navigation/use_smileid_sample_navigation.dart';
import 'package:usesmileid_sample_flutter/src/navigation/use_smileid_sample_njia.dart';
import 'package:usesmileid_sample_flutter/src/navigation/use_smileid_sample_steps.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_version.dart';
import 'support/use_smileid_sample_test_njia.dart';

/// The app's links, asserted against `spec/routes.json` through `spec/njia-graph.json`: a renamed path or step otherwise kills a link silently.
void main() {
  const String run = 'sdkFlow';
  final RegExp pathParam = RegExp(r':([A-Za-z][A-Za-z0-9]*)');
  late List<Map<String, Object?>> routes;
  late UseSmileIDSampleGraph graph;

  setUpAll(() {
    final Map<String, Object?> table =
        jsonDecode(File('../../spec/routes.json').readAsStringSync())
            as Map<String, Object?>;
    routes = (table['routes']! as List<Object?>).cast<Map<String, Object?>>();
    graph = useSmileIDSampleSpecGraph();
  });

  String idOf(Map<String, Object?> route) => route['id']! as String;

  String pathOf(Map<String, Object?> route) => route['path']! as String;

  /// The route's path under this app's scheme, each parameter filled with a sample value.
  Uri sampleUri(Map<String, Object?> route) => Uri.parse(
    'usesmileid-sample-flutter://${pathOf(route).substring(1).replaceAllMapped(pathParam, (Match match) => 'sample-${match[1]}')}',
  );

  /// Every fact a link might need: the run's forms all shown, on [route].
  Set<UseSmileIDSampleFact> factsFor(UseSmileIDSampleFlowRoute route) =>
      <UseSmileIDSampleFact>{
        UseSmileIDSampleFact.needsUserId,
        UseSmileIDSampleFact.needsIdDetails,
        if (route == UseSmileIDSampleFlowRoute.fullscreen)
          UseSmileIDSampleFact.fullScreenRun,
      };

  test('the spec lists routes, so no assertion below passes on nothing', () {
    expect(routes, isNotEmpty);
  });

  test(
    'every spec route is the graph step the flutter column names, linked at its path',
    () {
      for (final Map<String, Object?> route in routes) {
        final NjiaStep<UseSmileIDSampleStep, UseSmileIDSampleFact>? step = graph
            .step(idOf(route));
        expect(step, isNotNull, reason: '${idOf(route)}: no step');
        expect(step!.link, pathOf(route).substring(1), reason: idOf(route));
        final String flutter =
            (route['platform']! as Map<String, Object?>)['flutter']! as String;
        expect(
          flutter.split(' | ').first,
          'UseSmileIDSampleStep.${step.kind.name}',
          reason: idOf(route),
        );
      }
    },
  );

  test('every step id is its kind\'s name', () {
    for (final NjiaStep<UseSmileIDSampleStep, UseSmileIDSampleFact> step
        in graph.steps) {
      expect(step.id, step.kind.name);
    }
  });

  test('a spec sheet is a sheet step and nothing else is', () {
    for (final Map<String, Object?> route in routes) {
      expect(
        graph.step(idOf(route))!.presentation == NjiaPresentation.sheet,
        (route['presentation']! as String).endsWith('Sheet'),
        reason: idOf(route),
      );
    }
  });

  test('every spec link opens at its own step', () async {
    final UseSmileIDSampleReferenceNjia engines =
        UseSmileIDSampleReferenceNjia();
    for (final Map<String, Object?> route in routes) {
      final UseSmileIDSampleLink? link = UseSmileIDSampleDeepLinks.linkOf(
        sampleUri(route),
      );
      expect(link, isNotNull, reason: idOf(route));
      final UseSmileIDSampleFlowRoute asked =
          link!.route ?? UseSmileIDSampleFlowRoute.shell;
      final UseSmileIDSampleEngine? engine = await engines.openLink(
        graph,
        link.path,
        factsFor(asked),
      );
      expect(engine, isNotNull, reason: '${idOf(route)}: ${link.path}');
      expect(
        engine!.state.entries.last.step,
        idOf(route) == run && asked == UseSmileIDSampleFlowRoute.fullscreen
            ? UseSmileIDSampleStep.sdkFlowFullScreen.name
            : idOf(route),
        reason: idOf(route),
      );
    }
  });

  test('the run link opens full screen unless it asks for the shell', () async {
    final Map<String, Object?> spec = routes.firstWhere(
      (Map<String, Object?> route) => idOf(route) == run,
    );
    expect(
      UseSmileIDSampleDeepLinks.linkOf(sampleUri(spec))!.route,
      UseSmileIDSampleFlowRoute.fullscreen,
    );
    final UseSmileIDSampleLink shell = UseSmileIDSampleDeepLinks.linkOf(
      sampleUri(spec).replace(query: 'route=shell&probes=true'),
    )!;
    expect(shell.route, UseSmileIDSampleFlowRoute.shell);
    final UseSmileIDSampleEngine? engine = await UseSmileIDSampleReferenceNjia()
        .openLink(graph, shell.path, factsFor(UseSmileIDSampleFlowRoute.shell));
    expect(
      graph.stepOf(engine!.state.entries.last).kind,
      UseSmileIDSampleStep.sdkFlow,
    );
  });

  test('the flow route ids are the values the spec gives the run\'s route', () {
    final Map<String, Object?> spec = routes.firstWhere(
      (Map<String, Object?> route) => idOf(route) == run,
    );
    final Map<String, Object?> arg = (spec['args']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .firstWhere((Map<String, Object?> it) => it['name'] == 'route');
    final RegExpMatch values = RegExp(
      r'enum\(([^)]*)\)',
    ).firstMatch(arg['type']! as String)!;
    expect(
      UseSmileIDSampleFlowRoute.values.map(
        (UseSmileIDSampleFlowRoute it) => it.id,
      ),
      values[1]!.split(','),
    );
    expect(arg['default'], UseSmileIDSampleFlowRoute.fullscreen.id);
  });

  test(
    'the only link outside the spec is the full-screen run, and the gallery is in neither',
    () {
      final Set<String> spec = routes
          .map((Map<String, Object?> route) => pathOf(route).substring(1))
          .toSet();
      expect(
        graph.steps
            .map(
              (NjiaStep<UseSmileIDSampleStep, UseSmileIDSampleFact> step) =>
                  step.link,
            )
            .nonNulls
            .where((String link) => !spec.contains(link)),
        <String>['flow/:productId/run-fullscreen'],
      );
      final Uri gallery = Uri.parse(
        'usesmileid-sample-flutter://debug/components',
      );
      expect(UseSmileIDSampleDeepLinks.linkOf(gallery), isNull);
      expect(UseSmileIDSampleDeepLinks.isGallery(gallery), isTrue);
    },
  );

  test('the nav items select the shell\'s tabs, in the graph\'s order', () {
    final NjiaTabs<UseSmileIDSampleStep, UseSmileIDSampleFact> shell = graph
        .nodes
        .whereType<NjiaTabs<UseSmileIDSampleStep, UseSmileIDSampleFact>>()
        .single;
    expect(
      UseSmileIDSampleNavItem.values.map(useSmileIDSampleStepOf),
      shell.steps.map(
        (NjiaStep<UseSmileIDSampleStep, UseSmileIDSampleFact> step) =>
            step.kind,
      ),
    );
    expect(
      UseSmileIDSampleNavItem.values.map(
        (UseSmileIDSampleNavItem item) => item.testId,
      ),
      <String>[
        UseSmileIDSampleTestIds.navProducts,
        UseSmileIDSampleTestIds.navVerifications,
        UseSmileIDSampleTestIds.navSettings,
      ],
    );
    expect(
      shell.steps.map(
        (NjiaStep<UseSmileIDSampleStep, UseSmileIDSampleFact> step) =>
            '/${step.link}',
      ),
      routes
          .where((Map<String, Object?> route) => route['presentation'] == 'tab')
          .map(pathOf),
    );
  });

  test('a nav item is found from its root, and from no other step', () {
    for (final UseSmileIDSampleStep step in UseSmileIDSampleStep.values) {
      final UseSmileIDSampleNavItem? item = useSmileIDSampleNavItemOf(step);
      expect(
        item == null ? null : useSmileIDSampleStepOf(item),
        UseSmileIDSampleNavItem.values
                .map(useSmileIDSampleStepOf)
                .contains(step)
            ? step
            : null,
        reason: step.name,
      );
    }
  });

  test('the settings footer names the version the pubspec declares', () {
    // Read with a pattern rather than a YAML parser, which would be a dependency for one line.
    final RegExpMatch? declared = RegExp(
      r'^version:\s*(\d+\.\d+\.\d+)',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync());
    final String version = declared!.group(1)!;
    expect(useSmileIDSampleVersionLabel, endsWith(version));
  });
}
