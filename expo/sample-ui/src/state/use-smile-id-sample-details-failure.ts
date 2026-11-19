import {
  UseSmileIDSampleErrorAction,
  UseSmileIDSampleErrorMessage,
  type UseSmileIDSampleErrorResolution,
} from '../model/use-smile-id-sample-error-resolution';
import { type UseSmileIDSampleJob } from '../model/use-smile-id-sample-job';
import { type UseSmileIDSampleFlowStatus } from '../model/use-smile-id-sample-result';
import { UseSmileIDSampleStatus } from '../model/use-smile-id-sample-status';
import { type UseSmileIDSampleStrings } from '../use-smile-id-sample-strings';
import { smileIDSampleErrorForReason, smileIDSampleErrorUnexplained } from './use-smile-id-sample-error-handling';

/// Which accent a banner carries: warning for a failure the user can act on, error for one that is final.
export type UseSmileIDSampleBannerTone = 'warning' | 'error';

/// What verification details states: a stored job's `error` or `block`, or with no job the failed run that landed here.
export const smileIDSampleDetailsFailure = (
  job: UseSmileIDSampleJob | undefined,
  landedRun: UseSmileIDSampleErrorResolution | undefined,
): UseSmileIDSampleErrorResolution | undefined => {
  if (job === undefined) return landedRun;
  // The status endpoint returns no reason yet, so every such job resolves as the fallback.
  return job.status === UseSmileIDSampleStatus.Error || job.status === UseSmileIDSampleStatus.Blocked
    ? smileIDSampleErrorForReason(null)
    : undefined;
};

/// What a run that landed with no job states: its row, or that it stopped early when no row explains the failure.
export const smileIDSampleLandedFailure = (
  status: UseSmileIDSampleFlowStatus,
  row: UseSmileIDSampleErrorResolution | undefined,
): UseSmileIDSampleErrorResolution | undefined =>
  status === 'failed' ? (row ?? smileIDSampleErrorUnexplained) : undefined;

/// Warning when trying again later can get past the failure, error when the row's own action is Close.
export const smileIDSampleBannerTone = (failure: UseSmileIDSampleErrorResolution): UseSmileIDSampleBannerTone =>
  failure.action === UseSmileIDSampleErrorAction.Exit ? 'error' : 'warning';

/// A failure's message in the app's language.
export const smileIDSampleErrorMessageText = (
  message: UseSmileIDSampleErrorMessage,
  strings: UseSmileIDSampleStrings,
): string => {
  switch (message) {
    case UseSmileIDSampleErrorMessage.CouldNotStart:
      return strings.errorCouldNotStart;
    case UseSmileIDSampleErrorMessage.EndedEarly:
      return strings.errorEndedEarly;
    case UseSmileIDSampleErrorMessage.IdNumberInvalid:
      return strings.errorIdNumberInvalid;
    case UseSmileIDSampleErrorMessage.ServiceNotSetUp:
      return strings.errorServiceNotSetUp;
    case UseSmileIDSampleErrorMessage.SessionExpired:
      return strings.errorSessionExpired;
    case UseSmileIDSampleErrorMessage.ServiceUnavailable:
      return strings.errorServiceUnavailable;
    case UseSmileIDSampleErrorMessage.NotAvailable:
      return strings.errorNotAvailable;
    case UseSmileIDSampleErrorMessage.UpdateApp:
      return strings.errorUpdateApp;
    case UseSmileIDSampleErrorMessage.NotFound:
      return strings.errorNotFound;
    case UseSmileIDSampleErrorMessage.AlreadyStarted:
      return strings.errorAlreadyStarted;
    case UseSmileIDSampleErrorMessage.LinkExpired:
      return strings.errorLinkExpired;
    case UseSmileIDSampleErrorMessage.PhotosTooLarge:
      return strings.errorPhotosTooLarge;
    case UseSmileIDSampleErrorMessage.TooManyAttempts:
      return strings.errorTooManyAttempts;
    case UseSmileIDSampleErrorMessage.Server:
      return strings.errorServer;
    case UseSmileIDSampleErrorMessage.NoConnection:
      return strings.errorNoConnection;
    case UseSmileIDSampleErrorMessage.Timeout:
      return strings.errorTimeout;
    case UseSmileIDSampleErrorMessage.PhotoUnusable:
      return strings.errorPhotoUnusable;
    case UseSmileIDSampleErrorMessage.PhotoRejected:
      return strings.errorPhotoRejected;
    case UseSmileIDSampleErrorMessage.DocumentNotRecognised:
      return strings.errorDocumentNotRecognised;
    case UseSmileIDSampleErrorMessage.FaceCheckUnavailable:
      return strings.errorFaceCheckUnavailable;
    case UseSmileIDSampleErrorMessage.NoSavedSelfie:
      return strings.errorNoSavedSelfie;
    case UseSmileIDSampleErrorMessage.IdNumberNotAccepted:
      return strings.errorIdNumberNotAccepted;
    case UseSmileIDSampleErrorMessage.IdServiceDown:
      return strings.errorIdServiceDown;
    case UseSmileIDSampleErrorMessage.CouldNotFinish:
      return strings.errorCouldNotFinish;
    case UseSmileIDSampleErrorMessage.NotVerified:
      return strings.errorNotVerified;
  }
};
