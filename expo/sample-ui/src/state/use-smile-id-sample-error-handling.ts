import {
  smileIDSampleErrorActions,
  UseSmileIDSampleErrorAction,
  UseSmileIDSampleErrorMessage,
  type UseSmileIDSampleErrorResolution,
  UseSmileIDSampleTransportFailure,
} from '../model/use-smile-id-sample-error-resolution';

/// One row: a resolution and what a failure must carry to match it.
type Row = {
  readonly resolution: UseSmileIDSampleErrorResolution;
  readonly statuses?: readonly number[];
  readonly transport?: UseSmileIDSampleTransportFailure;
  readonly reasons?: readonly string[];
  readonly serverMessageContains?: readonly string[];
};

const Message = UseSmileIDSampleErrorMessage;
const Action = UseSmileIDSampleErrorAction;

const resolution = (
  id: string,
  message: UseSmileIDSampleErrorMessage,
  action: UseSmileIDSampleErrorAction,
  limits: { backoffSeconds?: readonly number[]; maxUses?: number; waitsForConnection?: boolean } = {},
): UseSmileIDSampleErrorResolution => ({
  id,
  message,
  action,
  backoffSeconds: limits.backoffSeconds ?? [],
  maxUses: limits.maxUses ?? smileIDSampleErrorActions[action].maxUses ?? null,
  waitsForConnection: limits.waitsForConnection ?? false,
});

/// The rows a failure the table does not name resolves as (spec/error-handling.json → fallback).
const requestInvalid = resolution('requestInvalid', Message.CouldNotStart, Action.Exit);
const notVerified = resolution('notVerified', Message.NotVerified, Action.Exit);

const submissionRows: readonly Row[] = [
  {
    resolution: resolution('idNumberInvalid', Message.IdNumberInvalid, Action.FixInput),
    statuses: [400],
    serverMessageContains: ['id number format', 'id_number', 'id_type'],
  },
  {
    resolution: resolution('callbackUrlMissing', Message.ServiceNotSetUp, Action.Exit),
    statuses: [400],
    serverMessageContains: ['callback'],
  },
  { resolution: requestInvalid, statuses: [400] },
  { resolution: resolution('sessionExpired', Message.SessionExpired, Action.NewSession), statuses: [401] },
  { resolution: resolution('insufficientBalance', Message.ServiceUnavailable, Action.Exit), statuses: [402] },
  {
    resolution: resolution('sdkVersionNotAllowed', Message.UpdateApp, Action.Exit),
    statuses: [403],
    serverMessageContains: ['sdk version'],
  },
  { resolution: resolution('notEnabled', Message.NotAvailable, Action.Exit), statuses: [403] },
  { resolution: resolution('notFound', Message.NotFound, Action.Exit), statuses: [404] },
  { resolution: resolution('alreadyStarted', Message.AlreadyStarted, Action.NewSession), statuses: [409] },
  { resolution: resolution('linkExpired', Message.LinkExpired, Action.Exit), statuses: [410] },
  { resolution: resolution('payloadTooLarge', Message.PhotosTooLarge, Action.Recapture), statuses: [413] },
  { resolution: resolution('wrongContentType', Message.CouldNotStart, Action.Exit), statuses: [415] },
  { resolution: resolution('tokenPayloadInvalid', Message.SessionExpired, Action.NewSession), statuses: [422] },
  {
    resolution: resolution('rateLimited', Message.TooManyAttempts, Action.Retry, { backoffSeconds: [30], maxUses: 1 }),
    statuses: [429],
  },
  {
    resolution: resolution('serverError', Message.Server, Action.Retry, { backoffSeconds: [5, 15, 30], maxUses: 3 }),
    statuses: [500, 502, 503, 504],
  },
  {
    resolution: resolution('noConnection', Message.NoConnection, Action.Retry, { waitsForConnection: true }),
    transport: UseSmileIDSampleTransportFailure.NoConnection,
  },
  {
    resolution: resolution('timeout', Message.Timeout, Action.Retry, { backoffSeconds: [5] }),
    transport: UseSmileIDSampleTransportFailure.Timeout,
  },
];

