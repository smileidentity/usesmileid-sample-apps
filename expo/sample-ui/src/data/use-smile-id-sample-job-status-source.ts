import { smileIDSampleStatusLabel, type UseSmileIDSampleStatus } from '../model/use-smile-id-sample-status';
import { type UseSmileIDSampleStrings } from '../use-smile-id-sample-strings';

/// What a refresh did, so the screen can say so. The labels are product strings, identical across the four apps.
export type UseSmileIDSampleStatusRefresh =
  | { readonly kind: 'updated'; readonly status: UseSmileIDSampleStatus; readonly message: string; readonly httpCode: number }
  /// 202 — still running; the row already says Processing.
  | { readonly kind: 'stillProcessing' }
  /// No live session, so no credential to ask with. A precondition, not an error.
  | { readonly kind: 'noSession' }
  /// Never submitted under a scanned session, so there is no server-side job.
  | { readonly kind: 'noServerJob' }
  /// Submitted by a different partner, so this session's credential is for another account.
  | { readonly kind: 'partnerMismatch' }
  /// The server's wording, or the error's type when `failure` is `unexpected`.
  | { readonly kind: 'failed'; readonly reason: string; readonly failure?: 'notStored' | 'unexpected' };

/// The one network call the app owns, behind a seam so the refresh orchestration tests off-device.
export type UseSmileIDSampleJobStatusSource = {
  /// Maps the HTTP exchange onto an outcome and lets a transport failure throw — the store owns reporting it.
  check: (jobId: string, token: string, sandbox: boolean) => Promise<UseSmileIDSampleStatusRefresh>;
};

/// What each outcome says on screen. Kept beside the type so four apps cannot word them differently.
export const smileIDSampleRefreshLabel = (
  outcome: UseSmileIDSampleStatusRefresh,
  strings: UseSmileIDSampleStrings,
): string => {
  switch (outcome.kind) {
    case 'updated':
      return strings.statusRefreshResult({ status: smileIDSampleStatusLabel(outcome.status, strings), message: outcome.message });
    case 'stillProcessing':
      return strings.statusRefreshProcessing;
    case 'noSession':
      return strings.statusRefreshNoSession;
    case 'noServerJob':
      return strings.statusRefreshNotTokenJob;
    case 'partnerMismatch':
      return strings.statusRefreshOtherPartner;
    case 'failed':
      return strings.statusRefreshFailed({ reason: smileIDSampleFailureText(outcome, strings) });
  }
};

/// A failure's own line, in the app's language where the app worded it.
const smileIDSampleFailureText = (
  failed: Extract<UseSmileIDSampleStatusRefresh, { kind: 'failed' }>,
  strings: UseSmileIDSampleStrings,
): string => {
  switch (failed.failure) {
    case 'notStored':
      return strings.jobErrorNotStored;
    case 'unexpected':
      return strings.jobErrorUnexpected({ type: failed.reason });
    default:
      return failed.reason;
  }
};
