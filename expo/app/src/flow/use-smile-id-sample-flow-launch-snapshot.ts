import type {
  UseSmileIDSampleFlowRoute,
  UseSmileIDSampleIdDetails,
  UseSmileIDSampleProduct,
  UseSmileIDSampleTokenSession,
  UseSmileIDSampleUserDetails,
} from '@smileid/sample-ui';

import { smileIDSampleStartsExpired } from './use-smile-id-sample-token-binding-rules';

/// Read once at flow entry; never re-read while the flow runs.
export type UseSmileIDSampleFlowLaunchSnapshot = {
  readonly product: UseSmileIDSampleProduct;
  readonly route: UseSmileIDSampleFlowRoute;
  readonly userDetails: UseSmileIDSampleUserDetails;
  readonly idDetails: UseSmileIDSampleIdDetails;
  /// The scenario ids, which on this platform arrive by launch argument rather than from a drawer.
  readonly scenario: string;
  readonly theme: string;
  /// Whether the run submits against sandbox; the linked session decides, and no session is sandbox.
  readonly sandbox: boolean;
  /// The five settings, not the settings object: the read happens once.
  readonly allowAgentMode: boolean;
  readonly enableEnhancedLiveness: boolean;
  readonly consentStep: boolean;
  readonly instructionsStep: boolean;
  readonly previewStep: boolean;
  /// The id this run submits under; only authentication sends it.
  readonly userId: string;
  readonly partnerId: string;
  readonly partnerName: string;
  /// The active profile's webhook URL; empty means their portal default.
  readonly callbackUrl: string;
  /// Live at entry only: a session that has run out is the gate's business, never the builder's.
  readonly session: UseSmileIDSampleTokenSession | null;
  /// Run out — the one thing that routes back to the scanner. Usually true with no session.
  readonly sessionExpired: boolean;
};

/// Where the run submitted, which is the only thing that publishes it.
export const smileIDSampleFlowEnvironment = (
  snapshot: UseSmileIDSampleFlowLaunchSnapshot,
): 'sandbox' | 'production' => (snapshot.sandbox ? 'sandbox' : 'production');

/// The session a run actually submits under.
export const smileIDSampleSnapshotSession = (
  snapshot: UseSmileIDSampleFlowLaunchSnapshot,
): UseSmileIDSampleTokenSession | null =>
  smileIDSampleStartsExpired(snapshot.scenario) ? null : snapshot.session;