const resultRows: readonly Row[] = [
  {
    resolution: resolution('idAuthorityPhotoUnavailable', Message.FaceCheckUnavailable, Action.Exit),
    reasons: ['image_unavailable_or_invalid'],
    serverMessageContains: ['id authority photo not available'],
  },
  {
    resolution: resolution('noEnrolledSelfie', Message.NoSavedSelfie, Action.Exit),
    reasons: ['image_unavailable_or_invalid'],
    serverMessageContains: ['no enrolled selfie found'],
  },
  { resolution: resolution('photoUnusable', Message.PhotoUnusable, Action.Recapture), reasons: ['image_unavailable_or_invalid'] },
  { resolution: resolution('contentPolicyViolated', Message.PhotoRejected, Action.Recapture), reasons: ['content_policy_violated'] },
  {
    resolution: resolution('documentUnclassifiable', Message.DocumentNotRecognised, Action.Recapture),
    reasons: ['document_unclassifiable'],
  },
  { resolution: resolution('invalidIdNumber', Message.IdNumberNotAccepted, Action.FixInput), reasons: ['invalid_id_number'] },
  {
    resolution: resolution('serviceUnavailable', Message.IdServiceDown, Action.RetryLater, { backoffSeconds: [30], maxUses: 1 }),
    reasons: ['service_unavailable'],
  },
  {
    resolution: resolution('internalError', Message.CouldNotFinish, Action.Retry, { backoffSeconds: [5], maxUses: 1 }),
    reasons: ['internal_error'],
  },
  {
    resolution: notVerified,
    reasons: [
      'spoof_detected',
      'face_verification_failed',
      'document_check_failed',
      'age_requirement_not_met',
      'account_locked',
      'account_locked_fraud',
      'high_risk',
      'medium_risk',
      'identifier_not_found',
    ],
  },
];

/// Every submission row's resolution, in the order of spec/error-handling.json.
export const smileIDSampleErrorSubmissionRows: readonly UseSmileIDSampleErrorResolution[] = submissionRows.map(
  (row) => row.resolution,
);

/// Every result row's resolution, in the order of spec/error-handling.json.
export const smileIDSampleErrorResultRows: readonly UseSmileIDSampleErrorResolution[] = resultRows.map(
  (row) => row.resolution,
);

const accepts = (row: Row, serverMessage?: string | null): boolean => {
  if (row.serverMessageContains === undefined) return true;
  const text = (serverMessage ?? '').toLowerCase();
  return row.serverMessageContains.some((part) => text.includes(part));
};

const resolve = (
  rows: readonly Row[],
  matches: (row: Row) => boolean,
  serverMessage: string | null | undefined,
  fallback: UseSmileIDSampleErrorResolution,
): UseSmileIDSampleErrorResolution =>
  rows.find((candidate) => matches(candidate) && accepts(candidate, serverMessage))?.resolution ?? fallback;

/// The row a submission the table does not name resolves as.
export const smileIDSampleErrorSubmissionFallback: UseSmileIDSampleErrorResolution = requestInvalid;

/// A submission the server refused with `status`; `serverMessage` only tells rows apart and is never shown.
export const smileIDSampleErrorForStatus = (status: number, serverMessage?: string | null): UseSmileIDSampleErrorResolution =>
  resolve(submissionRows, (row) => row.statuses?.includes(status) ?? false, serverMessage, requestInvalid);

/// A submission the server never answered.
export const smileIDSampleErrorForTransport = (failure: UseSmileIDSampleTransportFailure): UseSmileIDSampleErrorResolution =>
  resolve(submissionRows, (row) => row.transport === failure, null, requestInvalid);

/// An accepted job that ended in `error` or `block` with `reason`; none, or one the table does not name, is never explained.
export const smileIDSampleErrorForReason = (
  reason?: string | null,
  serverMessage?: string | null,
): UseSmileIDSampleErrorResolution =>
  resolve(resultRows, (row) => reason != null && (row.reasons?.includes(reason) ?? false), serverMessage, notVerified);
