import { UseSmileIDSampleErrorAction, type UseSmileIDSampleProduct } from '@smileid/sample-ui';

/// Where a failure's one action takes the user.
export type UseSmileIDSampleErrorMove =
  /// The product's flow again, past the forms, as a new job.
  | { readonly kind: 'runAgain'; readonly product: UseSmileIDSampleProduct }
  /// The ID form, whose Continue starts the flow.
  | { readonly kind: 'editIdDetails'; readonly product: UseSmileIDSampleProduct }
  /// The scanner for a new token, then the flow.
  | { readonly kind: 'newToken'; readonly product: UseSmileIDSampleProduct }
  /// Out of the run, to the products tab.
  | { readonly kind: 'leave' };

/// The move `action` makes for the run of `product`; without a product there is nothing to run again.
export const smileIDSampleErrorMove = (
  action: UseSmileIDSampleErrorAction,
  product: UseSmileIDSampleProduct | null,
): UseSmileIDSampleErrorMove => {
  if (product === null) return { kind: 'leave' };
  switch (action) {
    case UseSmileIDSampleErrorAction.Retry:
    case UseSmileIDSampleErrorAction.RetryLater:
    case UseSmileIDSampleErrorAction.Recapture:
      return { kind: 'runAgain', product };
    case UseSmileIDSampleErrorAction.FixInput:
      return { kind: 'editIdDetails', product };
    case UseSmileIDSampleErrorAction.NewSession:
      return { kind: 'newToken', product };
    case UseSmileIDSampleErrorAction.Exit:
      return { kind: 'leave' };
  }
};
