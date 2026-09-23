import 'package:flutter/foundation.dart';
import 'package:sample_ui/sample_ui.dart';

/// Everything a token's bindings decide for one product.
@immutable
class UseSmileIDSampleFlowPlan {
  /// Built by [useSmileIDSampleFlowPlan].
  const UseSmileIDSampleFlowPlan({
    required this.userDetailsGap,
    required this.showIdDetailsForm,
    required this.declareConsentScreen,
    required this.passUserDetails,
  });

  /// The user-details rows still to collect; satisfied skips the form.
  final UseSmileIDSampleUserDetailsRequirement userDetailsGap;

  /// Whether the host's ID form appears.
  final bool showIdDetailsForm;

  /// Whether the consent screen is declared; a bound consent omits it.
  final bool declareConsentScreen;

  /// Whether to pass `userDetails`; false passes null, never blanks.
  final bool passUserDetails;

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleFlowPlan &&
      other.userDetailsGap == userDetailsGap &&
      other.showIdDetailsForm == showIdDetailsForm &&
      other.declareConsentScreen == declareConsentScreen &&
      other.passUserDetails == passUserDetails;

  @override
  int get hashCode => Object.hash(
    userDetailsGap,
    showIdDetailsForm,
    declareConsentScreen,
    passUserDetails,
  );

  @override
  String toString() =>
      'UseSmileIDSampleFlowPlan(gap: ${userDetailsGap.prompt}, '
      'idForm: $showIdDetailsForm, consent: $declareConsentScreen, '
      'userDetails: $passUserDetails)';
}

/// The plan the bindings make for [product].
UseSmileIDSampleFlowPlan useSmileIDSampleFlowPlan(
  UseSmileIDSampleTokenBindings? bindings,
  UseSmileIDSampleProduct product,
) => UseSmileIDSampleFlowPlan(
  userDetailsGap: useSmileIDSampleUserDetailsRequirement(bindings),
  showIdDetailsForm:
      product.needsIdDetails && bindings?.bindsIdDetails(product) != true,
  declareConsentScreen: bindings?.consent == null,
  passUserDetails: bindings?.bindsRequiredUserDetails != true,
);
