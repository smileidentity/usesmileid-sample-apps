import { smileIDSampleRequirementFrom } from '@smileid/sample-ui';
import {
  UseSmileIDFlowBuilder,
  type ValidationState,
  type UseSmileIDValidationException,
} from '@smileid/usesmileid';

import { smileIDSampleApplying } from './use-smile-id-sample-flow-builder-config';
import {
  smileIDSampleSnapshotSession,
  type UseSmileIDSampleFlowLaunchSnapshot,
} from './use-smile-id-sample-flow-launch-snapshot';
import { smileIDSampleMinusRequirement } from './use-smile-id-sample-token-binding-rules';

/// What the gate decided, and so where the journey goes instead of the SDK.
export type UseSmileIDSampleFlowPreflight =
  | { readonly kind: 'ready' }
  /// The forms can resolve it.
  | { readonly kind: 'needsDetails'; readonly issues: readonly UseSmileIDValidationException[] }
  /// Only a new token resolves it.
  | { readonly kind: 'needsSession' }
  /// No form can resolve it, and it must still never reach the SDK.
  | { readonly kind: 'misconfigured'; readonly issues: readonly UseSmileIDValidationException[] };

/// The entry gate: the SDK's non-throwing pre-flight plus its per-payload validators.
export const smileIDSamplePreflight = (
  snapshot: UseSmileIDSampleFlowLaunchSnapshot,
): UseSmileIDSampleFlowPreflight => {
  // Ahead of the payloads: no form fixes a lapsed session.
  if (snapshot.sessionExpired) return { kind: 'needsSession' };
  const builder = new UseSmileIDFlowBuilder();
  smileIDSampleApplying(builder, snapshot);
  const requirement = smileIDSampleRequirementFrom(smileIDSampleSnapshotSession(snapshot)?.bindings);

  // Payloads before the builder's verdict: a form can fix what was typed, not how this built it.
  const checks: ValidationState[] = [];
  if (builder.userDetails !== undefined) {
    // The public validator takes no token, so the bindings are subtracted.
    checks.push(smileIDSampleMinusRequirement(builder.validateUserDetails(builder.userDetails), requirement));
  }
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

  const payloadIssues = checks.flatMap((state) => (state.valid ? [] : state.issues));
  if (payloadIssues.length > 0) return { kind: 'needsDetails', issues: payloadIssues };

  const verdict = builder.validate();
  return verdict.valid ? { kind: 'ready' } : { kind: 'misconfigured', issues: verdict.issues };
};
