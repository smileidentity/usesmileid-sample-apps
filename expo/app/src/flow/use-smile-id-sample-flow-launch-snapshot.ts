import type {
  UseSmileIDSampleFlowRoute,
  UseSmileIDSampleIdDetails,
  UseSmileIDSampleProduct,
  UseSmileIDSampleUserDetails,
} from '@smileid/sample-ui';

/// Read once at flow entry; never re-read while the flow runs.
export type UseSmileIDSampleFlowLaunchSnapshot = {
  readonly product: UseSmileIDSampleProduct;
  readonly route: UseSmileIDSampleFlowRoute;
  readonly userDetails: UseSmileIDSampleUserDetails;
  readonly idDetails: UseSmileIDSampleIdDetails;
  /// The scenario ids, which on this platform arrive by launch argument rather than from a drawer.
  readonly scenario: string;
  readonly theme: string;
  /// Whether the run submits against sandbox, which a scanned session will decide once one exists.
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
};

/// Where the run submitted, which is the only thing that publishes it.
export const smileIDSampleFlowEnvironment = (
  snapshot: UseSmileIDSampleFlowLaunchSnapshot,
): 'sandbox' | 'production' => (snapshot.sandbox ? 'sandbox' : 'production');
