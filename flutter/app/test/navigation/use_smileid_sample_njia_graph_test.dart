import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:usesmileid_njia/usesmileid_njia.dart';
import 'package:usesmileid_sample_flutter/src/navigation/use_smileid_sample_njia.dart';

/// The spec's graph, read from the repository rather than the asset, so a stale copy can't pass.
UseSmileIDSampleGraph useSmileIDSampleSpecGraph() => useSmileIDSampleNjiaCodec
    .decodeGraph(File('../../spec/njia-graph.json').readAsStringSync());

void main() {
  final UseSmileIDSampleGraph graph = useSmileIDSampleSpecGraph();

  test('the graph is valid', () {
    expect(graph.validate(), isEmpty);
  });

  test('every kind the app names is a step in the graph, once', () {
    final List<UseSmileIDSampleStep> kinds =
        graph.steps.map((step) => step.kind).toList()
          ..sort((a, b) => a.index.compareTo(b.index));
    expect(kinds, UseSmileIDSampleStep.values);
  });

  test('every fact the app names is one a skipWhen reads', () {
    final List<NjiaCondition<UseSmileIDSampleFact>> conditions =
        <NjiaCondition<UseSmileIDSampleFact>>[
          ...graph.nodes.map((node) => node.skipWhen).nonNulls,
          ...graph.steps.map((step) => step.skipWhen).nonNulls,
        ];
    expect(
      conditions
          .expand(
            (condition) => <UseSmileIDSampleFact>[
              ...condition.allOf,
              ...condition.noneOf,
            ],
          )
          .toSet(),
      UseSmileIDSampleFact.values.toSet(),
    );
  });

  test('the bundled asset is the spec graph', () {
    expect(
      File(useSmileIDSampleNjiaGraphAsset).readAsStringSync(),
      File('../../spec/njia-graph.json').readAsStringSync(),
    );
  });
}
