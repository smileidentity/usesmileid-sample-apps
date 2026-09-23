import type { UseSmileIDSampleProduct } from '../model/use-smile-id-sample-product';
import {
  smileIDSampleBindsIdDetails,
  smileIDSampleBindsRequiredUserDetails,
  type UseSmileIDSampleTokenBindings,
} from './use-smile-id-sample-token-decoder';
import {
  smileIDSampleRequirementFrom,
  type UseSmileIDSampleUserDetailsRequirement,
} from './use-smile-id-sample-user-details-requirement';

/// Everything a token's bindings decide about a run, resolved once at entry (token-binding-matrix-android.md §4).
export type UseSmileIDSampleFlowPlan = {
  /// Which user-details rows the host must still collect; nothing outstanding means skip the form.
  readonly userDetailsGap: UseSmileIDSampleUserDetailsRequirement;
  readonly showIdDetailsForm: boolean;
  /// False once the token carries consent: declaring the screen anyway ends the run before it starts.
  readonly declareConsentScreen: boolean;
  /// False means pass no `userDetails` at all — never blanks, which silence the SDK's per-field errors.
  readonly passUserDetails: boolean;
};

/// The one decision the forms, the gate and the builder all read, so none of them re-derives it.
export const smileIDSampleFlowPlan = (
  bindings: UseSmileIDSampleTokenBindings | null | undefined,
  product: UseSmileIDSampleProduct,
): UseSmileIDSampleFlowPlan => ({
  userDetailsGap: smileIDSampleRequirementFrom(bindings),
  showIdDetailsForm: product.needsIdDetails && !smileIDSampleBindsIdDetails(bindings, product),
  declareConsentScreen: bindings?.consent == null,
  passUserDetails: !smileIDSampleBindsRequiredUserDetails(bindings),
});
