import {
  UseSmileIDSampleErrorAction,
  type UseSmileIDSampleProduct,
  type UseSmileIDSampleResumePoint,
} from '@smileid/sample-ui';

/// Where a failure's one action takes the user.
export type UseSmileIDSampleErrorMove =
  /// The product's flow again, past the forms, as a new job.
  | { readonly kind: 'runAgain'; readonly product: UseSmileIDSampleProduct }
  /// The product's first step under the live session, whose partner may not take the details the run had.
  | { readonly kind: 'runFromStart'; readonly product: UseSmileIDSampleProduct }
  /// The ID form, whose Continue starts the flow.
  | { readonly kind: 'editIdDetails'; readonly product: UseSmileIDSampleProduct }
  /// The scanner for a new token, then the run from `resumeAt`.
  | { readonly kind: 'newToken'; readonly product: UseSmileIDSampleProduct; readonly resumeAt: UseSmileIDSampleResumePoint }
  /// Out of the run, to the products tab.
  | { readonly kind: 'leave' };

/// Where the run's ID details come from: the form it asks for, the token (which only a new token can change), or nowhere.
export type UseSmileIDSampleIdDetailsSource = 'form' | 'token' | 'none';

/// What the gate a product tap passes knows: whether a session is live, its partner, the run's own, and its ID details' source.
export type UseSmileIDSampleErrorGate = {
  readonly sessionLive: boolean;
  readonly livePartnerId: string | null;
  readonly runPartnerId: string | null;
  readonly idDetails: UseSmileIDSampleIdDetailsSource;
};

/// The move `action` makes for the run of `product`, gated as a product tap is: a live session, on the run's own partner.
export const smileIDSampleErrorMove = (
  action: UseSmileIDSampleErrorAction,
  product: UseSmileIDSampleProduct | null,
  gate: UseSmileIDSampleErrorGate,
): UseSmileIDSampleErrorMove => {
  if (product === null) return { kind: 'leave' };
  const ownPartner = gate.runPartnerId !== null && gate.runPartnerId === gate.livePartnerId;
  switch (action) {
    case UseSmileIDSampleErrorAction.Retry:
    case UseSmileIDSampleErrorAction.RetryLater:
    case UseSmileIDSampleErrorAction.Recapture:
      if (!gate.sessionLive) return { kind: 'newToken', product, resumeAt: 'flow' };
      return ownPartner ? { kind: 'runAgain', product } : { kind: 'runFromStart', product };
    case UseSmileIDSampleErrorAction.FixInput:
      if (!gate.sessionLive || gate.idDetails === 'token') return { kind: 'newToken', product, resumeAt: 'firstStep' };
      return ownPartner && gate.idDetails === 'form' ? { kind: 'editIdDetails', product } : { kind: 'runFromStart', product };
    case UseSmileIDSampleErrorAction.NewSession:
      return { kind: 'newToken', product, resumeAt: 'flow' };
    case UseSmileIDSampleErrorAction.Exit:
      return { kind: 'leave' };
  }
};
