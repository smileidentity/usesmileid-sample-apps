import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_njia/usesmileid_njia.dart';
import 'package:usesmileid_njia_testing/usesmileid_njia_testing.dart';
import 'package:usesmileid_sample_flutter/src/navigation/use_smileid_sample_njia.dart';
import 'package:usesmileid_sample_flutter/src/navigation/use_smileid_sample_njia_facts.dart';

import 'use_smileid_sample_njia_graph_test.dart';

/// The wizard has five steps, so a longer walk is a loop.
const int _runLength = 5;

void main() {
  final UseSmileIDSampleGraph graph = useSmileIDSampleSpecGraph();
  final ReferenceNjiaNative<UseSmileIDSampleStep, UseSmileIDSampleFact> native =
      ReferenceNjiaNative(useSmileIDSampleNjiaCodec);

  /// The shell's journey rules: consent unless bound, the auth user ID, ID details unless bound, then the run.
  List<UseSmileIDSampleStep> expected(
    UseSmileIDSampleProduct product,
    bool bindsUser,
    bool bindsId,
    UseSmileIDSampleFlowRoute route,
  ) => <UseSmileIDSampleStep>[
    if (!bindsUser) UseSmileIDSampleStep.consentDetailsForm,
    if (product == UseSmileIDSampleProduct.smartSelfieAuth)
      UseSmileIDSampleStep.authUserId
    else if (product.needsIdDetails && !bindsId)
      UseSmileIDSampleStep.idDetailsForm,
    if (route == UseSmileIDSampleFlowRoute.fullscreen)
      UseSmileIDSampleStep.sdkFlowFullScreen
    else
      UseSmileIDSampleStep.sdkFlow,
  ];

  /// A product tap from the products tab, then `next` from each form until the run is on top.
  Future<List<UseSmileIDSampleStep>> walked(
    UseSmileIDSampleProduct product,
    bool bindsUser,
    bool bindsId,
    UseSmileIDSampleFlowRoute route,
  ) async {
    final Set<UseSmileIDSampleFact> facts = useSmileIDSampleFacts(
      product,
      bindsIdDetails: bindsId,
      route: route,
    );
    final NjiaEngine<UseSmileIDSampleStep, UseSmileIDSampleFact> engine =
        await native.start(graph, facts: facts);
    await engine
        .navigator(engine.state.top!)
        .go(
          graph.firstStep(facts, bindsUserDetails: bindsUser),
          arg: product.id,
        );
    final List<UseSmileIDSampleStep> walked = <UseSmileIDSampleStep>[];
    while (true) {
      final UseSmileIDSampleStep kind = graph.stepOf(engine.state.top!).kind;
      walked.add(kind);
      if (kind == UseSmileIDSampleStep.sdkFlow ||
          kind == UseSmileIDSampleStep.sdkFlowFullScreen ||
          walked.length > _runLength) {
        await engine.dispose();
        return walked;
      }
      await engine.navigator(engine.state.top!).next();
    }
  }

  test(
    'every product walks the forms its token leaves, then the run its launch asked for',
    () async {
      for (final UseSmileIDSampleProduct product
          in UseSmileIDSampleProduct.values) {
        for (final bool bindsUser in <bool>[false, true]) {
          for (final bool bindsId in <bool>[false, true]) {
            for (final UseSmileIDSampleFlowRoute route
                in UseSmileIDSampleFlowRoute.values) {
              expect(
                await walked(product, bindsUser, bindsId, route),
                expected(product, bindsUser, bindsId, route),
                reason: '$product binds user $bindsUser id $bindsId $route',
              );
            }
          }
        }
      }
    },
  );

  test('facts name only what a run needs', () {
    expect(
      useSmileIDSampleFacts(
        UseSmileIDSampleProduct.smartSelfieEnrollment,
        bindsIdDetails: false,
        route: UseSmileIDSampleFlowRoute.shell,
      ),
      isEmpty,
    );
    expect(
      useSmileIDSampleFacts(
        UseSmileIDSampleProduct.smartSelfieAuth,
        bindsIdDetails: false,
        route: UseSmileIDSampleFlowRoute.fullscreen,
      ),
      <UseSmileIDSampleFact>{
        UseSmileIDSampleFact.needsUserId,
        UseSmileIDSampleFact.fullScreenRun,
      },
    );
  });
}
