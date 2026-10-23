import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import 'flow/use_smileid_sample_token_binding_rules.dart';
import 'navigation/use_smileid_sample_deep_links.dart';
import 'navigation/use_smileid_sample_navigation.dart';
import 'navigation/use_smileid_sample_njia.dart';
import 'navigation/use_smileid_sample_njia_facts.dart';
import 'state/use_smileid_sample_providers.dart';
import 'state/use_smileid_sample_session_providers.dart';

/// A product tap's run, or null when no live session backs it and the scanner comes first, since every run submits under a token.
UseSmileIDSampleRunEntry? useSmileIDSampleEntryFor(
  WidgetRef ref,
  UseSmileIDSampleGraph graph,
  UseSmileIDSampleProduct product,
) {
  final UseSmileIDSampleTokenSession? linked = ref
      .read(useSmileIDSampleSessionProvider)
      .live;
  if (linked == null ||
      linked.hasExpired(ref.read(useSmileIDSampleWallClockProvider)())) {
    ref
        .read(useSmileIDSampleInterruptedRunProvider.notifier)
        .send(
          UseSmileIDSampleRunIntent(
            productId: product.id,
            route: ref.read(useSmileIDSampleLaunchArgsProvider).route,
            resumeAt: UseSmileIDSampleResumePoint.firstStep,
          ),
        );
    return null;
  }
  return useSmileIDSampleRunEntryFor(ref, graph, product);
}

/// Where [product] starts under this launch and its token: a form is skipped only when the token already carries all of it.
UseSmileIDSampleRunEntry useSmileIDSampleRunEntryFor(
  WidgetRef ref,
  UseSmileIDSampleGraph graph,
  UseSmileIDSampleProduct product,
) {
  final UseSmileIDSampleTokenBindings? bindings = useSmileIDSampleLiveBindings(
    ref,
  );
  final Set<UseSmileIDSampleFact> facts = useSmileIDSampleFacts(
    product,
    bindsIdDetails: bindings?.bindsIdDetails(product) ?? false,
    route: ref.read(useSmileIDSampleLaunchArgsProvider).route,
  );
  return UseSmileIDSampleRunEntry(
    facts: facts,
    step: graph.firstStep(
      facts,
      bindsUserDetails: bindings?.bindsRequiredUserDetails ?? false,
    ),
  );
}

/// Straight into the run on [route], past every form, as an autostart or a resumed run goes.
UseSmileIDSampleRunEntry useSmileIDSampleRunOnly(
  WidgetRef ref,
  UseSmileIDSampleProduct product,
  UseSmileIDSampleFlowRoute route,
) => UseSmileIDSampleRunEntry(
  facts: useSmileIDSampleFacts(
    product,
    bindsIdDetails:
        useSmileIDSampleLiveBindings(ref)?.bindsIdDetails(product) ?? false,
    route: route,
  ),
  step:
      (route == UseSmileIDSampleFlowRoute.fullscreen
              ? UseSmileIDSampleStep.sdkFlowFullScreen
              : UseSmileIDSampleStep.sdkFlow)
          .name,
);

/// The facts a link's run starts with: its product's, on the route it asked for, or the launch's.
Set<UseSmileIDSampleFact> useSmileIDSampleLinkFacts(
  WidgetRef ref,
  UseSmileIDSampleLink link,
) {
  final String? productId = UseSmileIDSampleDeepLinks.productIdOf(link);
  final UseSmileIDSampleProduct? product = UseSmileIDSampleProduct.values
      .where((UseSmileIDSampleProduct it) => it.id == productId)
      .firstOrNull;
  if (product == null) {
    return const <UseSmileIDSampleFact>{};
  }
  return useSmileIDSampleFacts(
    product,
    bindsIdDetails:
        useSmileIDSampleLiveBindings(ref)?.bindsIdDetails(product) ?? false,
    route: link.route ?? ref.read(useSmileIDSampleLaunchArgsProvider).route,
  );
}

/// The product with [id], or null for one this build does not know.
UseSmileIDSampleProduct? useSmileIDSampleProductOf(String? id) =>
    UseSmileIDSampleProduct.values
        .where((UseSmileIDSampleProduct it) => it.id == id)
        .firstOrNull;

/// The live token session, read once at the tap.
UseSmileIDSampleTokenSession? useSmileIDSampleLiveTokenSession(WidgetRef ref) =>
    useSmileIDSampleLiveSession(
      ref.read(useSmileIDSampleSessionProvider).live,
      DateTime.now().millisecondsSinceEpoch,
      scenario: ref.read(useSmileIDSampleScenarioProvider).scenario,
    );

/// The live token's bindings, read once at the tap.
UseSmileIDSampleTokenBindings? useSmileIDSampleLiveBindings(WidgetRef ref) =>
    useSmileIDSampleLiveTokenSession(ref)?.bindings;
