import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_njia/usesmileid_njia.dart';

import 'use_smileid_sample_njia.dart';

/// The facts a run of [product] starts with, which the graph's `skipWhen` reads to skip a form.
Set<UseSmileIDSampleFact> useSmileIDSampleFacts(
  UseSmileIDSampleProduct product, {
  required bool bindsIdDetails,
  required UseSmileIDSampleFlowRoute route,
}) => <UseSmileIDSampleFact>{
  if (product == UseSmileIDSampleProduct.smartSelfieAuth)
    UseSmileIDSampleFact.needsUserId,
  if (product.needsIdDetails && !bindsIdDetails)
    UseSmileIDSampleFact.needsIdDetails,
  if (route == UseSmileIDSampleFlowRoute.fullscreen)
    UseSmileIDSampleFact.fullScreenRun,
};

/// The wizard's steps in the order `next` walks them: the consent form, the two optional forms and the run's two forms.
const List<UseSmileIDSampleStep> _wizard = <UseSmileIDSampleStep>[
  UseSmileIDSampleStep.consentDetailsForm,
  UseSmileIDSampleStep.authUserId,
  UseSmileIDSampleStep.idDetailsForm,
  UseSmileIDSampleStep.sdkFlow,
  UseSmileIDSampleStep.sdkFlowFullScreen,
];

/// Where a product tap goes on the graph.
extension UseSmileIDSampleFirstStep on UseSmileIDSampleGraph {
  /// The consent form unless the token binds user details, else the first wizard step [facts] don't skip.
  String firstStep(
    Set<UseSmileIDSampleFact> facts, {
    required bool bindsUserDetails,
  }) => _wizard
      .skip(bindsUserDetails ? 1 : 0)
      .map(
        (UseSmileIDSampleStep kind) =>
            steps.firstWhere((step) => step.kind == kind),
      )
      .firstWhere((step) => step.skipWhen?.holdsFor(facts) != true)
      .id;
}
