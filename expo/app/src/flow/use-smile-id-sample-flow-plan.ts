import {
  smileIDSampleBindsIdDetails,
  smileIDSampleBindsRequiredUserDetails,
  smileIDSampleRequirementFrom,
  type UseSmileIDSampleProduct,
  type UseSmileIDSampleTokenBindings,
  type UseSmileIDSampleUserDetailsRequirement,
} from '@smileid/sample-ui';

/// Everything a token's bindings decide about a run.
export type UseSmileIDSampleFlowPlan = {
  /// The rows the host must still collect; none outstanding skips the form.
  readonly userDetailsGap: UseSmileIDSampleUserDetailsRequirement;
  readonly showIdDetailsForm: boolean;
  /// False once the token carries consent.
  readonly declareConsentScreen: boolean;
  /// False means pass no `userDetails`, never blanks.
  readonly passUserDetails: boolean;
};

/// The one decision the forms, the gate and the builder read.
export const smileIDSampleFlowPlan = (
  bindings: UseSmileIDSampleTokenBindings | null | undefined,
  product: UseSmileIDSampleProduct,
): UseSmileIDSampleFlowPlan => ({
  userDetailsGap: smileIDSampleRequirementFrom(bindings),
  showIdDetailsForm: product.needsIdDetails && !smileIDSampleBindsIdDetails(bindings, product),
  declareConsentScreen: bindings?.consent == null,
  passUserDetails: !smileIDSampleBindsRequiredUserDetails(bindings),
});
