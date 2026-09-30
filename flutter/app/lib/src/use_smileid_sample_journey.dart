import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import 'flow/use_smileid_sample_flow_plan.dart';
import 'flow/use_smileid_sample_token_binding_rules.dart';
import 'state/use_smileid_sample_providers.dart';
import 'state/use_smileid_sample_session_providers.dart';
import 'use_smileid_sample_routes.dart';

/// Where a product tap goes first, and where each form goes next.
abstract final class UseSmileIDSampleJourney {
  /// The first step for [product], skipping forms the live token covers.
  static String firstStepFor(
    UseSmileIDSampleProduct product,
    UseSmileIDSampleTokenBindings? live,
  ) => useSmileIDSampleFlowPlan(live, product).userDetailsGap.isSatisfied
      ? afterUserDetails(product, live)
      : UseSmileIDSampleRoutes.consentDetailsForm(product.id);

  /// What follows the user-details form: the ID form, or the flow itself.
  static String afterUserDetails(
    UseSmileIDSampleProduct product,
    UseSmileIDSampleTokenBindings? live,
  ) => useSmileIDSampleFlowPlan(live, product).showIdDetailsForm
      ? UseSmileIDSampleRoutes.idDetailsForm(product.id)
      : UseSmileIDSampleRoutes.sdkFlow(product.id);

  /// What follows the ID-details form.
  static String afterIdDetails(UseSmileIDSampleProduct product) =>
      UseSmileIDSampleRoutes.sdkFlow(product.id);
}

/// A product tap: the scanner first when no live session backs the run, since every run submits under a token.
String useSmileIDSampleEntryFor(
  WidgetRef ref,
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
    return UseSmileIDSampleRoutes.scanToken;
  }
  return UseSmileIDSampleJourney.firstStepFor(
    product,
    useSmileIDSampleLiveBindings(ref),
  );
}

/// The live token's bindings, read once at the tap.
UseSmileIDSampleTokenBindings? useSmileIDSampleLiveBindings(WidgetRef ref) =>
    useSmileIDSampleLiveSession(
      ref.read(useSmileIDSampleSessionProvider).live,
      DateTime.now().millisecondsSinceEpoch,
      scenario: ref.read(useSmileIDSampleScenarioProvider).scenario,
    )?.bindings;
