import {
  smileIDSampleRequirementFrom,
  type UseSmileIDSampleUserDetailsRequirement,
} from '@smileid/sample-ui';
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

/// What the gate decided, and so where the journey goes instead of the SDK.
export type UseSmileIDSampleFlowPreflight =
  | { readonly kind: 'ready' }
  /// The forms can resolve it.
  | { readonly kind: 'needsDetails'; readonly issues: readonly UseSmileIDValidationException[] }
  /// Only a new token resolves it, so the journey goes back to the scanner rather than to a form.
  | { readonly kind: 'needsSession' }
  /// No form can resolve it, and it must still never reach the SDK.
  | { readonly kind: 'misconfigured'; readonly issues: readonly UseSmileIDValidationException[] };

/// The entry gate: the SDK's non-throwing pre-flight plus its per-payload validators.
export const smileIDSamplePreflight = (
  snapshot: UseSmileIDSampleFlowLaunchSnapshot,
): UseSmileIDSampleFlowPreflight => {
  // Ahead of the payloads, because no form fixes a session that has run out.
  if (snapshot.sessionExpired) return { kind: 'needsSession' };
  const builder = new UseSmileIDFlowBuilder();
  smileIDSampleApplying(builder, snapshot);
  const requirement = smileIDSampleRequirementFrom(smileIDSampleSnapshotSession(snapshot)?.bindings);

  // Payloads before the builder's verdict: a form can fix what was typed, not how this built it.
  const checks: ValidationState[] = [];
  if (builder.userDetails !== undefined) {
    // The public validator takes no token, so the bindings come off what it reports instead.
    checks.push(minus(builder.validateUserDetails(builder.userDetails), requirement));
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

/// Drops the issues the token already answers; every other rule the SDK applies still stands.
const minus = (state: ValidationState, requirement: UseSmileIDSampleUserDetailsRequirement): ValidationState => {
  if (state.valid) return state;
  const outstanding = state.issues.filter((issue) => !covers(requirement, issue));
  return outstanding.length === 0 ? { valid: true } : { ...state, issues: outstanding };
};

const covers = (requirement: UseSmileIDSampleUserDetailsRequirement, issue: UseSmileIDValidationException): boolean => {
  const details = issue.errorDetails as { fieldName?: unknown; reason?: unknown } | undefined;
  switch (details?.fieldName) {
    case 'userDetails.givenNames':
      return !requirement.firstName;
    case 'userDetails.lastName':
      return !requirement.lastName;
    // The contact rule is reported against the object, so its reason is what identifies it.
    case 'userDetails':
      return !requirement.contact && String(details.reason).toLowerCase().includes('email');
    default:
      return false;
  }
};
