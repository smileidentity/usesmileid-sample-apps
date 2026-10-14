import {
  UseSmileIDFlowBuilder,
  type ValidationState,
  type UseSmileIDValidationException,
} from '@smileid/usesmileid';

import { useSmileIDSampleShellExtension } from '../extension';
import { smileIDSampleApplying } from './use-smile-id-sample-flow-builder-config';
import { type UseSmileIDSampleFlowLaunchSnapshot } from './use-smile-id-sample-flow-launch-snapshot';

/// What the gate decided, and so where the journey goes instead of the SDK.
export type UseSmileIDSampleFlowPreflight =
  | { readonly kind: 'ready' }
  /// The forms can resolve it.
  | { readonly kind: 'needsDetails'; readonly issues: readonly UseSmileIDValidationException[] }
  /// SmartSelfie Authentication with no enrolled user to run as; the user ID screen resolves it.
  | { readonly kind: 'needsUserId' }
  /// Only a new token resolves it.
  | { readonly kind: 'needsSession' }
  /// No form can resolve it, and it must still never reach the SDK.
  | { readonly kind: 'misconfigured'; readonly issues: readonly UseSmileIDValidationException[] };

/// The entry gate: the SDK's non-throwing pre-flight plus its per-payload validators.
export const smileIDSamplePreflight = (
  snapshot: UseSmileIDSampleFlowLaunchSnapshot,
): UseSmileIDSampleFlowPreflight => {
  // Ahead of the payloads: no form fixes a missing or lapsed session.
  if (snapshot.sessionExpired || snapshot.session === null) return { kind: 'needsSession' };
  // Ahead of the SDK's own check, which would end the run: the user ID screen resolves it.
  if (snapshot.product.id === 'smartSelfieAuth' && snapshot.userId.length === 0) return { kind: 'needsUserId' };
  const builder = new UseSmileIDFlowBuilder();
  smileIDSampleApplying(builder, snapshot, undefined, useSmileIDSampleShellExtension);
  useSmileIDSampleShellExtension?.customiseFlow?.(builder, snapshot.product);

  // Payloads before the builder's verdict: a form can fix what was typed, not how this built it.
  // User details are not checked here: the API reports any a job needs, on the result card.
  const checks: ValidationState[] = [];
  if (builder.biometricKYCParams !== undefined)
    checks.push(builder.validateBiometricKYCParams(builder.biometricKYCParams));
  if (builder.enhancedKYCParams !== undefined)
    checks.push(builder.validateEnhancedKYCParams(builder.enhancedKYCParams));
  if (builder.documentVerificationParams !== undefined)
    checks.push(builder.validateDocumentVerificationParams(builder.documentVerificationParams));
  if (builder.enhancedDocumentVerificationParams !== undefined)
    checks.push(
      builder.validateEnhancedDocumentVerificationParams(builder.enhancedDocumentVerificationParams),
    );
  if (builder.residencyDocumentVerificationParams !== undefined)
    checks.push(
      builder.validateResidencyDocumentVerificationParams(builder.residencyDocumentVerificationParams),
    );

  const payloadIssues = checks.flatMap((state) => (state.valid ? [] : state.issues));
  if (payloadIssues.length > 0) return { kind: 'needsDetails', issues: payloadIssues };

  const verdict = builder.validate();
  return verdict.valid ? { kind: 'ready' } : { kind: 'misconfigured', issues: verdict.issues };
};
