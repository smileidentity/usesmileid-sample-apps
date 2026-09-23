import {
  smileIDSampleRequirementSatisfied,
  type UseSmileIDSampleProduct,
  type UseSmileIDSampleTokenBindings,
} from '@smileid/sample-ui';
import type { Href } from 'expo-router';

import { smileIDSampleFlowPlan } from './use-smile-id-sample-flow-plan';

/// What follows user details, shared with that form's Continue.
export const smileIDSampleStepAfterUserDetails = (
  product: UseSmileIDSampleProduct,
  bindings: UseSmileIDSampleTokenBindings | null,
): Href =>
  smileIDSampleFlowPlan(bindings, product).showIdDetailsForm
    ? `/flow/${product.id}/id-details`
    : `/flow/${product.id}/run`;

/// A product's first step, past the form when the token binds all it collects.
export const smileIDSampleFirstStepFor = (
  product: UseSmileIDSampleProduct,
  bindings: UseSmileIDSampleTokenBindings | null,
): Href =>
  smileIDSampleRequirementSatisfied(smileIDSampleFlowPlan(bindings, product).userDetailsGap)
    ? smileIDSampleStepAfterUserDetails(product, bindings)
    : `/flow/${product.id}/details`;
