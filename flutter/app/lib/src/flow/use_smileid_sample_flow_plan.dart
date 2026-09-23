import 'package:flutter/foundation.dart';
import 'package:sample_ui/sample_ui.dart';

/// Everything a token's bindings decide, resolved once so no call site re-derives part of it.
@immutable
class UseSmileIDSampleFlowPlan {
  /// Built by [useSmileIDSampleFlowPlan]; public so the truth table can name what it expects.
  const UseSmileIDSampleFlowPlan({
    required this.userDetailsGap,
    required this.showIdDetailsForm,
    required this.declareConsentScreen,
    required this.passUserDetails,
  });

  /// Which user-details rows the host must still collect; satisfied means skip the form.
  final UseSmileIDSampleUserDetailsRequirement userDetailsGap;

  /// Whether the host's ID form appears.
  final bool showIdDetailsForm;

  /// Whether `consent` is declared: a bound consent lifts the requirement, and declaring it anyway ends the run.
  final bool declareConsentScreen;

  /// False means pass null, never blanks: a non-null `userDetails` silences the SDK's per-field errors.
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

/// The bindings' whole decision for [product], each field traceable to one SDK rule.
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
