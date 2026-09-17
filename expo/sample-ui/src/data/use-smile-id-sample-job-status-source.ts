import type { UseSmileIDSampleStatus } from '../model/use-smile-id-sample-status';

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
  | { readonly kind: 'failed'; readonly reason: string };

/// The one network call the app owns, behind a seam so the refresh orchestration tests off-device.
export type UseSmileIDSampleJobStatusSource = {
  /// Maps the HTTP exchange onto an outcome and lets a transport failure throw — the store owns reporting it.
  check: (jobId: string, token: string, sandbox: boolean) => Promise<UseSmileIDSampleStatusRefresh>;
};

/// What each outcome says on screen. Kept beside the type so four apps cannot word them differently.
export const smileIDSampleRefreshLabel = (outcome: UseSmileIDSampleStatusRefresh): string => {
  switch (outcome.kind) {
    case 'updated':
      return outcome.message;
    case 'stillProcessing':
      return 'Still processing';
    case 'noSession':
      return 'No live token session to check with';
    case 'noServerJob':
      return 'Never submitted, so there is nothing to check';
    case 'partnerMismatch':
      return 'Submitted by a different partner';
    case 'failed':
      return outcome.reason;
  }
};
